--[[
    Gilo Helicopter - Police Helicopter Camera System
    Enhanced Edition v2.0.0 with ALPR, Tactical Markers, and Coordination Tools
]]

-- ============================================================================
-- CAMERA SETTINGS
-- ============================================================================

local fov_max = 80.0
local fov_min = 10.0
local zoomspeed = 2.0
local speed_lr = 3.0
local speed_ud = 3.0

-- Control IDs
local toggle_helicam = 51      -- E
local toggle_vision = 25       -- Right Mouse
local toggle_spotlight = 183   -- G (in camera)
local toggle_lock_on = 22      -- Spacebar
local toggle_marker = 73       -- X (place marker)
local toggle_marker_type = 20  -- Z (cycle marker type)

-- ============================================================================
-- STATE VARIABLES
-- ============================================================================

local count, cintura, hover, help, super = 0, 0, 0, 0, 0
local helicam = false
local fov = (fov_max + fov_min) * 0.5
local vision_state = 0
local spotlight_state = false
local spotlightFollowCam = false

-- ALPR/Scanning State
local hasScanned = false
local lockOnTime = 0
local lastRaycastTime = 0
local lastDetectedVehicle = nil

-- Marker State
local activeMarkers = {}
local currentMarkerType = 1  -- 1=Suspect, 2=Officer Down, 3=Perimeter, 4=Generic

-- UI Toggle State
local showSpeed = true
local showStreetName = true
local showAltitude = true

-- ============================================================================
-- MARKER TYPE DEFINITIONS
-- ============================================================================

local MarkerTypes = {
    [1] = { name = "SUSPECT",      color = 1,  sprite = 458, label = "Suspect Location" },
    [2] = { name = "OFFICER DOWN", color = 49, sprite = 304, label = "Officer Down" },
    [3] = { name = "PERIMETER",    color = 5,  sprite = 465, label = "Perimeter Point" },
    [4] = { name = "GENERIC",      color = 3,  sprite = 458, label = "AIR-1 Marker" },
}

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

local function GetVehicleSpeedKmh(vehicle)
    local velocity = GetEntityVelocity(vehicle)
    local speed = math.sqrt(velocity.x^2 + velocity.y^2 + velocity.z^2)
    return speed * 3.6
end

local function GetVehicleSpeedMph(vehicle)
    return GetVehicleSpeedKmh(vehicle) * 0.621371
end

