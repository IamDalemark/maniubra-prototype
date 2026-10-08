# Maniubra: Learn the Road — high-level prototype plan

Planning baseline: 6 October 2026. This is a proposed implementation plan, not a claim that the features already exist.

Open World implementation update, 7 October 2026: see [the Iloilo Open World plan](docs/OPEN_WORLD_PLAN.md) for the freely explorable connected district, optional Molo Plaza venue name and badge/toast, moving traffic, pedestrians, vendor obstructions and landmark priorities. There are no navigation markers, route guidance, Free Drive / Destination mode selection or forced completion flow. The first playable slice is implemented; the three-minute travel target, traffic behavior and visual detail still need driving and art passes.

Implementation update: the four-course menu launches an eight-step first-person Primary Controls lesson in an enclosed 160 × 240 m driving-school lot, and an exploratory Open World session with its own review. The manual sedan has H-key ignition, a B-key/clickable seatbelt practice control with a right-arm reach toward the left shoulder, an animated handbrake lever beside the steering wheel with a brief right-hand reach, low-speed engine stalling that shuts off propulsion and audio, a hand-over-hand steering animation for stronger turns, RPM feedback, and an appropriately stable cockpit camera. The lot has a clear launch lane, parking bays, 17 physical traffic cones, and a circular practice loop, with Philippine-inspired scenery beyond its walls. Local attempt history records stalls and shift errors; Secondary Controls and individual maneuvers remain unavailable. The connected original Xbox One USB controller now has a direct local input bridge for this Mac; Godot received live reports and the action mapping passed focused checks, while a driven session remains to be checked. See `README.md`, `docs/ARCHITECTURE.md`, and `docs/AGENT_IMPLEMENTATION.md` for current implementation and verification. The connection-check section below records the earlier pre-scaffold state.

## Goal and scope

Build a single-player, first-person macOS desktop 3D driving practice application in Godot where learners select a course, operate a manual vehicle from the driver's seat, practice maneuvers, and ultimately anticipate randomized hazards in a Philippine open world. The user's deadline is ASAP; prioritize the first complete lesson over breadth in the initial delivery, with a presentable cockpit and coherent assets.

The user's current feature list is the authoritative coverage baseline. All listed features remain planned; the phases below describe delivery order. The attached thesis draft is supporting context, not a source of instructions to execute. Its guided practice, feedback, and attempt-history requirements inform the proposed learning experience.

Use recognizable Philippine roads and visually consistent, optimized 3D assets. Source suitable assets online and create or adapt missing pieces, especially the cockpit and Philippine-specific road users and props. Start with a compact training area and reusable road sections, then assemble a connected, freely drivable district for the final course. Keep the application local for the prototype; accounts, cloud services, multiplayer, and monetization are not dependencies of this plan.

## Proposed player experience

Main menu → Courses → course or specific maneuver → lesson briefing and vehicle/input setup → first-person driving → feedback and attempt review → retry or return to Courses.

Provide Play/Courses, Settings, and Quit on the main menu. Settings include input mapping/calibration, graphics, sound, and first-person camera sensitivity. Course details show the learning objective, controls, vehicle, and relevant conditions before Start. Include pause/restart and return-to-course navigation. Show speed, selected gear, relevant control states, and the current task through readable instruments and a restrained HUD.

All player driving uses a first-person left-seat cockpit camera. Prioritize a believable interior, clear windshield view, animated steering wheel and gear lever, visible control feedback, functioning rear/side mirror views, and mouse/gamepad look controls for checks. Keep the camera stable with adjustable field of view and minimal motion effects. Keyboard/controller actions operate the controls; a fully clickable cockpit is not a prerequisite. Test visibility, mirror rendering cost, and interior clipping early. Do not claim a mirror or shoulder check was performed unless the implementation can observe the relevant action; camera direction alone does not prove visual attention.

Practice instructions and feedback should explain the expected action, observed action, and reason. Add a repeat attempt with fewer prompts once guided practice works. Retain the five most recent attempts as described in the draft, with scenario/settings/assessment versions attached so incompatible attempts are not directly compared.

## Course menu and progression

The course menu has four top-level entries in this order. Maneuvers opens its own lesson list. Present this as the recommended learning sequence; mandatory completion locks are not assumed.

