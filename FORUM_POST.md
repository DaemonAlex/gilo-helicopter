## Gilo Helicopter - Enhanced Edition v2.1.0

**What is this?**
A modernized and enhanced version of the original Gilo Helicopter police camera script with new features for serious RP servers.

---

### What's Different?

| Original | Enhanced Edition |
|----------|------------------|
| ESX-only notifications | Multi-framework (ox_lib, QBCore, ESX, wasabi_notify, native) |
| Event-based spotlight sync (laggy) | State Bag sync (instant, no desync) |
| Basic plate display | Full ALPR with dispatch integration |
| No ground coordination | Tactical markers visible to all police |
| Raycast every frame | Throttled to 200ms (better performance) |
| Pilot-only spotlight | Pilot + Co-pilot control |
| Single marker type | 4 marker types (Suspect, Officer Down, Perimeter, Generic) |

---

### New Features

- **ALPR Integration** - Auto-scans plates after 3s lock, sends to dispatch (qs-dispatch, ps-dispatch, cd_dispatch, wasabi_dispatch, or custom)
- **Tactical Markers** - Place colored ground markers visible to all police units with map blips
- **Auto-Waypoint** - GPS waypoint automatically set when locking onto a vehicle
- **Live Speed Display** - Shows target vehicle speed in KM/H and MPH
- **Street Name Overlay** - Real-time location displayed on camera
- **Toggleable UI** - Cycle through display modes (F7)
- **Super Hover Speed Limiter** - Prevents abuse (requires <10 km/h)

---

### Performance

| State | Usage |
|-------|-------|
| Idle | 0.00ms |
| Camera Active | ~0.02ms |

---

### Requirements
- FiveM Server (OneSync recommended)
- ox_lib (optional, for notifications)

---

### Download
[GitHub](https://github.com/DaemonAlex/gilo-helicopter)

---

### Credits
Original script by KernelPNC / Gilo Modding. Enhanced Edition adds modern features for Tier-1 RP servers.
