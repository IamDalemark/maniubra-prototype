# Maniubra: Learn the Road

Single-player, first-person manual-driving practice for macOS, built with Godot 4.7.

## Current state

The first playable course is **Courses → Primary Controls → Manual driving basics → Start lesson**. It is a seven-step first-person exercise covering clutch and first gear, acceleration, second gear, steering, braking, handbrake, and reversing. The result screen now shows a timestamped "What happened" timeline for completed steps and rejected shifts. The app retains the five most recent attempts locally. Other course entries and individual maneuvers remain visible but unavailable until implemented. Results are practice feedback, not a licensing assessment.

Open `build/ManiubraPrototype.app` on this Mac, or open `project.godot` in Godot and run the main scene. The sedan and street use original stylized Godot 3D assets and synthetic engine/road audio; see `assets/ASSET_REGISTER.md`. The left-hand-drive cockpit has a roof/headliner, instruments, rear and side mirror views, a moving steering wheel and hands, and adjustable field of view. Its right hand briefly reaches toward the gear lever on a successful shift. Stronger propulsion, a responsive RPM gauge and readout, speed-sensitive steering, tighter suspension, and a level cockpit camera make the sedan easier to drive. The camera now follows the driver seat after each physics step, eliminating the speed-dependent camera lag that made the interior appear to shake while moving forward. The street now has a connected crossroad and a drivable roundabout with a raised island; see the [gameplay view](docs/screenshots/primary_controls_city.png) and [map view](docs/screenshots/roundabout_map.png). The scenery includes reusable Philippine-inspired shopfronts, produce stalls, palms, lamps, a jeepney, and a tricycle. The latter two are static scenery, not driving NPCs. Course and maneuver selection uses illustrated concept-art cards; only Primary Controls is playable.

The sedan's suspension mounts now sit 0.5 m higher relative to the chassis, lowering its ride height and center of gravity while retaining wheel size. Moderate full-steering turns stay planted; a high-speed full-lock turn can still tip it. This is a simplified game handling tune, not a calibrated vehicle dynamics model.

| Action | Keyboard and mouse |
|---|---|
| Steer | A / D |
| Accelerate / brake | W / S |
| Depress clutch | Hold C |
| Shift up / down | E / Q |
| Handbrake | Space |
| Look around | Mouse |
| Pause / resume | Escape |
| Restart lesson | R |

The clutch must be depressed to shift. The simplified gearbox has reverse, neutral, and forward gears; its RPM display is an approximation, and engine stall and ignition are not modeled. The crossroad and roundabout are explorable geometry within Primary Controls, not yet separate assessed maneuver lessons or rule enforcement. Basic standard-gamepad mappings exist, but DualShock 4, Xbox, and steering-wheel devices have not been physically tested or calibrated. Keyboard and mouse are the verified input profile.

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

- Focused Godot checks passed for transmission, bounded and recoverable attempt storage, the camera staying at the driver seat, and the complete seven-step first-person lesson through saved result navigation. A straight-line frame probe measured zero camera-seat offset at 4–20 m/s; before the fix, the offset grew to 1.6 m. Run the checks with `MANIUBRA_DATA_DIR=/tmp/maniubra-core-check` and `/tmp/maniubra-flow-check` respectively using `tests/core_logic.gd` and `tests/primary_controls_flow.gd` as `--script` arguments.
- `tests/vehicle_stability.gd` passed on a flat Jolt test surface: a full-lock turn starting near 30 km/h stayed below 5° lean with all wheels contacting, while a full-lock turn starting near 54 km/h tipped. The lowered cockpit was visually checked in the exported app; a manually driven exported-app cornering run is still pending.
- The release export rebuilt and launched on macOS 26.3.1 (Apple M4 Pro). Its course selection, briefing, straight-ahead first-person view, animated hands, and RPM readout were visually checked in the exported app. Full-resolution lesson and roundabout-map captures were saved. The complete driven run was verified by the scripted Godot check; the roundabout has not yet had a manual exported-app driving playthrough.
- Persistence was verified with a temporary save override; normal exported-app save/relaunch remains unverified. No physical controller or wheel has been tested. Restricted command-line Godot prints a macOS system-certificate access error and may fail to save global editor settings, despite successful project checks and export.
