# Agent implementation handoff

## Objective and current baseline

Build Maniubra incrementally: a presentable, first-person manual-driving simulator for one player on macOS. Delivery is ASAP. The full product scope remains in `PROTOTYPE_PLAN.md`; complete a small course end to end before expanding the world.

Implemented now: four-course menu, nine individual maneuver entries, playable Primary Controls and an early playable Open World lesson in a first-person, left-hand-drive manual sedan. Its eight-step enclosed-lot exercise has timestamped feedback, upper-right corrective error toasts for rejected shifts, stalls, and blocked starts, pause/restart/exit, local five-attempt history, original stylized roofed cockpit/road geometry, rear and side mirror views, synthetic audio, and a local macOS export. The sedan now has animated steering and shifting hands, H-key ignition, a B-key and clickable seatbelt toggle with a right-arm reach across the chest toward the left shoulder, an animated handbrake lever beside the steering wheel with a brief hand reach on application and release, low-speed clutch/brake stalling with engine shutdown, stronger propulsion, approximate RPM, tighter suspension, and a camera stabilized against body roll. An upper-left driver check shows seatbelt and handbrake state; the seatbelt is currently a practice indicator, not a scored safety rule. The 160 × 240 m enclosed practice lot has a clear launch lane, painted parking bays, a cone slalom with 17 physical cones, and a circular practice loop. Reusable original 3D shopfront, palm, jeepney, and tricycle scenes sit beyond the walls. The road-user vehicles here are static scenery, and the roundabout is not yet an assessed maneuver. Course and maneuver selections use generated illustrated cards with accurate availability labels. Start is enabled for Primary Controls and Open World. Open World has connected streets, a painted optional Molo Plaza stop, one badge toast per drive, six scripted moving vehicles, eight pedestrians including three conditional crossings, and three collidable vendor stalls. Secondary Controls and individual maneuvers remain unavailable. Physical controller profiles and a sourced 3D asset collection are not validated or added yet.

Open World now has shared-style corrective toasts for shift/ignition/stall errors, pedestrian and traffic-vehicle contacts, roadside-stall contacts, and one authored market stop line. Incidents are included in its review. Pedestrians have separate moving arms and legs plus a simple fall animation on sedan impact. The sedan's gauges sit lower and are smaller to expose more of the near road in first person. `tests/open_world_flow.gd` checks the authored stop condition and event deduplication; `tests/open_world_collision.gd` verifies actual Jolt contact with a pedestrian and another vehicle. Manually drive and tune the sign/line and collision feedback in the exported app before expanding rule coverage.

The selected gear label is now a child of the shift lever's knob, displaying N, R, or the forward gear number on the control itself as the lever moves. The existing HUD gear readout remains for accessibility. This was checked in native Metal cockpit captures; verify legibility at the intended display size during the exported-app playthrough.

The two authored Open World crossing pedestrians use seeded reactions: one runs across and one briefly hesitates then runs back after entering the road. After reaching the curb, the turn-back actor wanders a bounded sidewalk corridor at varying walking speeds, with occasional runs and reversals. Two other sidewalk walkers have occasional short runs and reversals. Their gait quickens while running. The crossing trigger keeps a minimum response distance, and the session review records a turn-back separately from crossing and collision. `tests/pedestrian_behavior.gd` checks the return-to-roam transition, sidewalk bounds, continuing movement, speed variation, one-time event counts, and seeded reproducibility. A manually driven visibility and timing pass is still needed before treating the encounters as tuned hazards.

A separate ordinary walker uses the painted zebra crossing on the market street, about 37 m beyond the Open World start. The old decorative stripes outside the road were replaced by seven stripes spanning both lanes. The walker waits until the player's car is moving within a response distance, crosses curb to curb at walking pace, then continues roaming on the far sidewalk. Review records this as a marked crossing. `tests/marked_crossing.gd` checks paint/path alignment, stationary waiting, crossing, one event, and far-side roaming. A native Metal cockpit capture showed the person and crossing ahead, but visibility and traffic yielding still need a manually driven pass.

The steering wheel now turns farther visually, and the procedural hands perform a hand-over-hand reach and regrip during stronger turns in either direction. Small corrections retain a two-hand grip. Native Metal captures checked neutral, crossover, and full-lock poses; gear, handbrake, and seatbelt reaches still have priority. The animation remains a stylized approximation and needs a manual exported-app feel check.