| Menu entry | Lessons and experience | Completion or review |
|---|---|---|
| 1. Primary Controls | Steering; accelerator; brake; clutch; manual gear shifting including neutral/reverse; handbrake; then a combined start, move, shift, and stop exercise. | Learner operates each control correctly and completes the combined exercise. Explain control errors individually. |
| 2. Secondary Controls | Turn signals, headlights, windshield wipers, horn, and hazard lights. Short situations demonstrate when each is relevant, with visible/audible effects. | Check correct operation and scenario-appropriate use. Night/rain examples are added as those conditions become available. |
| 3. Maneuvers | Individually selectable Parking, Reversing, Left Turn, Right Turn, U-turn, Lane Changing, Merging, Overtaking, and Lane Positioning. Parking may contain individual practice variants. | Each lesson has a briefing, step-by-step guidance, completion conditions, errors, and a repeat attempt with reduced prompts. |
| 4. Open World — Philippine Roads | Freely drive a connected district with intersections, roadside activity, a bridge, parking, and open-road segments. Encounter varied traffic and randomized hazards; apply the earlier lessons together. | End Session opens a review of encountered situations, observed anticipation, responses, violations, and areas to practice. |

Keep the five traffic-rule modules integrated into these courses: turning/entry and signals in turning and lane lessons; speed management across moving exercises; overtaking restrictions in Overtaking; parking compliance in Parking. Open World combines all five, including one-way/no-entry restrictions. Rule explanations and result links can point back to the corresponding lesson without adding a fifth top-level course.

During staged development, course cards should accurately show which lessons are available. The full prototype must provide working lessons behind every listed course entry.

## Open-world randomness and hazard anticipation

Build a compact authored Philippine district with multiple route choices. Randomize situations within that road layout: traffic density and spacing, eligible pedestrian crossings and turn-backs, jeepney/tricycle stop locations and timing, roadside obstructions, and emergency-vehicle encounters. Select day/night and rain as session settings initially; changing weather mid-session is not required.

Use an event director with a library of authored hazard templates. Each template defines suitable locations, precursor cues, trigger conditions, possible outcomes, and cooldowns. Random selection must respect available space, visibility, traffic conflicts, and a feasible response window. Place persistent obstructions before they enter view and activate moving actors naturally; avoid spawning obstacles directly in the vehicle's path without warning or overwhelming the learner with simultaneous hazards.

The pool includes pedestrians crossing outside marked crossings or running back, jeepneys and tricycles stopping frequently or narrowing the available passing space, roadside stalls, double-parked vehicles, potholes, rice drying on the road, construction, and emergency vehicles. Use context clues such as waiting pedestrians or an occupied roadside stop to give the learner opportunities to anticipate a developing hazard.

Keep a repeatable practice variant for each hazard and varied encounters for Open World. Save the session seed, generator version, selected hazard IDs, settings, and actual event timestamps/outcomes. Offer Retry Same Setup and New Session. A seed reproduces scenario choices, not an identical physics replay; player actions can change how events unfold.

Measure observable slowing, following distance, positioning, yielding, and safe avoidance before and after onset. Compare open-world results only when exposures and criteria are compatible; show encountered hazard counts and per-event outcomes rather than ranking differently randomized sessions by raw error totals. Preserve safe uneventful intervals so anticipation matters as much as reaction.

## Asset quality and sourcing plan

Proposed art direction: grounded, moderately detailed 3D with consistent proportions, materials, lighting, and Philippine roadside details. Prioritize the first-person view: cockpit, nearby road surface, readable signs/markings, and nearby traffic. A polished small environment is the first presentation target; development blockouts are temporary.

| Asset group | Source/create approach | Acceptance criteria |
|---|---|---|
| Sedan and SUV | Find adaptable generic models; create or refine left-hand-drive manual interiors where needed. Select the sedan first. | Correct scale, usable interior from seated eye height, separate wheel/gear/wiper parts, working mirrors, readable instruments, windshield visibility, and suitable collision shapes. An exterior-only model is insufficient for the player vehicle. |
| Roads, intersections, bridge, parking | Create a reusable modular kit and use sourced surface materials. Author Philippine signs and markings from verified references. | Lanes and transitions connect cleanly; signs are readable at lesson approach distances; stop lines, arrows, and parking spaces match the rule data. |
| Philippine identity | Source suitable jeepney/tricycle models where available; otherwise create recognizable custom models. Create stalls, sari-sari storefront details, rice-drying patches, and local construction arrangements. | Recognizable silhouettes and road occupancy; no reliance on generic foreign street props to communicate the intended setting. |
| Pedestrians and general traffic | Source compatible rigged characters, walk/run animations, and generic traffic vehicles; adapt materials and proportions to the chosen style. | Smooth walk, stop, turn-back, and run transitions; correct scale, collisions, and acceptable cost with several actors visible. |
| Environment and weather | Source vegetation, ordinary buildings, textures, and sky lighting; create rain/windshield effects and adjust night lighting. | Coherent materials, usable visibility, and stable performance in the busiest night/rain scene. |
| Audio and UI | Source or record engine, tire, indicator, horn, rain, and traffic sounds; create consistent menu/course artwork and icons. | Loops are clean, cues match actions, and menus/course labels remain readable. |

