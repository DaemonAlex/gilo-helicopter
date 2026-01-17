# Changelog

All notable changes to Gilo Helicopter will be documented in this file.

---

## [2.1.0] - Coordination Update

### New Features
- **Co-Pilot Spotlight Control** - Co-pilots (seat 0) can now control the spotlight
  - Pilot and co-pilot both have access by default
  - Optional `AllowPassengerSpotlight` for rear passenger control
- **Auto-Waypoint** - Automatically sets GPS waypoint when locking onto a vehicle
  - Plays waypoint sound for feedback
  - Can be disabled via `GiloHeli.AutoWaypoint = false`
- **Multiple Marker Types** - Four tactical marker types with distinct colors
  - `SUSPECT` (Red) - Mark suspect locations
  - `OFFICER DOWN` (Orange) - Mark downed officer positions
  - `PERIMETER` (Yellow) - Mark perimeter points
  - `GENERIC` (Blue) - General purpose markers
  - Press `Z` while in camera to cycle marker types
- **Toggleable UI Elements** - Cycle through UI display modes with `F7`
  - All elements visible
  - Speed hidden
  - Street hidden
  - Minimal mode (speed + street hidden)
- **wasabi_dispatch Support** - Added ALPR integration for wasabi_dispatch
  - Full blip and notification support
  - Joins existing: qs-dispatch, ps-dispatch, cd_dispatch, generic
- **wasabi_notify Support** - Notifications now support wasabi_notify

### New Keybinds
- `L` - Toggle Spotlight Follow Camera mode
- `F7` - Cycle UI display modes
- `Z` - Cycle marker types (while in camera)

### Configuration Additions
- `GiloHeli.AutoWaypoint` - Enable/disable auto-waypoint on lock
- `GiloHeli.AllowPassengerSpotlight` - Allow rear passengers to control spotlight
- `GiloHeli.SpotlightFollowKey` - Key for spotlight follow toggle
- `GiloHeli.ToggleUIKey` - Key for UI cycle
- `GiloHeli.MarkerTypeKey` - Key for marker type cycle

### Breaking Changes
- **Config namespace renamed** from `Kernel` to `GiloHeli` to avoid conflicts with other scripts

### Technical
- Added `GiloHeli.Debug` option - debug logs now disabled by default
- Version checker on server start with colored console output
- Server now logs marker type in placement messages (when Debug enabled)
- Improved framework detection with pcall error handling
- Added 'highway' to default police job list

---

## [2.0.0] - Enhanced Edition

### Breaking Changes
- `SuperHoverKey` changed from `G` to `K` (G now places tactical markers in camera)
- Command names prefixed with `Heli` (e.g., `HeliCam`, `HeliHover`, `HeliSeatbelt`)
- Config structure reorganized with new sections

### Performance
- **State Bag Sync** - Spotlight now syncs instantly via entity state bags (OneSync Infinity compatible)
- **Throttled Raycasts** - Vehicle detection runs every 200ms instead of every frame
- **Resource Usage:** Idle: 0.00ms | Active Camera: ~0.02ms | Locked On: ~0.01ms

### New Features
- **ALPR Integration** - Automatically scans license plates after 3-second lock-on
  - Visual progress indicator on screen
  - Sends plate data to dispatch systems
  - Supports: qs-dispatch, ps-dispatch, cd_dispatch, generic
- **Tactical Markers** - Place ground markers visible to all police units
  - Press `G` while in camera mode
  - Creates 3D red beam + map blip labeled "AIR-1 MARKER"
  - Auto-expires after 60 seconds
  - Synced to all players with police jobs
- **Street Name Overlay** - Real-time location display on camera
  - Shows current street name
  - Shows crossing street (if applicable)
  - Shows zone/neighborhood name
- **Live Speed Display** - Target vehicles now show speed
  - Displays both KM/H and MPH
  - Updates in real-time while tracking

### Improvements
- **Multi-Framework Support** - Notifications work with:
  - ox_lib (recommended)
  - QBCore (`QBCore:Notify`)
  - ESX (`esx:showNotification`)
  - Native GTA fallback
- **Enhanced Vehicle Info Panel** - Now displays:
  - Lock status: `[LOCKED]` or `[TRACKING]`
  - Vehicle model name
  - License plate (highlighted)
  - Live speed (KM/H + MPH)
  - ALPR scan progress
- **Zoom Sound Effects** - Audio feedback when zooming in/out
- **Organized Configuration** - Config.lua restructured with clear sections
- **Better Help Display** - Cleaner status indicators (ON/OFF instead of Active/Inactive)

### Fixed
- **Syntax Error** - Fixed `local old cam = cam` → `local old_cam = cam` (line 264)
- **Duplicate Keybinds** - Removed duplicate RegisterKeyMapping block
- **Spotlight Desync** - Replaced event-based sync with State Bags
- **Super Hover Abuse** - Now requires helicopter speed < 10 km/h to engage
- **ESX-Only Notifications** - Now framework agnostic with fallbacks

### Technical Changes
- Complete rewrite of `client.lua` (~800 lines)
- New `server.lua` with State Bags and marker system
- Restructured `config.lua` with all new options
- Updated `fxmanifest.lua` to Cerulean standard

---

## [1.0.0] - Modernized

### Changes
- Updated `fx_version` from `adamant` to `cerulean`
- Added Lua 5.4 support
- Fixed script load order (config before client)
- Added Super Hover speed limiter (10 km/h max)
- Replaced ESX notifications with ox_lib support
- Added native notification fallback
- Fixed syntax error in camera code
- Removed duplicate code blocks
- Added proper fxmanifest metadata

---

## [Original] - Gilo Modding Release

### Features
- HeliCam with LSPD scaleform overlay
- Night vision and thermal vision modes
- Vehicle lock-on with plate reader
- Spotlight with network sync
- Seatbelt system
- Rappel from rear seats
- Hover and Super Hover modes
- Italian and English translations

### Credits
- Original Author: GiloHeliPNC (TheInteger)
- Gilo Modding: https://discord.gg/tEaUMEUSVq
