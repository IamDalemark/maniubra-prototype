# Minimal architecture

Status: first playable Primary Controls course. Later courses, rule evaluators, NPC traffic, and randomized hazards remain design boundaries.

## Implemented files

```text
project.godot                 Main scene, desktop window, existing renderer/physics
scenes/app.tscn               Root Control scene
scripts/app.gd               Main menu → courses → lessons → briefing → back
scripts/course_catalog.gd    Four courses and twelve stable lesson records
scenes/lessons/primary_controls.tscn   First playable driving session
scripts/primary_controls.gd            Yard, guided steps, HUD, result events
scenes/vehicles/sedan.tscn             First-person manual sedan
scripts/sedan.gd                       Vehicle motion, cockpit, mirrors, audio
scenes/props/*.tscn                    Streetscape props and movable traffic cone
scripts/props/city_prop.gd             Original streetscape geometry and materials
scripts/props/traffic_cone.gd          Reusable physical training cone
scripts/driving_input.gd               Keyboard and preliminary gamepad actions
scripts/manual_transmission.gd         Clutch-gated manual gearbox
scripts/attempt_store.gd               Versioned local attempt history
tests/core_logic.gd                    Transmission and persistence checks
tests/primary_controls_flow.gd         Scripted complete-lesson check
tests/vehicle_stability.gd             Flat-road cornering and rollover check
tests/audio_playback.gd                Ignition/audio loop and volume-setting check
tests/training_lot.gd                  Enclosure and obstacle checks
export_presets.cfg                     macOS release export
assets/ASSET_REGISTER.md               Current original-asset provenance
assets/ui/course_art/                  Generated course selection illustrations
docs/screenshots/                  Real lesson-camera and map captures
PROTOTYPE_PLAN.md             Product scope and delivery plan
docs/AGENT_IMPLEMENTATION.md Ordered implementation handoff
AGENTS.md                    Repository rules
```

`app.gd` owns the menu controls and current navigation state. `course_catalog.gd` contains curriculum data only and returns copies of its data. Course IDs are `primary_controls`, `secondary_controls`, `maneuvers`, and `open_world`. The catalog holds one initial combined lesson for each controls course, nine maneuver lessons, and one open-world lesson.

Primary Controls has a real scene path and is selectable. The other briefings accurately show unavailable lessons. `app.gd` owns image-card selection, session creation/removal, a timestamped result timeline, saved results, and retry; `primary_controls.gd` owns its exercise and feedback. There is no numeric pass/fail score. UI controls are built in scripts to keep the prototype small; extract dedicated scenes only when presentation work makes that useful.

## Current ownership

```text
App
├── Menu / briefing / results UI
└── Session (one loaded lesson at a time)
    ├── Enclosed training lot (walls, slalom cones, parking bays, circular loop)
    ├── Sedan
    │   ├── DrivingInput → ManualTransmission → Vehicle motion
    │   └── Cockpit / Camera3D / mirrors / control visuals
    └── Lesson controller → attempt events → end-of-attempt result
```

The implementation uses direct node ownership and local signals. There is no autoload service, global event bus, entity framework, backend, or generalized dependency injection.

| Owner | Minimum responsibility | Must stay separate from |
|---|---|---|
| App | Navigation; instantiate/free one session; return to briefing or results. | Physics, legal rules, hazard logic. |
| Course catalog | Stable IDs, titles, objectives; later a scene path for implemented lessons. | UI nodes, mutable attempt state. |
| Driving input | Normalize keyboard/gamepad/wheel input into actions. | Vehicle-specific physics and assessment. |
| Sedan + transmission | Move the vehicle; maintain clutch/gear state; expose observable driving state. | Course progression and score calculations. |
| Lesson controller | Starting state, steps, observable completion/errors, reset, and result. | Menu presentation and raw device mappings. |
| Attempt store | Save/load the five recent versioned attempt records. | Running simulation nodes and graphics. |

Input and transmission are small scripts owned by the vehicle, with focused checks that do not require a rendered world. Keep sedan and SUV parameters in a resource only when the second configuration is needed.

