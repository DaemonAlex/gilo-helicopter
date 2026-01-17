--[[
    Gilo Helicopter - Configuration
    Enhanced Edition v2.1.0
    ALPR, Markers, Street Names, Auto-Waypoint, Co-Pilot Control
]]

GiloHeli = {}

-- ============================================================================
-- DEBUG MODE
-- ============================================================================

GiloHeli.Debug = false                   -- Enable debug logging (marker placement, ALPR scans)

-- ============================================================================
-- GENERAL SETTINGS
-- ============================================================================

GiloHeli.UseVision = true                  -- Enable night/thermal vision modes
GiloHeli.ViewCommandsHelp = true           -- Show floating help text with keybinds
GiloHeli.ShowStreetName = true             -- Show street name on camera overlay
GiloHeli.CameraLogo = 1                    -- 0 = No logo, 1 = LSPD logo

-- ============================================================================
-- HELICOPTER WHITELIST
-- ============================================================================

GiloHeli.Vehicles = {
    "polmav",                            -- Police Maverick
    "buzzard",                           -- Buzzard
    "frogger",                           -- Frogger
    "maverick",                          -- Civilian Maverick
    -- Add your custom helicopter models here
}

-- ============================================================================
-- HOVER SETTINGS
-- ============================================================================

GiloHeli.SuperHoverMaxSpeed = 10           -- Max speed (km/h) to engage Super Hover

-- ============================================================================
-- ALPR / MDT INTEGRATION
-- ============================================================================

GiloHeli.EnableALPR = true                 -- Enable automatic plate scanning
GiloHeli.ALPRScanDelay = 180               -- Frames to lock-on before scan (~3 sec at 60fps)

-- Dispatch system integration
-- Options: "qs-dispatch", "ps-dispatch", "cd_dispatch", "wasabi_dispatch", "generic"
GiloHeli.DispatchSystem = "generic"

-- ============================================================================
-- AUTO-WAYPOINT
-- ============================================================================

GiloHeli.AutoWaypoint = true               -- Automatically set waypoint when locking on vehicle

-- ============================================================================
-- SPOTLIGHT CONTROL
-- ============================================================================

GiloHeli.AllowPassengerSpotlight = false   -- Allow rear passengers to control spotlight
                                         -- (Pilot and Co-Pilot can always control)

-- ============================================================================
-- TACTICAL MARKERS
-- ============================================================================

GiloHeli.EnableMarkers = true              -- Enable tactical ground markers
GiloHeli.MarkerKey = "G"                   -- Key to place marker (while in camera)
GiloHeli.MarkerTypeKey = "Z"               -- Key to cycle marker types
GiloHeli.MarkerDuration = 60               -- Marker duration in seconds

-- Marker Types:
-- 1 = Suspect (Red)
-- 2 = Officer Down (Orange)
-- 3 = Perimeter (Yellow)
-- 4 = Generic (Blue)

-- ============================================================================
-- KEYBINDS (Default keys - players can rebind in FiveM settings)
-- ============================================================================

GiloHeli.HelpKey = "U"                     -- Show help/status
GiloHeli.ActiveCamKey = "E"                -- Toggle HeliCam
GiloHeli.SeatbeltKey = "B"                 -- Toggle Seatbelt
GiloHeli.RappelKey = "X"                   -- Rappel from helicopter
GiloHeli.LightsKey = "H"                   -- Toggle Spotlight
GiloHeli.HoverKey = "J"                    -- Toggle Hover Mode
GiloHeli.SuperHoverKey = "K"               -- Toggle Super Hover Mode
GiloHeli.SpotlightFollowKey = "L"          -- Toggle Spotlight Follow Camera
GiloHeli.ToggleUIKey = "F7"                -- Cycle UI display modes

-- ============================================================================
-- NOTIFICATION SYSTEM
-- ============================================================================

function GiloHeli.Notify(text)
    -- ox_lib (recommended)
    if GetResourceState('ox_lib') == 'started' then
        lib.notify({ description = text, type = 'inform' })
        return
    end

    -- QBCore
    if GetResourceState('qb-core') == 'started' then
        TriggerEvent('QBCore:Notify', text, 'primary')
        return
    end

    -- ESX
    if GetResourceState('es_extended') == 'started' then
        TriggerEvent('esx:showNotification', text)
        return
    end

    -- wasabi_notify
    if GetResourceState('wasabi_notify') == 'started' then
        exports['wasabi_notify']:notify('AIR-1', text, 5000, 'info')
        return
    end

    -- Native fallback
    SetNotificationTextEntry('STRING')
    AddTextComponentString(text)
    DrawNotification(false, false)
end

-- ============================================================================
-- LANGUAGE SETTINGS
-- ============================================================================

GiloHeli.Language = "en"                   -- "en" for English, "it" for Italian