local function SetWaypointToCoords(coords)
    SetNewWaypoint(coords.x, coords.y)
    PlaySoundFrontend(-1, "WAYPOINT_SET", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
end

function MessaggioAiuto(msg, thisFrame, beep, duration)
    AddTextEntry('GiloNotify', msg)
    if thisFrame then
        DisplayHelpTextThisFrame('GiloNotify', false)
    else
        if beep == nil then beep = true end
        BeginTextCommandDisplayHelp('GiloNotify')
        EndTextCommandDisplayHelp(0, false, beep, duration or -1)
    end
end

-- ============================================================================
-- KEYBIND REGISTRATION
-- ============================================================================

CreateThread(function()
    RegisterKeyMapping('HeliCam', GiloHeli.Translations[GiloHeli.Lenguage]["active_heli_cam"], 'keyboard', GiloHeli.ActiveCamKey)
    RegisterKeyMapping('HeliSeatbelt', GiloHeli.Translations[GiloHeli.Lenguage]["seatbelt"], 'keyboard', GiloHeli.SeatbeltKey)
    RegisterKeyMapping('HeliRappel', GiloHeli.Translations[GiloHeli.Lenguage]["rappel"], 'keyboard', GiloHeli.RappelKey)
    RegisterKeyMapping('HeliLights', GiloHeli.Translations[GiloHeli.Lenguage]["lights"], 'keyboard', GiloHeli.LightsKey)
    RegisterKeyMapping('HeliHover', GiloHeli.Translations[GiloHeli.Lenguage]["hover"], 'keyboard', GiloHeli.HoverKey)
    RegisterKeyMapping('HeliSuperHover', GiloHeli.Translations[GiloHeli.Lenguage]["super"], 'keyboard', GiloHeli.SuperHoverKey)
    RegisterKeyMapping('HeliHelp', GiloHeli.Translations[GiloHeli.Lenguage]["help"], 'keyboard', GiloHeli.HelpKey)
    RegisterKeyMapping('HeliSpotlightFollow', GiloHeli.Translations[GiloHeli.Lenguage]["spotlight_follow"] or "Toggle Spotlight Follow", 'keyboard', GiloHeli.SpotlightFollowKey or "L")
    RegisterKeyMapping('HeliToggleUI', GiloHeli.Translations[GiloHeli.Lenguage]["toggle_ui"] or "Toggle UI Elements", 'keyboard', GiloHeli.ToggleUIKey or "F7")
    if GiloHeli.EnableMarkers then
        RegisterKeyMapping('HeliMarker', GiloHeli.Translations[GiloHeli.Lenguage]["place_marker"] or "Place Tactical Marker", 'keyboard', GiloHeli.MarkerKey or "G")
        RegisterKeyMapping('HeliMarkerType', GiloHeli.Translations[GiloHeli.Lenguage]["cycle_marker"] or "Cycle Marker Type", 'keyboard', GiloHeli.MarkerTypeKey or "Z")
    end
end)

-- ============================================================================
-- UI TOGGLE COMMAND
-- ============================================================================

RegisterCommand("HeliToggleUI", function()
    if not helicam then return end

    -- Cycle through UI modes: All -> No Speed -> No Street -> Minimal -> All
    if showSpeed and showStreetName then
        showSpeed = false
        Notifications("UI: Speed hidden")
    elseif not showSpeed and showStreetName then
        showSpeed = true
        showStreetName = false
        Notifications("UI: Street hidden")
    elseif showSpeed and not showStreetName then
        showSpeed = false
        showStreetName = false
        Notifications("UI: Minimal mode")
    else
        showSpeed = true
        showStreetName = true
        Notifications("UI: All elements visible")
    end
    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
end, false)

-- ============================================================================
-- SPOTLIGHT FOLLOW CAMERA TOGGLE
-- ============================================================================

RegisterCommand("HeliSpotlightFollow", function()
    if not CheckVeicoloPlayer() then return end

    spotlightFollowCam = not spotlightFollowCam
    if spotlightFollowCam then
        Notifications(GiloHeli.Translations[GiloHeli.Lenguage]["spotlight_follow_on"] or "Spotlight follows camera")
    else
        Notifications(GiloHeli.Translations[GiloHeli.Lenguage]["spotlight_follow_off"] or "Spotlight manual mode")
    end
    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
end, false)

-- ============================================================================
-- HELP COMMAND
-- ============================================================================

local Ca, Ci, Ho, So = "~r~OFF", "~r~OFF", "~r~OFF", "~r~OFF"

RegisterCommand("HeliHelp", function()
    if CheckVeicoloPlayer() then
        if help == 1 then
            help = 0
        elseif help == 0 then
            help = 1
            while help == 1 do
                Wait(5)
                Ca = count == 1 and "~g~ON" or "~r~OFF"
                Ci = cintura == 1 and "~g~ON" or "~r~OFF"
                Ho = hover == 1 and "~g~ON" or "~r~OFF"
                So = super == 1 and "~g~ON" or "~r~OFF"

                MessaggioAiuto(
                    GiloHeli.Translations[GiloHeli.Lenguage]["cam"] .. Ca .. "\n~w~" ..
                    GiloHeli.Translations[GiloHeli.Lenguage]["seatbelt_help"] .. Ci .. "\n~w~" ..
                    GiloHeli.Translations[GiloHeli.Lenguage]["hovering_help"] .. Ho .. "\n~w~" ..
                    GiloHeli.Translations[GiloHeli.Lenguage]["superhovering_help"] .. So,
                    false, true, 8000
                )

                if GiloHeli.ViewCommandsHelp then
                    AddTextEntry('HelpText', GiloHeli.Translations[GiloHeli.Lenguage]["help_text"])
                    local coords = GetEntityCoords(PlayerPedId())
                    SetFloatingHelpTextWorldPosition(1, coords.x - 7, coords.y + 5, coords.z)
                    SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
                    BeginTextCommandDisplayHelp('HelpText')
                    EndTextCommandDisplayHelp(2, false, false, -1)
                end

                if help == 0 then break end
            end
        end
    end
end, false)

-- ============================================================================
-- HOVER SYSTEMS
-- ============================================================================

RegisterCommand("HeliSuperHover", function()
    if not CheckVeicoloPlayer() then return end

    if super == 1 then
        super = 0
        MessaggioAiuto(GiloHeli.Translations[GiloHeli.Lenguage]["hover_off"], false, true, 8000)
        return
    end

    local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
    local currentSpeed = GetVehicleSpeedKmh(vehicle)

    if currentSpeed > GiloHeli.SuperHoverMaxSpeed then
        Notifications(GiloHeli.Translations[GiloHeli.Lenguage]["too_fast"])
        PlaySoundFrontend(-1, "5_Second_Timer", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", false)
        return
    end

    super = 1
    CreateThread(function()
        MessaggioAiuto(GiloHeli.Translations[GiloHeli.Lenguage]["hover_on"], false, true, 8000)
        while super == 1 and GetHeliMainRotorHealth(vehicle) > 0 and GetHeliTailRotorHealth(vehicle) > 0 and GetVehicleEngineHealth(vehicle, true) > 300 do
            Wait(0)
            SetEntityVelocity(vehicle, 0.0, 0.0, 0.0)
            SetPlaneTurbulenceMultiplier(vehicle, 0.0)
        end
        if super == 1 then
            super = 0
            MessaggioAiuto(GiloHeli.Translations[GiloHeli.Lenguage]["hover_off"], false, true, 8000)
        end
    end)
end, false)

RegisterCommand("HeliHover", function()
    if not CheckVeicoloPlayer() then return end

    if hover == 1 then
        hover = 0
        MessaggioAiuto(GiloHeli.Translations[GiloHeli.Lenguage]["hover_off"], false, true, 8000)
        return
    end

    hover = 1
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)

    CreateThread(function()
        MessaggioAiuto(GiloHeli.Translations[GiloHeli.Lenguage]["hover_on"], false, true, 8000)
        while hover == 1 and GetHeliMainRotorHealth(vehicle) > 0 and GetHeliTailRotorHealth(vehicle) > 0 and GetVehicleEngineHealth(vehicle, true) > 300 do
            Wait(0)
            local velocity = GetEntityVelocity(vehicle)
            SetEntityVelocity(vehicle, velocity.x, velocity.y, 0.0)
            SetPlaneTurbulenceMultiplier(vehicle, 0.0)
        end
        if hover == 1 then
            hover = 0
            MessaggioAiuto(GiloHeli.Translations[GiloHeli.Lenguage]["hover_off"], false, true, 8000)
        end
    end)
end, false)

-- ============================================================================
-- SPOTLIGHT SYSTEM (STATE BAGS + CO-PILOT CONTROL)
-- ============================================================================

RegisterCommand("HeliLights", function()
    if not CheckVeicoloPlayer() then return end

    local vehicle = GetVehiclePedIsIn(PlayerPedId())

    -- Allow pilot OR co-pilot to control spotlight
    local isPilot = GetPedInVehicleSeat(vehicle, -1) == PlayerPedId()
    local isCoPilot = GetPedInVehicleSeat(vehicle, 0) == PlayerPedId()

    if not isPilot and not isCoPilot and not GiloHeli.AllowPassengerSpotlight then
        Notifications(GiloHeli.Translations[GiloHeli.Lenguage]["pilot_only"] or "Only pilot/co-pilot can control spotlight")
        return
    end

    spotlight_state = not spotlight_state
    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)

    if NetworkGetEntityIsNetworked(vehicle) then
        local netId = NetworkGetNetworkIdFromEntity(vehicle)
        TriggerServerEvent('gilo:setSpotlight', netId, spotlight_state)
    else
        SetVehicleSearchlight(vehicle, spotlight_state, false)
    end
end, false)

