ESX = exports["es_extended"]:getSharedObject()

local HUD_UPDATE_INTERVAL = 900
local CARHUD_SLEEP_INTERVAL = 150

local hunger, thirst, inVeh = 0, 0, false


local function updatePlayerStatus()
    local ped = PlayerPedId()
    TriggerEvent('esx_status:getStatus', 'hunger', function(status)
        hunger = status.getPercent()
    end)
    TriggerEvent('esx_status:getStatus', 'thirst', function(status)
        thirst = status.getPercent()
    end)
end

local function updateHud()
    SendNUIMessage({
        action = 'updateHud',
        health = GetEntityHealth(PlayerPedId()) / 2,
        hunger = hunger,
        thirst = thirst,
        talking = NetworkIsPlayerTalking(PlayerId()),
        voice = LocalPlayer.state['proximity'].distance,
    })
end

local function compass(heading)
    if heading >= 337.5 or heading <= 22.5 then
        return "N"
    elseif heading > 22.5 and heading < 67.5 then
        return "NE"
    elseif heading >= 67.5 and heading <= 112.5 then
        return "E"
    elseif heading > 112.5 and heading < 157.5 then
        return "SE"
    elseif heading >= 157.5 and heading <= 202.5 then
        return "S"
    elseif heading > 202.5 and heading < 247.5 then
        return "SW"
    elseif heading >= 247.5 and heading <= 292.5 then
        return "W"
    else
        return "NW"
    end
end


local function updateCarHud()
    local speed = 0
    local ped = PlayerPedId()
    local x, y, z, streetName, zone, heading = nil, nil, nil, nil, nil, 0

    while inVeh do 
        DisplayRadar(true)
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle then
            x, y, z = table.unpack(GetEntityCoords(ped))
            zone = GetLabelText(GetNameOfZone(x, y, z))
            speed = math.floor(GetEntitySpeed(vehicle) * 3.6)
            local streetHash = GetStreetNameAtCoord(x, y, z)
            streetName = GetStreetNameFromHashKey(streetHash)
            heading = 360.0 - ((GetGameplayCamRot(0).z + 360.0) % 360.0)
        end

        SendNUIMessage({
            action = "updateCarhud",
            toggle = true,
            speed = speed,
            street = streetName,
            fuel = Entity(vehicle).state.fuel,
            engine = GetIsVehicleEngineRunning(vehicle),
            direction = compass(heading),
        })
        Wait(CARHUD_SLEEP_INTERVAL)
    end

    if not inVeh then
        SendNUIMessage({
            action = "carhudAction",
            toggle = false,
        })
    end
end

local function InitMap()
    RequestStreamedTextureDict("squaremap", false)
    while not HasStreamedTextureDictLoaded("squaremap") do
        Wait(0)
    end

    local defaultAspectRatio = 1920 / 1080
    local resolutionX, resolutionY = GetActiveScreenResolution()
    local aspectRatio = resolutionX / resolutionY
    local minimapOffset = 0
    if aspectRatio > defaultAspectRatio then
        minimapOffset = ((defaultAspectRatio - aspectRatio) / 3.6) - 0.008
    end

    SetMinimapClipType(0)
    AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "squaremap", "radarmasksm")
    AddReplaceTexture("platform:/textures/graphics", "radarmask1g", "squaremap", "radarmasksm")

    SetMinimapComponentPosition("minimap", "L", "B", 0.0 + minimapOffset, -0.017, 0.1638, 0.180)
    SetMinimapComponentPosition("minimap_mask", "L", "B", 0.0 + minimapOffset, 0.0, 0.128, 0.20)
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', 0.005 + minimapOffset, 0.025, 0.200, 0.290)
    SetBlipAlpha(GetNorthRadarBlip(), 0)
    SetMinimapClipType(0)

    SetRadarBigmapEnabled(true, false)
    while IsBigmapActive() do
        Wait(0)
        SetRadarBigmapEnabled(false, false)
    end
end

Citizen.CreateThread(function ()
    InitMap()

    while true do
        updatePlayerStatus()
        updateHud()
        Wait(HUD_UPDATE_INTERVAL)
    end
end)

lib.onCache('vehicle', function(value)
    if cache.vehicle == false then
        inVeh = true
        DisplayRadar(true)
        SendNUIMessage({ action = "toggleCarhud", toggle = true })
        updateCarHud()
    else
        DisplayRadar(false)
        inVeh = false
        SendNUIMessage({ action = "toggleCarhud", toggle = false })
    end
end)

RegisterCommand("minimapfix", function()
    RequestScaleformMovie("minimap")
    SetRadarBigmapEnabled(true, false)
    Wait(0)
    SetRadarBigmapEnabled(false, false)
end)

RegisterCommand('hud', function()
    toggle = not toggle
    SendNUIMessage({ action = 'toggleHud', toggle = toggle })
end)

RegisterKeyMapping('hud', 'Pokaż Hud', 'MOUSE_BUTTON', 'MOUSE_MIDDLE')