The sedan passenger side now has matching front/rear door shells, handles, transparent window panes, and interior trim. Side mirrors have angled housings facing the left-seat driver and raised reflection cameras. They are mounted outside the door skins, just behind slimmer front pillars. Native Metal captures at the user's Open World screenshot aspect ratio checked the straight-ahead view and a small right glance; the driver mirror has a small pillar overlap, and the far mirror is fully visible with that glance but remains near the forward view's edge. Perform a manually driven mirror check in the exported app before treating mirror usefulness as fully accepted.

The Xbox preset maps every implemented driving control, first-person look, pause, and menu select/back. Settings shows connected controller status, editable controller dropdowns, and keyboard remapping. Controller choices cover steering/look axes, triggers, driving buttons, and menu buttons; conflicts swap within a group. The controller layout is saved separately from keyboard bindings and is shared by native Godot gamepads and the direct USB path. Tests cover both paths, swap behavior, persistence, and reset. On 8 October 2026, a Microsoft Xbox One controller (`045e:02d1`) enumerated over USB but macOS GameController and Godot 4.7.2 reported zero gamepads. A statically linked libusb reader initializes this model and relays its live GIP reports over localhost to Godot, which generates the existing semantic actions. Godot received its live heartbeat, and the exported app contains the helper. Trigger/stick calibration and actual driving comfort still need a physical playthrough.

The sedan now sits lower on its wheels. A flat-road regression check keeps ordinary full-lock cornering planted and still permits rollover at high speed; inspect handling in a manually driven exported-app run before treating the tune as final.

Audio playback was repaired by setting explicit WAV loop endpoints. The engine sound now starts with ignition, stops on shutdown or stall, and loops while running; the volume setting controls both engine and road sounds. A graphical macOS probe measured a live Master-bus signal; confirm audibility on the intended speaker/headphone output during the exported-app playthrough.

**Status of Steps 1–6:** implementation, focused logic checks, scripted full-lesson check, and graphical exported-app launch/pause check are done. Step 6's stricter acceptance check remains open: two manually driven runs in the **exported** app (one with deliberate shift errors), followed by save/relaunch and retry verification. Complete that check before marking the first playable milestone fully accepted. Then proceed to Step 7.

Read `AGENTS.md`, the plan, and `docs/ARCHITECTURE.md`. Inspect the current files before editing; this handoff may outlive the initial shell. Record newly discovered hardware and tooling facts instead of assuming them.

10 October 2026 — Primary Controls beginner guidance: a centered panel now explains each exercise goal and reason, then presents a single state-aware action. A live control-only close-up shows glowing physical pedals, ignition, steering wheel and levers while the driving camera remains unchanged. Keyboard/controller labels follow current assignments. Stall recovery and accidental overshifts get actionable prompts. Engine/RPM/seatbelt, clutch/gear, speed, brake and handbrake metrics appear individually as introduced; pause freezes the reveal and restart clears it. Completed steps retain their existing numeric position and now include stable IDs. Scenario/assessment version 3 identifies the revised teaching and a zero-speed-aligned stop threshold. Focused guidance checks, the Open World regression and a native scripted complete lesson pass. The macOS app was rebuilt; its actual game pack also passed the complete rendered lesson and saved-review checks under the installed Godot runtime. Actual beginner comprehension and physical-controller comfort remain manual checks.

10 October 2026 — user-requested backing parking: `parking` is now the first implemented Maneuvers entry, titled Parking — Backing with Guide. `backing_parking.gd` directly reuses the Primary Controls guide and session lifecycle; `parking_view.gd` adds a live footprint/bay diagram. Six stable goals cover start/reverse/turn/straighten/stop/secure. The entire footprint and facing-out heading must fit, followed by neutral and a two-second handbrake hold with the foot brake released. Pause freezes assessment; reset restores physical cones. Shift, engine, cone-contact and speed reminders feed the same side toasts and saved review. Tests cover geometric boundaries, hold interruption/pause, reset, deduplication, device labels, actual cone collision, and a complete physics-driven reverse turn through persistence/retry. Native Metal captures were inspected and Primary Controls/Open World regressions pass. The rebuilt standalone macOS app launched; the actual exported game pack passed the complete native parking, physical-contact and saved-review/retry check under the installed Godot runtime. Manual exported-app parking and beginner comprehension remain acceptance checks. This is a wide-bay first variant starting alongside; forward approach, shunting, reduced prompts and legal compliance modules are not implemented. Next concrete step: manually drive this lesson with keyboard and the connected controller, tune prompt timing and bay visibility, then add the next requested maneuver or Secondary Controls.