## Small integration contracts

**Catalog:** preserve the existing `get_courses()`, `get_course(id)`, and `get_lesson(course_id, lesson_id)` interface. `scene_path` is set only for the implemented Primary Controls lesson. The app validates that path before enabling Start. User-visible titles may change without changing IDs.

**Session lifecycle:** App loads the selected scene, calls `start_attempt(context)`, and connects `attempt_finished(result)` and `exit_requested`. Context starts with `course_id`, `lesson_id`, `vehicle_id`, and `input_profile_id`. Add scenario and assessment versions when saving begins. Restart resets all owned nodes or reconstructs the session; it never reuses the previous event list. App frees the session and releases captured mouse input before showing menus.

**Driving input:** expose steering in `[-1, 1]`, throttle/brake/clutch in `[0, 1]`, handbrake state, and gear-selection requests. Define clutch `1` as pedal fully depressed/disengaged and `0` as released/engaged. Digital controls may ramp their values; physical analog axes must be calibrated. The same semantic inputs drive every supported device.

**Vehicle state:** expose speed in meters/second internally, selected gear (`-1` reverse, `0` neutral, positive forward gears), clutch engagement, transform, and relevant control states. Convert to km/h for display with `m/s × 3.6`. Gear count and ratios are tuning choices, not new product scope.

**Attempt event:** current events contain `type`, `elapsed_seconds`, and observed detail such as a completed step or rejected shift. The attempt clock stops while paused. Add criterion IDs when later criteria are implemented. Do not label raw input as successful maneuver execution.

**Result:** course/lesson IDs, completion state, observed events, and plain-language feedback. Primary Controls records scenario and assessment version 2, elapsed time, rejected shifts, and engine stall count. Add score deductions only after their criteria are defined and verified.

## Later additions, when their course needs them

- Rule evaluators read lane/sign/signal data and vehicle events. Rendered signs and rules share configuration.
- A lane-path traffic controller and small pedestrian state machines supply repeatable NPC behaviors.
- Open World adds an event director that selects eligible authored hazards with seed/version, spacing, cooldowns, and visibility constraints. Record actual encounters because player behavior changes outcomes.
- Local persistence uses `user://` and versioned data; no cloud dependency. Match lesson, vehicle, relevant settings, input assistance, assessment version, and compatible hazard exposure before comparing attempts.

## Asset ownership

Create folders as files are added. Current audio lives in `assets/audio/`, course-card concept illustrations in `assets/ui/course_art/`, and all first-course 3D geometry is generated by scripts. The reusable shopfront, stall, palm, streetlamp, jeepney, and tricycle scenes in `scenes/props/` are visual only; traffic cones are physical obstacles. Keep external license files with future sourced assets and maintain `assets/ASSET_REGISTER.md`. Store editable custom sources separately from optimized Godot imports when needed.

The cockpit must support the driver's actual eye position, clear windshield sight lines, instrument visibility, moving controls, and useful mirrors. The current camera follows the driver seat each rendered frame while filtering body roll and pitch; the procedural hands follow steering and a timed shift reach. The raised wheel mounts keep the chassis and center of gravity lower, while wheel roll influence permits rollover only under a severe full-lock turn in the flat-road test. The circular loop is traversable layout in the enclosed Primary Controls lot, with no rule evaluation yet. External car models are not automatically suitable player vehicles. Profile this view on the Mac before buying or building a large environment.

## First playable milestone status

- Godot loads the configured main scene without script/scene errors.
- The four course groups and all nine maneuver entries are reachable.
- Primary Controls enters a first-person sedan session with a complete eight-step control sequence and feedback; other briefings show unavailable gameplay.
- Escape pauses the exported course, and the session can restart or return to courses.
- Scripted Godot checks cover transmission, attempt storage, and the full lesson flow. The macOS export launches and its first-person view was visually checked.
- Physical controller testing, exported-app save/relaunch, and a manually driven end-to-end export check remain outstanding. Secondary Controls is the next course.