-- State Bag Handler for Spotlight
AddStateBagChangeHandler('spotlight', nil, function(bagName, key, value)
    local entity = GetEntityFromStateBagName(bagName)
    if entity and DoesEntityExist(entity) and IsEntityAVehicle(entity) then
        SetVehicleSearchlight(entity, value or false, false)
    end
end)

-- ============================================================================
-- SEATBELT SYSTEM
-- ============================================================================

RegisterCommand("HeliSeatbelt", function()
    if not CheckVeicoloPlayer() then return end

    if cintura == 0 then
        cintura = 1
        Notifications(GiloHeli.Translations[GiloHeli.Lenguage]["seatbelt_on"])
        CreateThread(function()
            while cintura == 1 do
                Wait(0)
                DisableControlAction(0, 75, true)
                DisableControlAction(27, 75, true)
            end
        end)
    else
        cintura = 0
        Notifications(GiloHeli.Translations[GiloHeli.Lenguage]["seatbelt_off"])
    end
end, false)

-- ============================================================================
-- RAPPEL SYSTEM
-- ============================================================================

RegisterCommand("HeliRappel", function()
    if not CheckVeicoloPlayer() then return end

    local vehicle = GetVehiclePedIsIn(PlayerPedId())
    local seat = nil

    if GetPedInVehicleSeat(vehicle, 1) == PlayerPedId() then
        seat = 1
    elseif GetPedInVehicleSeat(vehicle, 2) == PlayerPedId() then
        seat = 2
    end

    if seat then
        Notifications(GiloHeli.Translations[GiloHeli.Lenguage]["prepare_rope"])
        PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
        TaskRappelFromHeli(PlayerPedId(), 1)
    else
        Notifications(GiloHeli.Translations[GiloHeli.Lenguage]["not_possible"])
        PlaySoundFrontend(-1, "5_Second_Timer", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", false)
    end
end, false)

-- ============================================================================
-- TACTICAL MARKER SYSTEM (MULTIPLE TYPES)
-- ============================================================================

RegisterCommand("HeliMarkerType", function()
    if not helicam then return end

    currentMarkerType = currentMarkerType + 1
    if currentMarkerType > #MarkerTypes then
        currentMarkerType = 1
    end

    local markerInfo = MarkerTypes[currentMarkerType]
    Notifications("Marker: ~y~" .. markerInfo.name)
    PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FREEMODE_SOUNDSET", false)
end, false)

RegisterCommand("HeliMarker", function()
    if not helicam then return end
    PlaceMarkerFromCamera(nil)
end, false)

-- Receive markers from server
RegisterNetEvent('gilo:receiveMarker', function(markerId, coords, expireTime, markerType)
    local typeInfo = MarkerTypes[markerType] or MarkerTypes[4]

    activeMarkers[markerId] = {
        coords = coords,
        expireTime = expireTime,
        markerType = markerType,
        blip = nil,
        color = typeInfo.color
    }

    -- Create blip
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, typeInfo.sprite)
    SetBlipColour(blip, typeInfo.color)
    SetBlipScale(blip, 0.9)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("AIR-1: " .. typeInfo.name)
    EndTextCommandSetBlipName(blip)
    activeMarkers[markerId].blip = blip

    -- Flash blip for attention
    SetBlipFlashes(blip, true)
    SetTimeout(3000, function()
        if DoesBlipExist(blip) then
            SetBlipFlashes(blip, false)
        end
    end)
end)