## Working procedure for each step

10 October 2026 — Trailer Scenario: a second Open World map (`trailer_market`) is playable from its own briefing through saved review and retry. It has a compact rounded road loop, twelve encroaching palengke stalls, local streetscape details, ten jeepney/tricycle/car traffic actors, twelve vendors, twelve shoppers and four other pedestrians. Shoppers approach, browse for seeded intervals and leave for another stall. The focused flow check passes menu launch, physical scene ownership, crowd behavior, pause, contact/fall feedback, result identity and retry. Native Metal cockpit and overview renders were inspected (one short stationary capture reported 119 FPS at 1600 × 900 on the M4 Pro; this is not a full-session benchmark). The counterflow step is implemented: two visible helmeted riders merge and approach at up to 13 m/s after sustained wrong-lane travel. Tests cover both headings, stationary/close/blocked rejection, real rider movement within its own lane, event deduplication, contact, pause and complete restart. A native scripted sedan drive completed the roughly 370 m loop without obstacle contacts or tipping, with moving actors removed to isolate map clearance. Native motorcycle and encounter-toast renders were inspected. The macOS app was rebuilt, its menu launched, and its actual game pack passed native scene rendering, pause and saved-review verification under the installed Godot runtime. Manual exported-app driving with the full crowd is the next tuning check.

1. Identify the earliest incomplete step within the user's requested milestone.
2. Inspect its prerequisites and existing implementation. Preserve user changes.
3. State the concrete deliverable, then implement it without broad unrelated scaffolding.
4. Run its acceptance checks, inspect relevant visuals, and fix failures.
5. Update README/current-state notes. Report what works, what was tested, limitations, and the next step. Do not present planned work as finished.

If the user requests the first playable course, complete Steps 1–6, including the remaining exported-app acceptance check. If they request the full prototype, continue through the remaining steps. Do not treat one step as permission to stop before the requested milestone is complete.

## Step 1 — Verify the shell and establish a test yard

**Deliver:** `scenes/lessons/primary_controls.tscn` with a flat road/practice area, static ground collision, lighting, a vehicle spawn, and a session controller. Add a session child under App only when launching the lesson. Keep the public Start button unavailable until Step 6; use direct scene launch for development.

**Actions:**

- Verify installed Godot and load `project.godot`; preserve the existing Jolt/renderer choice unless measured evidence requires a change.
- Inspect demo Mac hardware and available local modeling tools. Establish a performance budget to verify on that machine; document measured results rather than invented minimum specifications.
- Add the session lifecycle described in the architecture. Implement return/restart without saving or scoring yet.
- Make test geometry consistent in scale; use one unit as one meter. Keep the training yard small.

**Accept:** direct scene run works, restart restores the same starting state, returning to the menu removes the session, and no script/scene errors occur. A graphical check is required; headless startup alone is insufficient.

## Step 2 — Select the sedan and establish the first-person view

**Deliver:** a sedan scene with a usable left-hand-drive interior and a stable cockpit camera. Temporary primitive geometry is acceptable while testing movement, but the first course's delivery needs a coherent interior.

**Actions:**

- Inspect candidate models for interior geometry, steering wheel, gear lever, wipers, material organization, scale, and rights to use/adapt them. Do not assume candidate packs listed in the plan contain a usable cockpit.
- Prefer a suitable free model; create missing geometry or adapt a model when faster. Record source/license/custom work in `assets/ASSET_REGISTER.md` and retain included license files. Paid assets need an approved budget.
- Add camera position/look controls, adjustable field of view, and mouse capture/release. Restore the cursor in menus and on pause.
- Establish windshield visibility and mirrors before designing reversing and lane-change lessons. Test mirror render quality/cost on the actual Mac. Avoid a driver body/hand rig until it provides useful value.
- Match materials and lighting in a small cockpit-and-street sample before importing a large collection.

**Accept:** no camera clipping at ordinary look angles, instruments can be read, front/side/rear checks are usable, and the scene remains responsive. Report any unfinished mirror or interior work explicitly.

## Step 3 — Implement input and manual driving

**Deliver:** normalized input, a manual transmission model, and a sedan that can move, steer, stop, and reverse.

**Actions:**

