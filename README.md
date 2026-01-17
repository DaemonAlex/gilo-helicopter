# Gilo Helicopter - Enhanced Edition

A premium-quality police helicopter camera system for FiveM with ALPR integration, tactical markers, and State Bag synchronization.

![FiveM](https://img.shields.io/badge/FiveM-Ready-green)
![Lua](https://img.shields.io/badge/Lua-5.4-blue)
![Version](https://img.shields.io/badge/Version-2.1.0-orange)
![Performance](https://img.shields.io/badge/Idle-0.00ms-brightgreen)

---

## What's New in v2.1.0

| Feature | Description |
|---------|-------------|
| **Co-Pilot Control** | Co-pilot can now control spotlight alongside pilot |
| **Auto-Waypoint** | Automatically sets GPS waypoint when locking on vehicle |
| **Marker Types** | 4 tactical marker types: Suspect, Officer Down, Perimeter, Generic |
| **Toggleable UI** | Cycle UI elements with F7 (speed, street name, minimal) |
| **wasabi_dispatch** | ALPR now supports wasabi_dispatch integration |
| **wasabi_notify** | Notifications now support wasabi_notify |

### Previous (v2.0.0)

| Feature | Description |
|---------|-------------|
| **State Bag Sync** | Spotlight now syncs instantly via State Bags (no lag) |
| **ALPR Integration** | Auto-scan plates after 3s lock-on, sends to dispatch |
| **Tactical Markers** | Place ground markers visible to all police units |
| **Street Names** | Real-time location display on camera overlay |
| **Enhanced Lock-On** | Shows vehicle model, plate, AND live speed |
| **Throttled Raycasts** | Vehicle detection runs every 200ms (was every frame) |
| **Sound Effects** | Audio feedback on zoom and actions |
| **Multi-Framework** | Works with QBCore, ESX, Qbox, or Standalone |

---

## Table of Contents

- [Features](#features)
- [Performance](#performance)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Controls](#controls)
- [ALPR / MDT Integration](#alpr--mdt-integration)
- [Tactical Markers](#tactical-markers)
- [Framework Support](#framework-support)
- [Changelog](#changelog)

---

## Features

### HeliCam System
- LSPD-branded scaleform overlay
- Smooth 360° pan and tilt
- Variable zoom (10° to 80° FOV)
- Real-time telemetry: Altitude, FOV, Heading
- **NEW:** Street name and zone display

### Vision Modes
- Normal daylight view
- Night vision (green tint)
- Thermal/infrared vision

### Enhanced Vehicle Tracking
- Automatic vehicle detection (200ms intervals)
- **NEW:** Displays vehicle model name
- **NEW:** Displays live speed (KM/H and MPH)
- License plate reader
- Lock-on tracking with smooth follow

### ALPR Integration
- Automatic plate scanning after 3-second lock-on
- Visual scan progress indicator
- Sends plate data to dispatch/MDT systems
- Supports: qs-dispatch, ps-dispatch, cd_dispatch, wasabi_dispatch, generic

### Tactical Markers
- Place 3D markers visible to all police units
- **4 Marker Types:** Suspect (Red), Officer Down (Orange), Perimeter (Yellow), Generic (Blue)
- Markers appear on map as blips with type-specific colors
- Auto-expire after 60 seconds
- Perfect for directing ground units

### Spotlight System
- State Bag synchronization (instant, no lag)
- Synced across all players (OneSync compatible)
- **Pilot AND Co-Pilot control** (configurable)
- Optional spotlight-follows-camera mode

### Auto-Waypoint
- Automatically sets GPS waypoint when locking onto a vehicle
- Plays waypoint sound for confirmation
- Can be disabled in config

### Flight Assist
- Hover Mode (maintain altitude)
- Super Hover (complete freeze)
- Speed limiter prevents Super Hover abuse
- Auto-disengage on damage

### Safety Systems
- Seatbelt prevents accidental exits
- Rappel from rear passenger seats
- Minimum altitude requirement

---

## Performance

| State | Resource Usage |
|-------|----------------|
| Idle (not in helicopter) | **0.00ms** |
| In helicopter, camera off | **0.00ms** |
| Camera active, free look | **~0.02ms** |
| Camera active, locked on | **~0.01ms** |

**Optimizations:**
- Vehicle raycast throttled to 200ms intervals
- State Bags replace network events
- Efficient marker rendering with sleep states

---

## Requirements

| Dependency | Required | Notes |
|------------|----------|-------|
| FiveM Server | Yes | OneSync Infinity recommended |
| [ox_lib](https://github.com/overextended/ox_lib) | No | Recommended for notifications |

---

## Installation

1. Download and extract to your resources folder:
   ```
   resources/
   └── [standalone]/
       └── gilo-helicopter/
   ```

2. Add to `server.cfg`:
   ```cfg
   ensure gilo-helicopter
   ```

3. Configure `config.lua` to your preferences

4. Restart server

---

## Configuration

### Basic Settings

```lua
GiloHeli.Debug = false                 -- Enable debug logging in server console
GiloHeli.UseVision = true              -- Night/thermal vision
GiloHeli.ShowStreetName = true         -- Street name on overlay
GiloHeli.CameraLogo = 1                -- 0=none, 1=LSPD
```

### Allowed Helicopters

```lua
GiloHeli.Vehicles = {
    "polmav",
    "buzzard",
    "frogger",
    "maverick",
}
```

### ALPR Settings

```lua
GiloHeli.EnableALPR = true             -- Enable plate scanning
GiloHeli.ALPRScanDelay = 180           -- ~3 seconds at 60fps
GiloHeli.DispatchSystem = "generic"    -- "qs-dispatch", "ps-dispatch", "cd_dispatch", "wasabi_dispatch", "generic"
```

### Auto-Waypoint & Spotlight

```lua
GiloHeli.AutoWaypoint = true           -- Set GPS waypoint on vehicle lock
GiloHeli.AllowPassengerSpotlight = false -- Allow rear passengers to control spotlight
```

### Tactical Markers

```lua
GiloHeli.EnableMarkers = true          -- Enable ground markers
GiloHeli.MarkerKey = "G"               -- Key to place marker
GiloHeli.MarkerTypeKey = "Z"           -- Key to cycle marker types
GiloHeli.MarkerDuration = 60           -- Seconds until expire
-- Types: 1=Suspect(Red), 2=Officer Down(Orange), 3=Perimeter(Yellow), 4=Generic(Blue)
```

### Keybinds

```lua
GiloHeli.ActiveCamKey = "E"            -- Toggle camera
GiloHeli.SeatbeltKey = "B"             -- Seatbelt
GiloHeli.RappelKey = "X"               -- Rappel
GiloHeli.LightsKey = "H"               -- Spotlight
GiloHeli.HoverKey = "J"                -- Hover
GiloHeli.SuperHoverKey = "K"           -- Super Hover
GiloHeli.HelpKey = "U"                 -- Help display
GiloHeli.SpotlightFollowKey = "L"      -- Spotlight follows camera
GiloHeli.ToggleUIKey = "F7"            -- Cycle UI display modes
```

---

## Controls

### General

| Key | Action |
|-----|--------|
| `E` | Toggle HeliCam |
| `H` | Toggle Spotlight (pilot/co-pilot) |
| `B` | Toggle Seatbelt |
| `X` | Rappel (rear seats) |
| `J` | Toggle Hover |
| `K` | Toggle Super Hover |
| `U` | Show Help/Status |
| `L` | Toggle Spotlight Follow Camera |
| `F7` | Cycle UI Display Modes |

### While in HeliCam

| Input | Action |
|-------|--------|
| Mouse | Pan camera |
| Scroll | Zoom in/out |
| Right Click | Cycle vision modes |
| Spacebar | Lock-on / Release vehicle |
| `G` | Place tactical marker |
| `Z` | Cycle marker type |
| `E` | Exit camera |

---

## ALPR / MDT Integration

When you lock onto a vehicle for 3+ seconds, the system automatically:

1. Scans the license plate
2. Shows "ALPR: SCANNED" on the overlay
3. Sends plate data to your dispatch system

### Supported Dispatch Systems

**qs-dispatch:**
```lua
GiloHeli.DispatchSystem = "qs-dispatch"
```

**ps-dispatch:**
```lua
GiloHeli.DispatchSystem = "ps-dispatch"
```

**cd_dispatch:**
```lua
GiloHeli.DispatchSystem = "cd_dispatch"
```

**wasabi_dispatch:**
```lua
GiloHeli.DispatchSystem = "wasabi_dispatch"
```

**Custom/Generic:**
```lua
GiloHeli.DispatchSystem = "generic"
```

For generic, listen for this server event:
```lua
RegisterNetEvent('gilo:alprScan', function(data)
    -- data.plate = "ABC123"
    -- data.vehicle = "Sultan"
    -- data.coords = vector3(...)
end)
```

---

## Tactical Markers

Air units can place ground markers for coordination:

1. Enter HeliCam mode (`E`)
2. Press `Z` to select marker type (shown on screen)
3. Point camera at target location
4. Press `G` to place marker
5. All police units see:
   - Colored 3D beam at location
   - Blip on minimap with type label
6. Marker auto-removes after 60 seconds

### Marker Types

| Type | Color | Use Case |
|------|-------|----------|
| **SUSPECT** | Red | Mark suspect locations |
| **OFFICER DOWN** | Orange | Mark downed officer positions |
| **PERIMETER** | Yellow | Mark perimeter points |
| **GENERIC** | Blue | General purpose markers |

### Server Configuration

Edit `server.lua` to customize:
```lua
local MARKER_DURATION = 60000  -- milliseconds
local MARKER_JOBS = { 'police', 'sheriff', 'lspd', 'bcso', 'sasp', 'trooper', 'highway' }
```

---

## Framework Support

### QBCore / Qbox
- Notifications via `QBCore:Notify`
- Job checks for markers
- Full compatibility

### ESX
- Notifications via `esx:showNotification`
- Job checks for markers
- Full compatibility

### Standalone
- Native GTA notifications
- ACE permission support: `gilo.helicopter.marker`
- No framework required

---

## State Bag Spotlight

The spotlight now uses FiveM State Bags for perfect synchronization:

```lua
-- Server sets state
Entity(vehicle).state:set('spotlight', true, true)

-- All clients automatically receive
AddStateBagChangeHandler('spotlight', nil, function(bagName, key, value)
    -- Instant sync, no network events
end)
```

Benefits:
- No desync or lag
- Works with OneSync Infinity
- No TriggerClientEvent spam

---

## Camera Overlay Information

The enhanced overlay displays:

```
┌─────────────────────────────────────┐
│  [LSPD LOGO]                        │
│                                     │
│  ALT: 150.5    FOV: 45%   HDG: 270 │
│                                     │
│                                     │
│           [TARGET]                  │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ [LOCKED] / [TRACKING]       │   │
│  │ Vehicle: Sultan RS          │   │
│  │ Plate: ABC123               │   │
│  │ Speed: 85 KM/H (53 MPH)     │   │
│  │ ALPR Scan: 75%              │   │
│  └─────────────────────────────┘   │
│                                     │
│  LOC: Strawberry Ave | Strawberry   │
└─────────────────────────────────────┘
```

---

## Changelog

### v2.0.0 - Enhanced Edition

**Breaking Changes:**
- `SuperHoverKey` changed from `G` to `K` (G now places tactical markers)
- Command names prefixed with `Heli` (e.g., `HeliCam`, `HeliHover`)

**Performance:**
- State Bag spotlight sync (instant, no lag)
- Throttled raycasts to 200ms intervals
- Idle: 0.00ms | Active: ~0.02ms

**New Features:**
- ALPR Integration - Auto-scan plates after 3s lock-on
- Tactical Markers - Place ground markers for police coordination
- Street Name Display - Real-time location on overlay
- Live Speed Display - KM/H and MPH on locked vehicles

**Improvements:**
- Multi-framework support (ox_lib, QBCore, ESX, Native)
- Enhanced vehicle info panel
- Zoom sound effects
- Organized configuration

**Fixed:**
- Syntax error in camera unlock logic
- Duplicate keybind registrations
- Spotlight desync issues
- Super Hover abuse (now requires <10 km/h)

---

### v1.0.0 - Modernized
- Updated to FiveM Cerulean
- Fixed syntax errors
- Added Super Hover speed limiter
- Replaced ESX notifications with ox_lib

---

### Original Release
- Initial release by Gilo Modding
- HeliCam, vision modes, spotlight, hover systems

See [CHANGELOG.md](CHANGELOG.md) for full details.

---

## Credits

**Original Author:** GiloHeliPNC (TheInteger)

**Gilo Modding**
- Discord: https://discord.gg/tEaUMEUSVq
- Tebex: https://gilo-modding.tebex.io/

**Enhanced Edition:** Optimized for Tier-1 RP servers

---

## License

Free to use and modify. Credit to original author appreciated.
