# Maniubra: Learn the Road

Single-player, first-person manual-driving practice for macOS, built with Godot 4.7.

## Current state

**Courses → Primary Controls → Manual driving basics** is an eight-step first-person exercise covering ignition, clutch and first gear, acceleration, second gear, steering, braking, handbrake, and reversing. Releasing the clutch in gear at very low speed without enough throttle, or braking to a stop without the clutch, stalls the engine; H restarts it in neutral or with the clutch depressed. Results include a timestamped "What happened" timeline. **Courses → Open World → Explore Iloilo** now starts a connected two-lane district with an optional Molo Plaza venue name. Stop fully in the painted bay for two seconds to earn a badge/toast, or explore without going there; end and review the drive from pause. The app retains the five most recent attempts locally. Secondary Controls and individual maneuvers remain unavailable. Results are practice feedback, not a licensing assessment.

Open `build/ManiubraPrototype.app` on this Mac, or open `project.godot` in Godot and run the main scene. The sedan and enclosed practice lot use original stylized Godot 3D assets and synthetic engine/road audio; see `assets/ASSET_REGISTER.md`. The left-hand-drive cockpit has a roof/headliner, instruments, rear and side mirror views, a moving steering wheel and hands, and adjustable field of view. Its right hand briefly reaches toward the gear lever on a successful shift. Stronger propulsion, a responsive RPM gauge and readout, speed-sensitive steering, tighter suspension, and a level cockpit camera make the sedan easier to drive. The camera now follows the driver seat after each physics step, eliminating the speed-dependent camera lag that made the interior appear to shake while moving forward. The 160 × 240 m enclosed driving-school lot has a long starting lane, painted parking bays, a cone slalom, 17 movable traffic cones, and a drivable circular practice loop; see the [cockpit capture](docs/screenshots/primary_controls_lot.png) and [lot map](docs/screenshots/training_lot_map.png). The new [Open World blockout](docs/screenshots/open_world_start.png) has a connected street grid, roundabout, bridge crossings, venue bay, and original stylized Calle Real, Molo and riverside landmark shapes. Six scripted cars/jeepneys/tricycles drive the outer streets, five pedestrians walk on sidewalks, and two pedestrians can cross when the player approaches at a response distance. Three collidable stalls partly enter the road. Traffic behavior and landmark art still need a full tuning pass. Course and maneuver selection uses illustrated concept-art cards.

The Open World visual pass includes a [Molo approach](docs/screenshots/open_world_molo.png) with a twin-spire church silhouette, a [roadside Molo Plaza sign](docs/screenshots/open_world_venue_sign.png) at the painted stopping bay, and a [Calle Real-inspired block](docs/screenshots/open_world_calle_real.png) with continuous heritage storefronts. The departure view now has a neighborhood market street rather than empty verges. The Iloilo River Esplanade area has water, a pedestrian frontage and bridge crossings. These are original stylized interpretations; fine architectural detail and the typical A–B travel time still need a manual driving pass.

Open World now shows [corrective side toasts](docs/screenshots/open_world_incident_toast.png) and records review events for a pedestrian hit, a traffic-vehicle collision, hitting a roadside stall, or crossing the [marked market stop line](docs/screenshots/open_world_stop_approach.png) without stopping. Rejected shifts, blocked ignition and engine stalls also show the same feedback there. The [pedestrian model](docs/screenshots/open_world_pedestrian_upright.png) has separate swinging arms and legs; a vehicle contact makes it [fall](docs/screenshots/open_world_pedestrian_fallen.png). This is a simple animated reaction, not a ragdoll or injury simulation. The smaller, lower gauges reveal more near road in the [current Open World cockpit view](docs/screenshots/open_world_start.png); the speed/RPM HUD remains available.

The [selected gear is now printed on the gear-shift knob](docs/screenshots/gear_knob_second.png), so its N/R/number moves with the lever. The sedan's suspension mounts sit 0.5 m higher relative to the chassis, lowering its ride height and center of gravity while retaining wheel size. Moderate full-steering turns stay planted; a high-speed full-lock turn can still tip it. This is a simplified game handling tune, not a calibrated vehicle dynamics model.

The engine and road WAVs have complete loop ranges. The engine loop starts with H and stops on ignition off or stall; the road loop continues during a lesson. The audio volume setting mutes and restores both sounds; engine pitch follows RPM and road sound grows with speed.

When a shift is rejected, the engine stalls, or an ignition attempt is blocked, a short-lived toast appears at the upper right with the corrective action. The event remains in the attempt's "What happened" review. See the [toast in the cockpit](docs/screenshots/error_toast.png).

The upper-left driver check reminds you whether the seatbelt is fastened and the handbrake is applied. Press **B** to toggle the seatbelt while driving. Its button is also clickable while paused, when the cursor is already visible. Either action moves the right arm across the chest toward the driver's left shoulder; see the [seatbelt reach](docs/screenshots/seatbelt_reach.png). Holding **Space** applies the handbrake and raises the lever beside the steering wheel; the right hand briefly reaches for it on application and release. See the [released](docs/screenshots/driver_check_released.png) and [applied](docs/screenshots/driver_check_applied.png) views. The seatbelt is a practice control and indicator; it does not yet change crash physics or the lesson result.