- Add named input actions for steering, throttle, brake, clutch, handbrake, gear up/down or direct selection, look, and pause. Keep mappings outside vehicle physics logic. Document defaults in README and display them in the lesson briefing.
- Implement gradual keyboard steering/pedal values while keeping the clutch explicitly user-operated. Preserve analog values for actual pedals/triggers.
- Start with `VehicleBody3D` behind the vehicle interface. Implement gears/clutch separately; built-in vehicle physics does not provide the manual transmission model.
- Define neutral, reverse, gear ratios, clutch engagement, and invalid shift handling. Decide and document whether simplified stall/restart behavior is needed. Make behavior teachable and observable.
- Display speed, selected gear, and relevant control states. Animate the steering wheel/gear lever from vehicle state.
- Test available controller axes early, particularly wheel/pedal independence and inversion. Unavailable physical devices remain unverified.

**Accept:** neutral does not propel the vehicle; depressing the clutch removes transmitted drive; gear changes alter drive behavior; reverse works deliberately; braking and handbrake stop/hold the vehicle as specified. Repeat low-speed turns, reversing, parking approach, and restart. If vehicle physics is unstable, resolve the model now before building further lessons.

## Step 4 — Turn the test yard into Primary Controls

**Deliver:** a guided sequence covering steering, accelerator, brake, clutch, gears, and handbrake, followed by a combined start/move/shift/stop exercise.

**Actions:**

- Define observable step completion and error conditions; separate pressing a control from executing the intended action.
- Add concise prompts, progress indication, pause/restart/exit, and useful control feedback.
- Track timestamped attempt events in the session. Freeze assessment time while paused; clear events and task state on restart.
- Add end-of-attempt feedback describing correct actions, missed actions, and the next practice suggestion. No arbitrary total score is needed.

**Accept:** a correct run completes; deliberate errors produce relevant explanations; repeating an event every frame does not duplicate penalties/events; restart and exit work from every step; gameplay stays first-person.

## Step 5 — Save attempts and finish the minimum presentation

**Deliver:** local review of the five most recent attempts and a presentable Primary Controls course.

**Actions:**

- Save versioned records under `user://` with lesson/scenario/assessment identifiers, vehicle, input profile, relevant settings, events, and result.
- Handle a missing, malformed, or incompatible save without crashing or silently misreporting results. Save through a temporary file and replace safely.
- Compare only compatible attempts. Do not turn simulation results into an official pass/fail decision.
- Add basic engine, tire/road, and control sounds with recorded sources/licenses. Balance the mix and provide a volume control.
- Complete one focused visual pass: cockpit materials, readable menu/briefing, clear road surface, consistent lighting, and no presentation-blocking placeholders.

**Accept:** results survive app restart; the sixth attempt retains the intended five most recent records; incompatible attempts remain identifiable and are not directly compared; corrupted/missing saves have a graceful outcome. Verify the complete course visually and audibly.

## Step 6 — Connect and deliver the first playable macOS course

**Deliver:** Primary Controls accessible from Main Menu → Courses → Primary Controls → briefing → Start → drive → results → retry/back, plus a working local macOS export.

**Actions:**

- Add the implemented lesson's scene path to the catalog; enable Start only when its session is available. Keep other lessons accurately marked unavailable.
- Add any necessary input/camera/audio settings used by this course; do not expose settings with no effect.
- Verify keyboard focus, window resizing, Escape behavior, mouse capture, pause, clean exit, and repeated course launches without duplicate sessions.
- Export for the actual demo Mac and launch outside the editor. Record architecture, macOS version, engine version, and observed performance. A local export is not a claim of signing/notarization for distribution.

**Accept:** complete two end-to-end runs, one correct and one with deliberate errors, using the exported app. Confirm saving and retry work. Report controller support only for physically tested devices. This completes the first playable-course milestone.

## Step 7 — Secondary Controls course

**Deliver:** selectable lessons/exercises for indicators, headlights, wipers, horn, and hazard lights with contextual examples.

**Actions:** reuse input and session contracts; add visible/audible feedback; introduce small night/rain test variants where needed; distinguish a control being on from appropriate use in a scenario.

**Accept:** each control works, its state is visible, the expected situation is explained, and correct/incorrect usage is recorded accurately. The course has the same briefing/review/retry loop as Primary Controls.

## Step 8 — Individual maneuver courses and rule logic

**Deliver in order:** Reversing, Parking, Left Turn, Right Turn, U-turn, Lane Positioning, Lane Changing, Merging, and Overtaking. Keep the menu order stable unless product needs change it.

**Actions:**

