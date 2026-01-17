--[[
    Gilo Helicopter - Server Side
    Enhanced Edition v2.1.0
    State Bags + Tactical Marker System + Version Checker
]]

local RESOURCE_VERSION = "2.1.0"

-- ============================================================================
-- VERSION CHECKER
-- ============================================================================

CreateThread(function()
    Wait(5000) -- Wait for server to fully start

    print("^2[gilo-helicopter]^7 Enhanced Edition v" .. RESOURCE_VERSION .. " loaded")
    print("^2[gilo-helicopter]^7 Features: ALPR, Tactical Markers, State Bag Sync")

    -- GitHub version check
    PerformHttpRequest("https://api.github.com/repos/DaemonAlex/gilo-helicopter/releases/latest", function(err, text, headers)
        if err == 200 then
            local data = json.decode(text)
            if data and data.tag_name then
                local latestVersion = data.tag_name:gsub("v", "")
                if latestVersion ~= RESOURCE_VERSION then
                    print("^3[gilo-helicopter]^7 Update available: v" .. latestVersion .. " (current: v" .. RESOURCE_VERSION .. ")")
                    print("^3[gilo-helicopter]^7 Download: https://github.com/DaemonAlex/gilo-helicopter")
                end
            end
        end
    end, "GET", "", { ["User-Agent"] = "FiveM" })
end)

-- ============================================================================
-- SPOTLIGHT STATE BAG SYNC
-- ============================================================================

RegisterNetEvent('gilo:setSpotlight', function(netId, state)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) then
        Entity(entity).state:set('spotlight', state, true)
    end
end)

-- ============================================================================
-- TACTICAL MARKER SYSTEM (WITH TYPES)
-- ============================================================================

local markers = {}
local markerIdCounter = 0

-- Configuration
local MARKER_DURATION = 60000  -- 60 seconds (can be overridden by config)
local MARKER_JOBS = { 'police', 'sheriff', 'lspd', 'bcso', 'sasp', 'trooper', 'highway' }

-- Marker type names for logging
local MARKER_TYPE_NAMES = {
    [1] = "SUSPECT",
    [2] = "OFFICER DOWN",
    [3] = "PERIMETER",
    [4] = "GENERIC"
}

-- Helper to check if player has police job (framework agnostic)
local function IsPlayerPolice(source)
    -- Try QBCore/Qbox
    if GetResourceState('qb-core') == 'started' then
        local success, QBCore = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        if success and QBCore then
            local player = QBCore.Functions.GetPlayer(source)
            if player then
                local job = player.PlayerData.job.name
                for _, policeJob in ipairs(MARKER_JOBS) do
                    if job == policeJob then return true end
                end
                return false
            end
        end
    end

    -- Try ESX
    if GetResourceState('es_extended') == 'started' then
        local success, ESX = pcall(function()
            return exports['es_extended']:getSharedObject()
        end)
        if success and ESX then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                local job = xPlayer.getJob().name
                for _, policeJob in ipairs(MARKER_JOBS) do
                    if job == policeJob then return true end
                end
                return false
            end
        end
    end

    -- Fallback: Check ACE permission
    if IsPlayerAceAllowed(source, 'gilo.helicopter.marker') then
        return true
    end

    -- Default allow (for standalone)
    return true
end

-- Get all online police players
local function GetPolicePlayers()
    local policePlayers = {}
    local players = GetPlayers()

    for _, playerId in ipairs(players) do
        if IsPlayerPolice(tonumber(playerId)) then
            table.insert(policePlayers, tonumber(playerId))
        end
    end

    return policePlayers
end

-- Place a tactical marker (with type support)
RegisterNetEvent('gilo:placeMarker', function(coords, markerType)
    local source = source

    -- Validate source is police
    if not IsPlayerPolice(source) then return end

    -- Default to generic marker if no type specified
    markerType = markerType or 4

    markerIdCounter = markerIdCounter + 1
    local markerId = markerIdCounter
    local expireTime = GetGameTimer() + MARKER_DURATION

    markers[markerId] = {
        coords = coords,
        placedBy = source,
        expireTime = expireTime,
        markerType = markerType
    }

    -- Send to all police players
    local policePlayers = GetPolicePlayers()
    for _, playerId in ipairs(policePlayers) do
        TriggerClientEvent('gilo:receiveMarker', playerId, markerId, coords, expireTime, markerType)
    end

    -- Debug log marker placement
    if GiloHeli and GiloHeli.Debug then
        local playerName = GetPlayerName(source)
        local typeName = MARKER_TYPE_NAMES[markerType] or "UNKNOWN"
        print(('[gilo-helicopter] %s placed %s marker at %.2f, %.2f, %.2f'):format(
            playerName, typeName, coords.x, coords.y, coords.z
        ))
    end

    -- Auto-remove after duration
    SetTimeout(MARKER_DURATION, function()
        if markers[markerId] then
            markers[markerId] = nil
            for _, playerId in ipairs(GetPolicePlayers()) do
                TriggerClientEvent('gilo:removeMarker', playerId, markerId)
            end
        end
    end)
end)

-- Send existing markers to newly connected police
AddEventHandler('playerJoining', function()
    local source = source

    SetTimeout(5000, function() -- Wait for player to fully load
        if IsPlayerPolice(source) then
            local now = GetGameTimer()
            for markerId, marker in pairs(markers) do
                if marker.expireTime > now then
                    TriggerClientEvent('gilo:receiveMarker', source, markerId, marker.coords, marker.expireTime, marker.markerType or 4)
                end
            end
        end
    end)
end)

-- ============================================================================
-- ALPR LOGGING (Generic Handler)
-- ============================================================================

RegisterNetEvent('gilo:alprScan', function(data)
    local source = source

    -- Debug log ALPR scan
    if GiloHeli and GiloHeli.Debug then
        local playerName = GetPlayerName(source)
        print(('[gilo-helicopter] ALPR Scan by %s - Plate: %s, Vehicle: %s at %.2f, %.2f'):format(
            playerName,
            data.plate,
            data.vehicle,
            data.coords.x,
            data.coords.y
        ))
    end

    -- You can add your custom MDT integration here
    -- Example: TriggerEvent('your-mdt:addALPRHit', data.plate, data.vehicle, data.coords)
end)

-- ============================================================================
-- LEGACY SPOTLIGHT EVENTS (Fallback for older clients)
-- ============================================================================

RegisterNetEvent('Elicottero:Accendiluce', function(state)
    local serverID = source
    TriggerClientEvent('Ritorno:AccendiLuci', -1, serverID, state)
end)