RegisterNetEvent('gilo:removeMarker', function(markerId)
    if activeMarkers[markerId] then
        if activeMarkers[markerId].blip then
            RemoveBlip(activeMarkers[markerId].blip)
        end
        activeMarkers[markerId] = nil
    end
end)

-- Draw 3D markers with type-based colors
CreateThread(function()
    while true do
        local sleep = 500
        local now = GetGameTimer()

        for markerId, marker in pairs(activeMarkers) do
            if marker.expireTime and now > marker.expireTime then
                if marker.blip then RemoveBlip(marker.blip) end
                activeMarkers[markerId] = nil
            else
                sleep = 0
                local typeInfo = MarkerTypes[marker.markerType] or MarkerTypes[4]
                local r, g, b = 255, 0, 0

                -- Set color based on marker type
                if marker.markerType == 1 then r, g, b = 255, 0, 0      -- Red: Suspect
                elseif marker.markerType == 2 then r, g, b = 255, 150, 0 -- Orange: Officer Down
                elseif marker.markerType == 3 then r, g, b = 255, 255, 0 -- Yellow: Perimeter
                else r, g, b = 0, 150, 255 end                           -- Blue: Generic

                DrawMarker(1, marker.coords.x, marker.coords.y, marker.coords.z + 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    2.0, 2.0, 50.0,
                    r, g, b, 100,
                    false, false, 2, false, nil, nil, false)
            end
        end

        Wait(sleep)
    end
end)

-- ============================================================================
-- HELICAM COMMAND
-- ============================================================================