- Build one lesson at a time using shared road pieces and controllers. Each needs start conditions, required actions, completion conditions, errors, explanation, and restart.
- Add the five rule modules in the relevant lessons. Use the plan's full coverage table to ensure every stated restriction/marking/parking case is represented.
- Maintain a rule register with verified official source, compliant action, violation conditions, exceptions, and explanation. Document instructor-reviewed simulator tolerances separately.
- Test legitimate low-speed stops, stop-line crossing phase/direction, driver's-side overtaking markings, and parked heading/occupancy. Add meaningful logic tests for these boundary cases.
- Add the SUV only after shared sedan logic works. Use separate configuration and cockpit dimensions with the same input/lesson contracts.

**Accept:** every implemented maneuver is independently selectable and completes its full review loop. Correct, incorrect, and boundary cases behave consistently. Both vehicles remain manual and left-hand-drive.

## Step 9 — Build Philippine road users and the connected district

**Deliver:** reusable road network, bridge, parking, roadside activity, jeepneys, tricycles, other vehicles, and pedestrians; all required fixed hazard examples.

**Actions:** source/create culturally recognizable assets; retain a consistent art style; use lane paths and small NPC state machines. Implement pedestrian crossing/turn-back and frequent roadside stops as authored, repeatable scenarios before randomization. Add stalls, double-parked vehicles, potholes, rice drying, construction, and emergency encounters. Add day/night/rain settings and complete road audio.

**Accept:** district roads connect and are freely drivable, NPCs follow their intended behaviors, and every hazard can be tested independently. Observe performance and first-person visibility under the busiest conditions.

## Step 10 — Open World with randomized anticipation

**Deliver:** the final course, with New Session, Retry Same Setup, and End Session review.

**Actions:**

- Add an event director that chooses eligible hazard templates, locations, timing, and traffic variation. Use visibility/space constraints, cooldowns, and encounter spacing.
- Keep the district authored; randomize encounters instead of procedurally generating an entire city.
- Store seed, generator version, selected hazards, settings, and actual event timestamps/outcomes. The same seed reconstructs setup choices, not identical physics after different player actions.
- Preserve natural precursor cues and feasible responses. Avoid obstacles appearing directly in front of the driver and unavoidable overlapping events.
- Evaluate observable anticipation before onset and response afterward. Do not equate fast braking with an appropriate response or camera direction with attention.
- Include one-way/no-entry rules here. Display hazard exposure and per-event results; compare only compatible sessions.

**Accept:** fixed-seed setup generation is repeatable, different seeds produce legitimate variation, every required hazard is eligible somewhere, and several sessions remain playable without unfair spawn conditions or duplicate events. Review correctly reflects what the learner actually encountered.

## Step 11 — Full-scope verification and handoff

**Deliver:** exported macOS prototype with every agreed feature mapped to an implementation and verification record.

**Actions:** review all rows in the plan; run correct/incorrect/boundary playthroughs; obtain instructor review of lesson criteria; test usability with intended learners; profile night/rain/mirrors/NPCs; document exact DS4/Xbox/wheel hardware combinations tested; inspect asset register and controls/help text.

**Accept:** no missing course or required scenario, no critical navigation/driving/result failures, tested performance stated accurately, and remaining device/content limitations clearly documented. Update README and handoff notes with the actual final state.

## Practical verification commands

Use the installed executable on the current Mac, or discover the actual executable on another machine:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/daniel/maniubra-prototype --editor --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/daniel/maniubra-prototype --quit-after 5
```

Inspect output for parse/scene errors even if the process returns code 0. Restricted execution reported macOS certificate-access and global editor-settings save errors; distinguish these from project failures and report them honestly. Use a graphical run for UI/first-person inspection and real devices for compatibility checks. Focused harnesses now exist at `tests/core_logic.gd` and `tests/primary_controls_flow.gd`; run them with a temporary `MANIUBRA_DATA_DIR` to avoid overwriting learner data.

## Suggested next-agent prompt

> Read AGENTS.md, PROTOTYPE_PLAN.md, docs/ARCHITECTURE.md, and docs/AGENT_IMPLEMENTATION.md. Primary Controls is implemented and a macOS app is exported. First close Step 6 acceptance: manually drive one correct and one deliberate-error run in the exported app, verify saved results after relaunch, retry, clean exit, window sizing, and measure performance. Fix any failures. Then implement Step 7 Secondary Controls with visible and audible vehicle controls and contextual night/rain exercises. Preserve the first-person manual sedan, four-course menu, stable catalog IDs, and asset register. Leave later lessons unavailable until their entire review loop works, and report physical controller support only for tested hardware.
