# Trailer Scenario — Palengke

Requested 10 October 2026: a second, small Filipino map, with crowding, many obstacles, NPCs visiting stalls, jeepneys and tricycles in traffic, and a fast oncoming motorcycle when the player counterflows.

The scenario is a separate lesson (`trailer_market`) within Open World. It reuses the first-person manual sedan, inputs, contact/error toasts, pause/restart, and saved session review. Exploration is unrestricted, with no route, marker, compulsory destination, or timer.

The authored map is a roughly 100 × 190 m fictional Iloilo-inspired market neighborhood. A rounded two-lane road loop connects the crowded palengke frontage with a quieter return street. Stalls encroach into the edges of both lanes at staggered locations, leaving sedan and jeepney clearance. Shop signs, corrugated roofs, awnings, produce, rice sacks, public transport, overhead utility wires and laundry supply the local identity.

Shoppers walk along the sidewalk, stop at stall counters for a seeded interval, then continue to another stall. Vendors remain at their counters; ordinary pedestrians and conditional crossing encounters add street activity. Jeepneys and tricycles circulate in each direction and make short stops.

Two helmeted motorcycles are visible at roadside positions before an encounter. On the straight market frontage, sustained travel in the opposing lane can activate the rider ahead. The rider merges into its own lane and approaches faster than normal traffic. Activation requires an approach-distance window and a clear merge area; a close or obstructed encounter is suppressed. Contact still produces the existing vehicle incident toast. Counterflow and motorcycle onset are recorded separately, with repeat suppression. These are authored simulator conditions, not legal penalty claims.

Acceptance checks: menu → briefing → map → review → retry; continuous drivable loop and stall clearance; shopper arrival, dwell and departure; correct-lane and stopped-car rejection; opposite-heading lane detection; response-distance and traffic gating; one-time rider activation; pause/restart cleanup; contact toasts; native cockpit/map renders and scripted driving. Manual exported-app tuning remains required before claiming final driving feel.

## Implementation and verification, 10 October 2026

The map, crowd, local traffic and motorcycle encounter are implemented. Population: twelve vendors, twelve shoppers, four other pedestrians, four jeepneys, four tricycles, two cars and two roadside riders. Riders remain visible while waiting. Counterflow must persist for 0.6 seconds while moving forward at least 1 m/s; returning to the correct lane for 0.8 seconds resets the incident latch. A rider needs at least 38 m (more at higher player speeds) and a clear merge. It first merges slowly, accelerates only once aligned, approaches at up to 13 m/s, then circulates at 5 m/s with a 32-second encounter cooldown. Its collider remains on its own side during the straight approach. These timings and speeds are prototype tuning values.

Checks completed:

- `tests/trailer_scenario_flow.gd`: catalog launch through saved review/retry, stall clearance, shopper arrival/browsing/departure, pause and fall/contact feedback.
- `tests/trailer_counterflow.gd`: correct/stopped-car rejection, both opposing headings, close/blocked suppression, actual fast rider motion without crossing the centreline, event deduplication, pause/contact, and reconstruction of riders/map on restart.
- `tests/open_world_flow.gd`: original district launch, optional destination badge, review and persistence regression.
- A 120-second simulated traffic probe confirmed all ten ordinary vehicles moved beyond their initial queue.
- macOS release export rebuilt with the existing controller helper. The built app launched to its menu; its actual PCK was run through native Metal map rendering, pause, saved review and map-ID verification using the installed Godot runtime. This is a packaged-scene check, not a manual exported-app drive.
- Native Metal cockpit, map, rider and toast captures inspected. A native scripted sedan run covered about 370 m around the whole loop without incident events or tipping. Moving actors were removed for this geometry check; it does not validate human driving feel in crowded traffic. `tests/trailer_map_drive.gd` retains the reproducible drive.

The return street is intentionally less crowded than the market frontage. This is a fictional neighborhood, not a surveyed Iloilo location. Next: manually drive the exported app through the crowd in both directions, tune encounter visibility/yielding, and assess performance across a full session on the intended demo Mac.