GiloHeli.Translations = {
    -- ========================================================================
    -- ITALIAN
    -- ========================================================================
    ["it"] = {
        -- Keybind Descriptions
        ["active_heli_cam"] = "Attiva Camera Elicottero",
        ["seatbelt"] = "Cintura Elicottero",
        ["rappel"] = "Calati con Fune",
        ["lights"] = "Accendi/Spegni Faro",
        ["hover"] = "Hover",
        ["super"] = "Super Hover",
        ["help"] = "Aiuto Elicottero",
        ["place_marker"] = "Piazza Marcatore",
        ["cycle_marker"] = "Cambia Tipo Marcatore",
        ["spotlight_follow"] = "Faro Segue Camera",
        ["toggle_ui"] = "Cambia Elementi UI",

        -- Status Display
        ["cam"] = "Camera: ",
        ["seatbelt_help"] = "Cintura: ",
        ["hovering_help"] = "Hovering: ",
        ["superhovering_help"] = "Super-Hovering: ",
        ["help_text"] = GiloHeli.ActiveCamKey .. " Camera\n" ..
                        GiloHeli.SeatbeltKey .. " Cintura\n" ..
                        GiloHeli.RappelKey .. " Calarti\n" ..
                        GiloHeli.LightsKey .. " Faro\n" ..
                        GiloHeli.HoverKey .. " Hover\n" ..
                        GiloHeli.SuperHoverKey .. " Super Hover",

        -- Camera Info
        ["plate"] = "Targa: ",
        ["vehicle"] = "Veicolo: ",

        -- Seatbelt
        ["seatbelt_on"] = "Cintura allacciata",
        ["seatbelt_off"] = "Cintura sganciata",

        -- Rappel
        ["prepare_rope"] = "Stai preparando l'attrezzatura per calarti.",
        ["not_possible"] = "Non puoi calarti da questo sedile.",

        -- Hover
        ["hover_on"] = "Auto-hover ~g~ATTIVO",
        ["hover_off"] = "Auto-hover ~r~DISATTIVO",
        ["too_fast"] = "Troppo veloce! Rallenta sotto i " .. GiloHeli.SuperHoverMaxSpeed .. " km/h",

        -- ALPR
        ["alpr_scanned"] = "ALPR: Targa scansionata",

        -- Markers
        ["marker_placed"] = "Marcatore tattico posizionato",

        -- Spotlight
        ["pilot_only"] = "Solo pilota/copilota può controllare il faro",
        ["spotlight_follow_on"] = "Faro segue la camera",
        ["spotlight_follow_off"] = "Faro in modalità manuale",

        -- Waypoint
        ["waypoint_set"] = "Waypoint impostato sul bersaglio",
    },

    -- ========================================================================
    -- ENGLISH
    -- ========================================================================
    ["en"] = {
        -- Keybind Descriptions
        ["active_heli_cam"] = "Toggle HeliCam",
        ["seatbelt"] = "Toggle Seatbelt",
        ["rappel"] = "Rappel from Helicopter",
        ["lights"] = "Toggle Spotlight",
        ["hover"] = "Toggle Hover",
        ["super"] = "Toggle Super Hover",
        ["help"] = "Helicopter Help",
        ["place_marker"] = "Place Tactical Marker",
        ["cycle_marker"] = "Cycle Marker Type",
        ["spotlight_follow"] = "Toggle Spotlight Follow",
        ["toggle_ui"] = "Toggle UI Elements",

        -- Status Display
        ["cam"] = "Camera: ",
        ["seatbelt_help"] = "Seatbelt: ",
        ["hovering_help"] = "Hovering: ",
        ["superhovering_help"] = "Super-Hovering: ",
        ["help_text"] = GiloHeli.ActiveCamKey .. " Camera\n" ..
                        GiloHeli.SeatbeltKey .. " Seatbelt\n" ..
                        GiloHeli.RappelKey .. " Rappel\n" ..
                        GiloHeli.LightsKey .. " Spotlight\n" ..
                        GiloHeli.HoverKey .. " Hover\n" ..
                        GiloHeli.SuperHoverKey .. " Super Hover",

        -- Camera Info
        ["plate"] = "Plate: ",
        ["vehicle"] = "Vehicle: ",

        -- Seatbelt
        ["seatbelt_on"] = "Seatbelt fastened",
        ["seatbelt_off"] = "Seatbelt removed",

        -- Rappel
        ["prepare_rope"] = "Preparing rappel equipment...",
        ["not_possible"] = "Cannot rappel from this seat.",

        -- Hover
        ["hover_on"] = "Auto Hover ~g~ENGAGED",
        ["hover_off"] = "Auto Hover ~r~DISENGAGED",
        ["too_fast"] = "Too fast! Slow down below " .. GiloHeli.SuperHoverMaxSpeed .. " km/h",

        -- ALPR
        ["alpr_scanned"] = "ALPR: Plate scanned and sent to dispatch",

        -- Markers
        ["marker_placed"] = "Tactical marker placed",

        -- Spotlight
        ["pilot_only"] = "Only pilot/co-pilot can control spotlight",
        ["spotlight_follow_on"] = "Spotlight follows camera",
        ["spotlight_follow_off"] = "Spotlight manual mode",

        -- Waypoint
        ["waypoint_set"] = "Waypoint set to target vehicle",
    }
}
