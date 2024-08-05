ESX = exports["es_extended"]:getSharedObject()

local hunger
local thirst

Citizen.CreateThread(function ()
    InitMap()


    while true do
                    local ped = PlayerPedId()

                    TriggerEvent('esx_status:getStatus', 'hunger', function(hungerstatus)
                        TriggerEvent('esx_status:getStatus', 'thirst', function(thirststatus)
                            hunger = hungerstatus.getPercent()
                            thirst = thirststatus.getPercent()
                        end)
                    end)


                    SendNUIMessage({
                        action = 'updateHud',
                        health = GetEntityHealth(PlayerPedId()) / 2,
                        hunger = hunger,
                        thirst = thirst,
                        talking = NetworkIsPlayerTalking(PlayerId()),
                        voice = LocalPlayer.state['proximity'].distance,
                    })
        Wait(900)
    end

end)


local inVeh = false


lib.onCache('vehicle', function(value)
    print('old vehicle:', cache.vehicle)
    print('new vehicle:', value)
    if cache.vehicle == false then
        inVeh = true
        
        DisplayRadar(true)
        print('true')
        SendNUIMessage({
            action = "toggleCarhud",
            toggle = true,
        });
        -- border()
        loop()
    else
        DisplayRadar(false)
        inVeh = false
        DisplayRadar(false)
        Wait(300)
        SendNUIMessage({
            action = "toggleCarhud",
            toggle = false,
        });
        DisplayRadar(false)
    end
end)

local carhudsleep = 150

function loop()
    local speed = 0
    local ped = PlayerPedId()
    local x, y, z = nil, nil, nil
    local zonytopka = nil
    local street = nil
    local streetName = nil
    local zone = nil

    
    
    while inVeh do 
        DisplayRadar(true)
            Vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                if Vehicle then
                    x, y, z = table.unpack(GetEntityCoords(ped))
                    zonytopka = GetLabelText(GetNameOfZone(x,y,z))
                    speed = math.floor((GetEntitySpeed(Vehicle)*3.6))
                    street = GetStreetNameAtCoord(x, y, z)
                    streetName = GetStreetNameFromHashKey(street)
                    zone = zonytopka
                    heading = 360.0 - ((GetGameplayCamRot(0).z + 360.0) % 360.0)
                end

                print(streetName)

                SendNUIMessage({
                    action = "updateCarhud",
                    toggle = true,
                    speed = speed,
                    street = streetName,
                    fuel = Entity(Vehicle).state.fuel,
                    engine = GetIsVehicleEngineRunning(Vehicle),
                    direction = compass(heading),
                });
        Wait(carhudsleep)
    end

    if not inVeh then
        SendNUIMessage({
            action = "carhudAction",
            toggle = false,
        });
    end
end

function compass(heading)
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
    elseif heading > 292.5 and heading < 337.5 then
        return "NW"
    end
end

RegisterNUICallback('hideOptions', function(data)
    SetNuiFocus(false, false)
end)

RegisterCommand("minimapfix", function(src, args, raw) 
    local minimap = RequestScaleformMovie("minimap")
    SetRadarBigmapEnabled(true, false)
    Wait(0)
    SetRadarBigmapEnabled(false, false)
end)



function GetMinimapAnchor()
    local safezone = GetSafeZoneSize()
    local safezone_x = 1.0 / 20.0
    local safezone_y = 1.0 / 20.0
    local aspect_ratio = GetAspectRatio(0)
    local res_x, res_y = GetActiveScreenResolution()
    local xscale = 1.0 / res_x
    local yscale = 1.0 / res_y
    local Minimap = {}
    Minimap.width = xscale * (res_x / (3.33 * aspect_ratio))
    Minimap.height = yscale * (res_y / 5.174)
    Minimap.left_x = xscale * (res_x * (safezone_x * ((math.abs(safezone - 1.0)) * 10)) + 4)
    Minimap.bottom_y = 1.0 - yscale * (res_y * (safezone_y * ((math.abs(safezone - 1.0)) * 10)) + 1)
    Minimap.right_x = Minimap.left_x + Minimap.width
    Minimap.top_y = Minimap.bottom_y - Minimap.height
    Minimap.x = Minimap.left_x
    Minimap.y = Minimap.top_y
    Minimap.xunit = xscale
    Minimap.yunit = yscale
    return Minimap
end

function drawRct(x, y, width, height, r, g, b, a)
    DrawRect(x + width/2, y + height/2, width, height, r, g, b, a)
end

-- function border()
--     while inVeh do 
--         Wait(0)
--         local ui = GetMinimapAnchor()
--         local thickness = 3
--         drawRct(ui.x, ui.y, ui.width, thickness * ui.yunit, 0, 0, 0, 255)
--         drawRct(ui.x, ui.y + ui.height, ui.width, -thickness * ui.yunit, 0, 0, 0, 255)
--         drawRct(ui.x, ui.y, thickness * ui.xunit, ui.height, 0, 0, 0, 255)
--         drawRct(ui.x + ui.width, ui.y, -thickness * ui.xunit, ui.height, 0, 0, 0, 255)
--     end
-- end

function InitMap()
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
    
    -- 0.0 = nav symbol and icons left
    -- 0.1638 = nav symbol and icons stretched
    -- 0.216 = nav symbol and icons raised up
    SetMinimapComponentPosition("minimap", "L", "B", 0.0 + minimapOffset, -0.017, 0.1638, 0.180)

    -- icons within map
    SetMinimapComponentPosition("minimap_mask", "L", "B", 0.0 + minimapOffset, 0.0, 0.128, 0.20)

    -- -0.01 = map pulled left
    -- 0.025 = map raised up
    -- 0.262 = map stretched
    -- 0.315 = map shorten
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', 0.005 + minimapOffset, 0.025, 0.232, 0.290)
    SetBlipAlpha(GetNorthRadarBlip(), 0)
    SetMinimapClipType(0)

    SetRadarBigmapEnabled(true, false)
    while IsBigmapActive() do
        Wait(0)
        SetRadarBigmapEnabled(false, false)
    end
end