RegisterCommand("HeliCam", function()
    if CheckVeicoloPlayer() and CheckAltezzaElicottero(GetVehiclePedIsIn(PlayerPedId())) then
        if count == 0 then
            count = 1
            ActivateHeliCam()
        else
            helicam = false
            count = 0
        end
    end
end, false)

-- ============================================================================
-- MAIN HELICAM SYSTEM
-- ============================================================================

function ActivateHeliCam()
    local lPed = PlayerPedId()
    local heli = GetVehiclePedIsIn(lPed)

    if not CheckAltezzaElicottero(heli) then return end

    PlaySoundFrontend(-1, "SELECT", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", false)
    helicam = true

    -- Setup timecycle and scaleform
    SetTimecycleModifier("heliGunCam")
    SetTimecycleModifierStrength(0.3)

    local scaleform = RequestScaleformMovie("HELI_CAM")
    while not HasScaleformMovieLoaded(scaleform) do Wait(0) end

    -- Create camera
    local cam = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)
    AttachCamToEntity(cam, heli, 0.0, 0.0, -1.5, true)
    SetCamRot(cam, 0.0, 0.0, GetEntityHeading(heli))
    SetCamFov(cam, fov)
    RenderScriptCams(true, false, 0, 1, 0)

    -- Set LSPD logo
    PushScaleformMovieFunction(scaleform, "SET_CAM_LOGO")
    PushScaleformMovieFunctionParameterInt(GiloHeli.CameraLogo or 1)
    PopScaleformMovieFunctionVoid()

    -- State
    local locked_on_vehicle = nil
    local zoomvalue = 0.5
    hasScanned = false
    lockOnTime = 0
    local waypointSet = false

    -- Main camera loop
    while helicam and not IsEntityDead(lPed) and GetVehiclePedIsIn(lPed) == heli and CheckAltezzaElicottero(heli) do
        Wait(0)

        -- Toggle HeliCam off
        if IsControlJustPressed(0, toggle_helicam) then
            PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
            helicam = false
            break
        end

        -- Toggle Vision
        if GiloHeli.UseVision and IsControlJustPressed(0, toggle_vision) then
            PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
            ChangeVision()
        end

        -- Spotlight toggle (in camera) - now allows co-pilot
        if IsControlJustPressed(0, toggle_spotlight) then
            local isPilot = GetPedInVehicleSeat(heli, -1) == lPed
            local isCoPilot = GetPedInVehicleSeat(heli, 0) == lPed

            if isPilot or isCoPilot or GiloHeli.AllowPassengerSpotlight then
                spotlight_state = not spotlight_state
                PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
                if NetworkGetEntityIsNetworked(heli) then
                    TriggerServerEvent('gilo:setSpotlight', NetworkGetNetworkIdFromEntity(heli), spotlight_state)
                else
                    SetVehicleSearchlight(heli, spotlight_state, false)
                end
            end
        end

        -- Spotlight follow camera (sync spotlight direction to camera)
        if spotlightFollowCam and spotlight_state then
            local camRot = GetCamRot(cam, 2)
            -- Note: Native spotlight direction control is limited, this is a visual approximation
        end

        -- Place Marker (in camera)
        if GiloHeli.EnableMarkers and IsControlJustPressed(0, toggle_marker) then
            PlaceMarkerFromCamera(cam)
        end

        -- Cycle marker type
        if GiloHeli.EnableMarkers and IsControlJustPressed(0, toggle_marker_type) then
            currentMarkerType = currentMarkerType + 1
            if currentMarkerType > #MarkerTypes then currentMarkerType = 1 end
            Notifications("Marker: ~y~" .. MarkerTypes[currentMarkerType].name)
            PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FREEMODE_SOUNDSET", false)
        end

        -- Handle locked vehicle
        if locked_on_vehicle then
            if DoesEntityExist(locked_on_vehicle) then
                PointCamAtEntity(cam, locked_on_vehicle, 0.0, 0.0, 0.0, true)
                RenderVehicleInfo(locked_on_vehicle, true)

                -- Auto-waypoint on lock (once)
                if GiloHeli.AutoWaypoint and not waypointSet then
                    local vehCoords = GetEntityCoords(locked_on_vehicle)
                    SetWaypointToCoords(vehCoords)
                    waypointSet = true
                    Notifications(GiloHeli.Translations[GiloHeli.Lenguage]["waypoint_set"] or "Waypoint set to target")
                end

                -- ALPR Integration - scan after lock-on time
                if GiloHeli.EnableALPR and not hasScanned then
                    lockOnTime = lockOnTime + 1
                    if lockOnTime > (GiloHeli.ALPRScanDelay or 180) then
                        local plate = GetVehicleNumberPlateText(locked_on_vehicle)
                        TriggerALPRScan(plate, locked_on_vehicle)
                        hasScanned = true
                    end
                end

                -- Unlock
                if IsControlJustPressed(0, toggle_lock_on) then
                    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
                    locked_on_vehicle = nil
                    hasScanned = false
                    lockOnTime = 0
                    waypointSet = false

                    -- Recreate camera to unlock from entity
                    local rot = GetCamRot(cam, 2)
                    local currentFov = GetCamFov(cam)
                    DestroyCam(cam, false)
                    cam = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)
                    AttachCamToEntity(cam, heli, 0.0, 0.0, -1.5, true)
                    SetCamRot(cam, rot.x, rot.y, rot.z, 2)
                    SetCamFov(cam, currentFov)
                    RenderScriptCams(true, false, 0, 1, 0)
                end
            else
                locked_on_vehicle = nil
                hasScanned = false
                lockOnTime = 0
                waypointSet = false
            end
        else
            -- Free camera mode
            zoomvalue = (1.0 / (fov_max - fov_min)) * (fov - fov_min)
            CheckInputRotation(cam, zoomvalue)

            -- Throttled vehicle detection (every 200ms)
            local now = GetGameTimer()
            if now - lastRaycastTime > 200 then
                lastRaycastTime = now
                lastDetectedVehicle = GetVehicleInView(cam)
            end

            if DoesEntityExist(lastDetectedVehicle) then
                RenderVehicleInfo(lastDetectedVehicle, false)

                if IsControlJustPressed(0, toggle_lock_on) then
                    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
                    locked_on_vehicle = lastDetectedVehicle
                    lockOnTime = 0
                    hasScanned = false
                    waypointSet = false
                end
            end
        end

        -- Handle zoom with sound
        HandleZoom(cam)

        -- Hide HUD
        HideHUDThisFrame()

        -- Update scaleform overlay
        PushScaleformMovieFunction(scaleform, "SET_ALT_FOV_HEADING")
        PushScaleformMovieFunctionParameterFloat(GetEntityCoords(heli).z)
        PushScaleformMovieFunctionParameterFloat(zoomvalue)
        PushScaleformMovieFunctionParameterFloat(GetCamRot(cam, 2).z)
        PopScaleformMovieFunctionVoid()

        DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)

        -- Draw street name (if enabled)
        if GiloHeli.ShowStreetName and showStreetName then
            DrawStreetName(cam)
        end

        -- Draw current marker type indicator
        if GiloHeli.EnableMarkers then
            DrawMarkerTypeIndicator()
        end
    end

    -- Cleanup
    helicam = false
    count = 0
    ClearTimecycleModifier()
    fov = (fov_max + fov_min) * 0.5
    RenderScriptCams(false, false, 0, 1, 0)
    SetScaleformMovieAsNoLongerNeeded(scaleform)
    DestroyCam(cam, false)
    SetNightvision(false)
    SetSeethrough(false)