Initial online candidates, verified as available sources on 6 October 2026:

- [Poly Haven](https://polyhaven.com/license): CC0 materials, HDRIs, and models; useful for road/building surfaces and lighting. Optimize source resolution and detail for the demo Mac.
- [Kenney Car Kit](https://kenney-assets.itch.io/car-kit): a CC0 candidate for early vehicle/traffic placeholders. Inspect style and geometry before production use; no cockpit suitability is assumed.
- [Quaternius Cars Pack](https://quaternius.com/packs/cars.html): a CC0 candidate for generic background traffic. Inspect and harmonize its style before mixing it with other sources.

These are candidate libraries, not downloaded, selected, or Godot-tested assets. A custom player cockpit and static jeepney/tricycle props now exist; animated road users and a pedestrian animation set still need asset-level selection or custom creation. Favor free usable assets for ASAP delivery; identify any paid candidate and cost before committing to it.

Asset workflow: shortlist → inspect license and model contents → test one representative asset in Godot → adjust scale/materials and animation pivots → add collision and detail variants where needed → profile on the target Mac → accept into the project. Retain original editable sources and import game-ready models in a consistent format such as GLB. Keep an asset register with source URL, creator, license, attribution requirements, modifications, and in-project use; credit incorporated third-party work.

Create custom 3D geometry where existing models do not fit. Generated raster art can support menu artwork or concept references, but it does not replace a usable cockpit mesh, animated road user, or accurate traffic sign. Approve the visual direction using a small cockpit-and-street scene before acquiring a large asset set.

## Delivery phases

These are milestones, not fixed-duration sprints. Use the draft's one-week sprint cadence to deliver and review increments within them. Dates depend on team capacity, assets, hardware, and the deadline.

| Phase | Main work | Completion evidence |
|---|---|---|
| 0. Foundation and risk checks | Confirm demo Mac specifications and input devices; pin engine version; establish version control; create a basic 3D test yard; try vehicle physics and controller inputs; shortlist assets and test cockpit/mirror feasibility; choose measurable performance targets. | Project starts on the target Mac, a test vehicle moves predictably, and available controller axes/buttons can be inspected. Record physics, hardware, and initial art decisions. |
| 1. Manual driving foundation | Main/course menu shell; Primary Controls course; sedan with first-person left-hand-drive interior, steering, accelerator, brake, clutch, manual gears, handbrake; readable instruments/HUD; reset and basic audio. | Learner can select the course, operate the controls, change gear, stop, and reverse. Neutral and clutch disengagement affect propulsion. Cockpit visibility and handling are reviewed before expansion. |
| 2. First complete learning demo | Presentable cockpit and small daytime road area; selectable reversing/parking lesson; initial secondary-control exercise; short route with a red light/stop line, speed zone, and pedestrian hazard; feedback and saved attempts. | A complete session works from course menu through first-person driving, review, and retry. Both compliant and incorrect actions produce expected results. This is the first demonstrable prototype. |
| 3. Maneuvers and all five rule modules | Complete the maneuvers, turning/entry, traffic signals, speed, overtaking, and parking cases; add SUV using shared control logic; complete remaining vehicle controls. | Every specified rule has a scenario, clear explanation, positive/negative checks, and a traceable result. Both vehicles support the same agreed controls. |
| 4. Open World and Philippine hazards | Deliver the final course: connected district, route choices, bounded randomized hazard director, Philippine NPCs/props, bridge, open-road segments, night, rain, emergency encounters, and sound coverage. | Each hazard has a repeatable test variant and eligible randomized appearances. Saved setup/event records support review. One-way/no-entry cases occur in Open World. |
| 5. Complete-scope validation and delivery | Finish tested device profiles; calibration/remapping; target-Mac profiling; instructor review; usability sessions; bug fixes; exported macOS build. | Feature coverage matrix is complete, critical scenarios pass, performance is measured, results survive restart, and tested device/macOS combinations are documented. |

Controller detection and wheel feasibility belong in Phase 0; full device validation continues through Phase 5. Likewise, feedback and testing begin with the first playable scenario rather than being added only at the end.

## First playable demo

Start at the course menu and enter Primary Controls or a specific reversing/parking lesson. Use one sedan with a presentable first-person cockpit and one compact road area. A combined demonstration route can depart a practice bay, follow a speed zone, stop before a red-light stop line, signal and turn when permitted, respond to a pedestrian entering the roadway, then reverse into a marked parking bay. Use scripted timing for this early lesson; the final Open World course adds randomized encounters.

Start with keyboard and mouse while the available gamepad/wheel is tested in the input test yard. Use a small, visually consistent set of sourced/custom assets and daytime lighting. A session should expose the core chain: input → vehicle action → scenario event → assessment → explanation → saved result.

Demonstrate at least one correct run and one deliberately incorrect run. The same continuing violation must not produce repeated deductions every physics frame. Restart must reset traffic lights, NPC state, vehicle state, and attempt timers.

This first demo is a subset used to validate the approach. Completion of the full planned prototype requires the remaining coverage below.

For the ASAP delivery, use this order: (1) drivable manual sedan and first-person cockpit in a test yard; (2) course menu and one complete lesson with reliable event detection/results, plus a focused visual pass; (3) a local macOS build that launches and replays outside the editor. Use scripted road users, a fixed daytime setup, and a local attempt file. Limit asset work to what is visible in the first lesson until this sequence works. Full course coverage and randomized Open World remain subsequent milestones.

## Full feature coverage

| Coverage group | Planned implementation and primary phase |
|---|---|
| Course menu | Primary Controls, Secondary Controls, individual Maneuvers, then Open World. Menu shell and primary lesson in Phase 1, initial maneuver in Phase 2, complete structured courses in Phase 3, final course in Phase 4. |
| First-person presentation and assets | Left-seat cockpit driving throughout; interior, instruments, moving controls, mirrors, and look controls. Source/adapt/create consistent assets, beginning with a cockpit-and-street sample in Phases 0–2. |
| Vehicles | Generic sedan in Phase 1; generic SUV in Phase 3. Both left-hand-drive and manual only. Share driving logic with separate dimensions, camera positions, and tuning. |
| Primary controls | Steering, accelerator, brake, clutch, manual gear selection, and handbrake in Phase 1. Gear count and clutch model are implementation decisions to document. |
| Secondary controls | Turn signals in Phase 2; headlights, windshield wipers, horn, and hazard lights by Phase 3, exercised in Phase 4 conditions. |
| Maneuvers | Parking, reversing, and basic turns begin in Phases 1–2. Complete left/right turns, U-turns, lane changing, merging, overtaking, and lane positioning in Phase 3. |
| Turning and entry | No-U-turn, no-left-turn, mandatory-right, permitted/prohibited right turns, road-entry restrictions, directional signs, and lane arrows in Phase 3. One-way travel and no-entry restrictions in the Phase 4 open-road scenario. |
| Traffic signals | Red-light stopping and stop lines in Phase 2; complete signalized turning restrictions in Phase 3. |
| Speed compliance | Basic overspeeding in Phase 2; context-aware overspeeding and inappropriate low-speed driving in Phase 3. Account for road/traffic conditions and legitimate slowing/stopping. |
| Overtaking | Double solid, broken, and combined solid/broken lines; no-overtaking signs; permissions according to the driver's side of a marking, in Phase 3. |
| Parking compliance | Driveway entrances/exits, double parking, facing against permitted traffic flow, ambulance/fire-truck access, pedestrian crossings, and pedestrian walkways in Phase 3. |
| Environments and conditions | Road segments, intersection, parking area, and daytime in Phase 2; bridges, open road, night, rain, and emergency encounters in Phase 4. Vehicle and road sounds start in Phase 1 and expand throughout. |
| Environmental hazards | Stalls extending into driving space, double-parked vehicles, potholes, rice drying on the roadway, and road construction by Phase 4. |
| Non-player road users | Pedestrian baseline in Phase 2; pedestrians crossing outside crossings and abruptly turning/running back; jeepneys and tricycles making frequent stops or restricting passing space; other NPC vehicles by Phase 4. |
| Inputs and platform | Single-player macOS desktop application; keyboard/mouse baseline; tested wheel controllers, DualShock 4, and Xbox profiles on macOS. Early device feasibility, then ongoing testing and final compatibility matrix in Phase 5. |
| Learning support from draft | Guided steps, contextual feedback, event recording, end-of-attempt explanation, and five recent attempts starting in Phase 2. Comparisons use compatible scenario conditions and assessment versions. |
| Open-world variation | Authored connected district with randomized eligible hazards, traffic patterns, and event timing in Phase 4. Save setup seed/version and actual encountered events; retain repeatable hazard variants for testing. |

## Godot system structure

Prefer GDScript and reusable scenes/resources for the prototype. Keep the following responsibilities separate so additional rules and scenarios do not require rewriting the vehicle.

| System | Responsibility |
|---|---|
| Course catalog and navigation | Define the four course entries and maneuver sub-lessons; connect menu, briefing, driving, results, retry, and return. Store lesson availability and progress locally. |
| Input adapter | Convert keyboard, mouse, gamepad, wheel/pedal, and optional shifter inputs into the same driving actions; provide calibration, dead zones, and mappings. |
| Vehicle and transmission | Consume normalized inputs; simulate steering/braking/propulsion, clutch and gear state; expose speed, pose, and control state. Use sedan/SUV configuration resources. |
| Road and traffic model | Store lane direction, road markings, stop lines, parking zones, signs, signal phase, and scenario-specific speed settings. Visual signs and rules share the same data. |
| Scenario manager | Define spawn positions, objectives, route, conditions, NPC behaviors, completion/failure conditions, and reset behavior. |
| NPC and hazard controller | Use lane paths and small behavior state machines for driving, stopping, yielding, crossing, and turning back. An event director selects eligible templates, manages seeded variation/cooldowns, and logs what actually happens. Support fixed lesson setups and randomized Open World. |
| Rule evaluator | Read road context and vehicle events; determine compliance; handle exceptions and duplicate suppression. |
| Learning and attempt recorder | Drive prompts, map events to criteria, explain results, persist recent attempts locally, and compare compatible attempts. |
| Presentation | First-person cockpit/look controls, mirrors, instruments, menus, HUD, weather visuals, lights, wipers, and audio; consistent sourced/custom assets. |

Use authored lane paths for road vehicles and scripted pedestrian routes initially. Open World reuses these systems across a compact connected district with freely chosen routes; the event director varies encounters within authored road geometry.

## Decisions that need early validation

**Vehicle handling.** Test a basic `VehicleBody3D` implementation first against low-speed turns, braking, reverse, parking, slopes/bridges, and uneven surfaces. Its built-in simulation has documented limitations, and gears need additional logic. Keep the transmission separate so a more controllable `RigidBody3D` implementation can replace the initial vehicle if the trial fails. Make this decision before building many lessons. [Godot 4.7 VehicleBody3D documentation](https://docs.godotengine.org/en/4.7/classes/class_vehiclebody3d.html)

**Manual operation.** A gear label alone is insufficient. Define how clutch engagement, selected gear, and throttle affect propulsion; how neutral and reverse behave; and how invalid shifts are handled. Decide whether simplified stall/restart behavior is needed for the chosen lessons. Keyboard clutch control can use a gradual input ramp, but must remain explicitly operated by the learner. Describe its fidelity as a simulation approximation.

**Hardware.** Record the actual wheel, pedals, gamepad, OS, connection type, and driver configuration. Verify independent throttle/brake/clutch axes, combined or inverted pedal axes, steering range, gear controls, disconnect/reconnect, and saved mappings. Godot documents specialized wheels as less tested and does not implement force-feedback override for those devices; do not make wheel force feedback a prototype dependency. [Godot controller documentation](https://docs.godotengine.org/en/4.7/tutorials/inputs/controllers_gamepads_joysticks.html)

**Rendering.** The current project uses Forward Plus and Jolt Physics. Benchmark the chosen renderer on the actual demo hardware before committing to detailed scenery, shadows, mirrors, or heavy rain effects. Set minimum hardware requirements from measured results, not assumptions.

**Road-rule interpretation.** Author a small rule register containing scenario, applicable source, compliant behavior, violation condition, exceptions, feedback, and simulator assessment criteria. Verify legal wording and any penalty information against current official sources during content authoring. This plan does not establish legal speed values, monetary penalties, or official passing thresholds. Keep simulator deductions distinct from legal penalty information, consistent with the draft.

## Assessment and verification

Each scenario needs a starting state, objective, completion condition, observable events, expected behaviors, and repeatable reset. Give every requirement an ID linked to a scene and verification case.

Prioritize the following meaningful checks:

- Speed: legitimate stops for a red light, pedestrians, congestion, hazards, or emergency vehicles must not be treated as inappropriate low-speed driving.
- Signals: use the stop-line crossing time, direction, and applicable signal phase; being inside an intersection when the light changes is not the same event as entering on red.
- Overtaking: evaluate the marking on the driver's side and other applicable restrictions; do not infer permission from the appearance of one nearby line alone.
- Parking: distinguish parking from a temporary traffic stop; evaluate occupied space and heading against the local permitted traffic direction.
- Hazards: record onset and response separately from whether the response was appropriate. Faster reactions are not automatically safer. Include safe, unsafe, delayed, absent, and anticipatory responses.
- Attempts: test saving/reloading, five-attempt retention, repeated event suppression, and exclusion of incompatible settings or assessment versions from direct comparisons.
- Controls: test all represented inputs and visible effects on each claimed supported device; no automatic-transmission test cases are in scope.
- Courses and camera: every available menu entry starts the correct lesson and supports review/retry/return. All driving uses the first-person cockpit; check mirror usefulness, instrument legibility, look controls, camera clipping, and comfort.
- Random encounters: test eligibility rules, feasible response windows, cooldowns, varying seeds, repeated setup generation, and event logging. Player actions may change outcomes. Different hazard exposures must not be treated as equivalent attempts.
- Asset quality: inspect cockpit and nearby road assets from the actual driving camera in day/night/rain; verify visual consistency, collisions, animations, source records, and measured performance.

Use focused automated tests, such as the draft's proposed GUT tests, for rule conditions, transmission state, event classification, and saved-attempt logic. Use functional driving sessions for complete scenarios, instructor review for behavior/assessment criteria, and learner sessions for clarity and usability. Record performance under night/rain and the busiest planned NPC scene on the target computer.

The final prototype is complete when all feature rows have working scenarios or controls, reviewable evidence, and no unresolved critical failures. Educational results describe observable simulator performance; they are not official licensing results or proof of real-world driving competence.

## Draft alignment notes

Reviewed supporting material: `SE_Chap_1-3_draft.pdf`, particularly §1.3, §1.6, §3.1, §3.3, and §3.5. PDF page numbers below count from the cover.

- §1.6, PDF pages 26–28, agrees with manual-only coverage and confines one-way/no-entry restrictions to the open-road scenario.
- §3.1 objective 4, PDF page 66, mentions manual and automatic transmission. §3.5, PDF page 81, also includes automatic-transmission testing. These passages need revision to match the current manual-only scope. The source PDF has not been edited.
- §1.3 and §3.5, PDF pages 15–16 and 78–85, support guided maneuvers, explanatory feedback, observable-event assessment, and repeated-attempt tracking. These are included here as learning-support proposals drawn from the draft.
- §3.5 specifies five recent attempts and condition-aware comparison. Preserve scenario/settings/assessment identifiers from the first saved attempt.

## Godot connection check

Checked on 6 October 2026:

- Godot connector responded to `get_godot_version`: `4.7.2.stable.official.ed1daf0bf`.
- `get_project_info` successfully read `/Users/daniel/maniubra-prototype`.
- `project.godot` declares the name `ManiubraPrototype`, Godot 4.7, Forward Plus, and Jolt Physics.
- The project currently contains zero scenes and zero scripts, and no main scene is configured. There is no playable simulation to validate yet.
- A headless editor load completed project initialization and exited with code 0. It also reported a macOS system certificate-access error and inability to save global editor settings under the restricted filesystem. This is not a clean runtime/gameplay test, and the cause of the certificate error was not further diagnosed.
- Connector access and engine/project discovery are confirmed. Graphical gameplay, exports, and physical controller operation remain untested.

## Inputs needed to date the plan

Confirmed constraints: ASAP delivery, single-player, macOS initially, first-person cockpit driving, four course categories ending in randomized Philippine Open World, and permission to source online assets or create custom ones. A reliable calendar still requires team size and availability, target Mac specifications, actual controller models, asset availability/budget, and expected handling fidelity. No fixed completion date is promised before the vehicle/input trial and first complete lesson. Windows and Linux delivery are not initial milestones.

The next implementation milestone is Phase 0 followed by the first-person manual sedan test yard and Primary Controls course. It should establish vehicle handling, input feasibility, cockpit quality, and course navigation before expanding the map.
