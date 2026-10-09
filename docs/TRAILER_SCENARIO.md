# Trailer Scenario — Palengke

Requested 10 October 2026: a second, small Filipino map, with crowding, many obstacles, NPCs visiting stalls, jeepneys and tricycles in traffic, and a fast oncoming motorcycle when the player counterflows.

The scenario is a separate lesson (`trailer_market`) within Open World. It reuses the first-person manual sedan, inputs, contact/error toasts, pause/restart, and saved session review. Exploration is unrestricted, with no route, marker, compulsory destination, or timer.

The authored map is a roughly 100 × 190 m fictional Iloilo-inspired market neighborhood. A rounded two-lane road loop connects the crowded palengke frontage with a quieter return street. Stalls encroach into the edges of both lanes at staggered locations, leaving sedan and jeepney clearance. Shop signs, corrugated roofs, awnings, produce, rice sacks, public transport, overhead utility wires and laundry supply the local identity.

Shoppers walk along the sidewalk, stop at stall counters for a seeded interval, then continue to another stall. Vendors remain at their counters; ordinary pedestrians and conditional crossing encounters add street activity. Jeepneys and tricycles circulate in each direction and make short stops.

Two helmeted motorcycles are visible at roadside positions before an encounter. On the straight market frontage, sustained travel in the opposing lane can activate the rider ahead. The rider merges into its own lane and approaches faster than normal traffic. Activation requires an approach-distance window and a clear merge area; a close or obstructed encounter is suppressed. Contact still produces the existing vehicle incident toast. Counterflow and motorcycle onset are recorded separately, with repeat suppression. These are authored simulator conditions, not legal penalty claims.

Acceptance checks: menu → briefing → map → review → retry; continuous drivable loop and stall clearance; shopper arrival, dwell and departure; correct-lane and stopped-car rejection; opposite-heading lane detection; response-distance and traffic gating; one-time rider activation; pause/restart cleanup; contact toasts; native cockpit/map renders and scripted driving. Manual exported-app tuning remains required before claiming final driving feel.