end

-- ============================================================================
-- ALPR INTEGRATION
-- ============================================================================

function TriggerALPRScan(plate, vehicle)
    local model = GetEntityModel(vehicle)
    local vehName = GetLabelText(GetDisplayNameFromVehicleModel(model))

    -- Notify player
    Notifications(GiloHeli.Translations[GiloHeli.Lenguage]["alpr_scanned"] or ("ALPR: " .. plate .. " scanned"))
    PlaySoundFrontend(-1, "TENNIS_MATCH_POINT", "HUD_AWARDS", false)

    -- Trigger dispatch/MDT integration
    if GiloHeli.DispatchSystem == "qs-dispatch" then
        TriggerServerEvent('qs-dispatch:server:notify', {
            job = {"police", "sheriff"},
            title = "ALPR Scan - AIR-1",
            message = "Plate: " .. plate .. " | Vehicle: " .. vehName,
            time = 10000
        })
    elseif GiloHeli.DispatchSystem == "ps-dispatch" then
        TriggerServerEvent('ps-dispatch:server:notify', {
            dispatchcodename = "alpr",
            dispatchCode = "10-29",
            title = "ALPR Scan",
            description = "Plate: " .. plate .. " | Vehicle: " .. vehName,
        })
    elseif GiloHeli.DispatchSystem == "cd_dispatch" then
        TriggerServerEvent('cd_dispatch:AddNotification', {
            job_table = {'police', 'sheriff'},
            coords = GetEntityCoords(vehicle),
            title = "ALPR Scan - AIR-1",
            message = "Plate: " .. plate .. " | Vehicle: " .. vehName,
            flash = 0,
            blip = {
                sprite = 225,
                scale = 1.0,
                colour = 3,
                flashes = false,
                text = "ALPR Hit",
                time = 10000,
            }
        })
    elseif GiloHeli.DispatchSystem == "wasabi_dispatch" then
        local coords = GetEntityCoords(vehicle)
        exports['wasabi_dispatch']:notify({
            title = "ALPR Scan - AIR-1",
            message = "Plate: **" .. plate .. "** | Vehicle: " .. vehName,
            icon = "helicopter",
            duration = 10000,
            jobs = {"police", "sheriff", "lspd", "bcso"},
            coords = coords,
            blip = {
                sprite = 225,
                color = 3,
                scale = 1.0,
                label = "ALPR Hit - " .. plate,
                duration = 10000,
            }
        })
    else
        -- Generic server event for custom MDT systems
        TriggerServerEvent('gilo:alprScan', {
            plate = plate,
            vehicle = vehName,
            coords = GetEntityCoords(vehicle)
        })
    end