| Action | Keyboard and mouse |
|---|---|
| Start / stop engine | H |
| Fasten / unfasten seatbelt | B, or click the upper-left button while paused |
| Steer | A / D |
| Accelerate / brake | W / S |
| Depress clutch | Hold C |
| Shift up / down | E / Q |
| Handbrake | Hold Space |
| Look around | Mouse |
| Pause / resume | Escape |
| Restart lesson | R |

The clutch must be depressed to shift. The simplified gearbox has reverse, neutral, and forward gears; its RPM display and stall threshold are teaching approximations. The circular loop is explorable geometry within Primary Controls, not yet a separate assessed maneuver lesson or rule enforcement. [Settings](docs/screenshots/settings_xbox.png) now shows a standard Xbox controller layout, connection status, and [editable keyboard bindings](docs/screenshots/settings_keybinds.png). Select an action, press a replacement key, or restore defaults. Bindings save locally and update lesson prompts and HUD hints. Gamepad sticks and triggers use the fixed Xbox layout shown in Settings. Godot currently detected no connected controller on this Mac, so the Xbox mappings are software-checked but physical handling remains unverified; steering-wheel and DualShock 4 hardware remain untested. Keyboard and mouse are the verified input profile.

Xbox preset: left stick steer, right trigger accelerate, left trigger brake, LB clutch, RB shift up, D-pad down shift down, A handbrake, Y engine on/off, X seatbelt, D-pad up restart, Menu pause, and right stick look. In menus, A selects and B goes back.

On the current Mac:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/daniel/maniubra-prototype
```

## Project documents

- [Prototype plan](PROTOTYPE_PLAN.md): product scope, course sequence, assets, and delivery milestones.
- [Architecture](docs/ARCHITECTURE.md): current ownership and future boundaries.
- [Agent implementation steps](docs/AGENT_IMPLEMENTATION.md): ordered work packages, checks, and handoff instructions.
- [Agent rules](AGENTS.md): repository-wide constraints for implementation.

The next course milestone is Secondary Controls. First finish an exported-app save/relaunch check and test available controller hardware. Keep later lessons unavailable until their complete briefing → driving → feedback loops work.

## Verification — 6 October 2026

- Focused Godot checks passed for transmission, bounded and recoverable attempt storage, the camera staying at the driver seat, and the complete eight-step first-person lesson through saved result navigation. A straight-line frame probe measured zero camera-seat offset at 4–20 m/s; before the fix, the offset grew to 1.6 m. Run the checks with `MANIUBRA_DATA_DIR=/tmp/maniubra-core-check` and `/tmp/maniubra-flow-check` respectively using `tests/core_logic.gd` and `tests/primary_controls_flow.gd` as `--script` arguments.
- `tests/vehicle_stability.gd` passed on a flat Jolt test surface: a full-lock turn starting near 30 km/h stayed below 5° lean with all wheels contacting, while a full-lock turn starting near 54 km/h tipped. The lowered cockpit was visually checked in the exported app; a manually driven exported-app cornering run is still pending.
- `tests/audio_playback.gd` passed: both two-second WAV loops were still playing after 3.2 seconds, and the volume setting muted and restored both players. A graphical macOS audio probe measured a live signal on the Master bus after the loop fix; an audible check by the user on their chosen output device remains useful.
- `tests/training_lot.gd` passed: four collidable boundary walls surround the lot, the sedan starts in the clear launch lane, and 17 collidable cones populate the practice area. A native Metal-rendered cockpit and overhead map were inspected and saved in `docs/screenshots/`.
- The full-lesson flow check verifies the right-side toast for rejected shifts, stalls, and blocked starts, its timed dismissal, and its removal after a successful restart. The toast was also visually checked in a native Metal render.
- The same flow check verifies B-key and button seatbelt toggles, their short arm reach, the upper-left handbrake reminder, and the handbrake reach and lever positions. Both cockpit states were visually inspected in native Metal renders.
- The earlier release export rebuilt and launched on macOS 26.3.1 (Apple M4 Pro). Its course selection, briefing, straight-ahead first-person view, animated hands, and RPM readout were visually checked in the exported app. Full-resolution lesson and roundabout-map captures were saved. The complete driven run was verified by the scripted Godot check; the roundabout has not yet had a manual exported-app driving playthrough.
- Persistence was verified with a temporary save override; normal exported-app save/relaunch remains unverified. No physical controller or wheel has been tested. Restricted command-line Godot prints a macOS system-certificate access error and may fail to save global editor settings, despite successful project checks and export.
- `tests/open_world_flow.gd` passed the optional destination/review flow plus collision-toast deduplication and stopping versus rolling through the authored stop line. `tests/open_world_collision.gd` passed actual Jolt contact checks: the sedan hit a pedestrian and a traffic vehicle, yielding one incident each and a visible pedestrian fall. The Primary Controls flow still passes after the shared cockpit adjustment. Native Metal renders were inspected for road visibility, the stop approach, and upright/fallen pedestrian poses. These checks do not replace a manually driven macOS playthrough.
- `tests/input_bindings.gd` verifies the Xbox action preset, keyboard remap UI, duplicate rejection, local save/reload, reset, and that controller mappings survive keyboard changes. The settings screen was checked in a native Metal render. The Xbox controller itself was not available for a physical playthrough.