end

-- ============================================================================
-- STREET NAME DISPLAY
-- ============================================================================

function DrawStreetName(cam)
    local camCoords = GetCamCoord(cam)
    local streetHash, crossingHash = GetStreetNameAtCoord(camCoords.x, camCoords.y, camCoords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    local crossingName = GetStreetNameFromHashKey(crossingHash)

    local locationText = streetName
    if crossingName and crossingName ~= "" then
        locationText = streetName .. " / " .. crossingName
    end

    local zone = GetNameOfZone(camCoords.x, camCoords.y, camCoords.z)
    local zoneName = GetLabelText(zone)

    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(0.0, 0.4)
    SetTextColour(255, 255, 255, 200)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString("LOC: " .. locationText .. " | " .. zoneName)
    DrawText(0.01, 0.95)
end

-- ============================================================================
-- MARKER TYPE INDICATOR
-- ============================================================================

function DrawMarkerTypeIndicator()
    local typeInfo = MarkerTypes[currentMarkerType]

    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(0.0, 0.35)
    SetTextColour(255, 255, 255, 180)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString("MARKER: " .. typeInfo.name .. " [Z to change]")
    DrawText(0.01, 0.91)
end

-- ============================================================================
-- ENHANCED VEHICLE INFO DISPLAY
-- ============================================================================

function RenderVehicleInfo(vehicle, isLocked)
    local model = GetEntityModel(vehicle)
    local vehName = GetLabelText(GetDisplayNameFromVehicleModel(model))
    local plate = GetVehicleNumberPlateText(vehicle)
    local speed = math.floor(GetVehicleSpeedKmh(vehicle))
    local speedMph = math.floor(GetVehicleSpeedMph(vehicle))

    local lockStatus = isLocked and "~g~[LOCKED]" or "~y~[TRACKING]"

    local infoText = lockStatus .. "~w~\n"
    infoText = infoText .. "Vehicle: " .. vehName .. "\n"
    infoText = infoText .. "Plate: ~y~" .. plate .. "~w~"

    -- Only show speed if enabled
    if showSpeed then
        infoText = infoText .. "\nSpeed: " .. speed .. " KM/H (" .. speedMph .. " MPH)"
    end

    -- ALPR scan progress
    if isLocked and GiloHeli.EnableALPR and not hasScanned then
        local progress = math.min(100, math.floor((lockOnTime / (GiloHeli.ALPRScanDelay or 180)) * 100))
        infoText = infoText .. "\n~b~ALPR Scan: " .. progress .. "%"
    elseif isLocked and hasScanned then
        infoText = infoText .. "\n~g~ALPR: SCANNED"
    end

    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(0.0, 0.5)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(infoText)
    DrawText(0.55, 0.85)
end

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

function PlaceMarkerFromCamera(cam)
    local camCoords, camRot

    if cam then
        camCoords = GetCamCoord(cam)
        camRot = GetCamRot(cam, 2)
    else
        camCoords = GetGameplayCamCoord()
        camRot = GetGameplayCamRot(2)
    end

    local forward = RotAnglesToVec(camRot)

    local rayHandle = StartShapeTestRay(
        camCoords.x, camCoords.y, camCoords.z,
        camCoords.x + forward.x * 1000.0,
        camCoords.y + forward.y * 1000.0,
        camCoords.z + forward.z * 1000.0,
        1, PlayerPedId(), 0
    )

    local _, hit, hitCoords = GetShapeTestResult(rayHandle)

    if hit then
        TriggerServerEvent('gilo:placeMarker', hitCoords, currentMarkerType)
        PlaySoundFrontend(-1, "WAYPOINT_SET", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
        Notifications(MarkerTypes[currentMarkerType].label .. " placed")
    end
end

function CheckVeicoloPlayer()
    local vehicle = GetVehiclePedIsIn(PlayerPedId())
    if vehicle == 0 then return false end

    for i = 1, #GiloHeli.Vehicles do
        if IsVehicleModel(vehicle, GiloHeli.Vehicles[i]) then
            return true
        end
    end
    return false
end

function CheckAltezzaElicottero(heli)
    return GetEntityHeightAboveGround(heli) > 1.5
end

function ChangeVision()
    if vision_state == 0 then
        SetNightvision(true)
        vision_state = 1
    elseif vision_state == 1 then
        SetNightvision(false)
        SetSeethrough(true)
        vision_state = 2
    else
        SetSeethrough(false)
        vision_state = 0
    end
end

function HideHUDThisFrame()
    HideHelpTextThisFrame()
    HideHudAndRadarThisFrame()
    HideHudComponentThisFrame(19)
    HideHudComponentThisFrame(1)
    HideHudComponentThisFrame(2)
    HideHudComponentThisFrame(3)
    HideHudComponentThisFrame(4)
    HideHudComponentThisFrame(13)
    HideHudComponentThisFrame(11)
    HideHudComponentThisFrame(12)
    HideHudComponentThisFrame(15)
    HideHudComponentThisFrame(18)
end

function CheckInputRotation(cam, zoomvalue)
    local rightAxisX = GetDisabledControlNormal(0, 220)
    local rightAxisY = GetDisabledControlNormal(0, 221)
    local rotation = GetCamRot(cam, 2)

    if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
        local new_z = rotation.z + rightAxisX * -1.0 * speed_ud * (zoomvalue + 0.1)
        local new_x = math.max(math.min(20.0, rotation.x + rightAxisY * -1.0 * speed_lr * (zoomvalue + 0.1)), -89.5)
        SetCamRot(cam, new_x, 0.0, new_z, 2)
    end
end

local lastZoomSound = 0
function HandleZoom(cam)
    local changed = false

    if IsControlJustPressed(0, 241) then
        fov = math.max(fov - zoomspeed, fov_min)
        changed = true
    end
    if IsControlJustPressed(0, 242) then
        fov = math.min(fov + zoomspeed, fov_max)
        changed = true
    end

    if changed then
        local now = GetGameTimer()
        if now - lastZoomSound > 100 then
            PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FREEMODE_SOUNDSET", false)
            lastZoomSound = now
        end
    end

    local current_fov = GetCamFov(cam)
    if math.abs(fov - current_fov) < 0.1 then
        fov = current_fov
    end
    SetCamFov(cam, current_fov + (fov - current_fov) * 0.05)
end

function GetVehicleInView(cam)
    local coords = GetCamCoord(cam)
    local forward = RotAnglesToVec(GetCamRot(cam, 2))

    local rayHandle = CastRayPointToPoint(
        coords.x, coords.y, coords.z,
        coords.x + forward.x * 200.0,
        coords.y + forward.y * 200.0,
        coords.z + forward.z * 200.0,
        10, GetVehiclePedIsIn(PlayerPedId()), 0
    )

    local _, _, _, _, entityHit = GetRaycastResult(rayHandle)

    if entityHit > 0 and IsEntityAVehicle(entityHit) then
        return entityHit
    end
    return nil
end

function RotAnglesToVec(rot)
    local z = math.rad(rot.z)
    local x = math.rad(rot.x)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end
