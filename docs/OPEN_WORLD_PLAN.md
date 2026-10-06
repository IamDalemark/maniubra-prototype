# Open World — Iloilo driving plan

Planning date: 7 October 2026. A first playable slice now has a connected drivable district, the optional Molo Plaza badge flow, six moving road vehicles, sidewalk walkers, two conditional crossings and three physical vendor stalls. A first landmark visual pass gives Molo Church a twin-spire front, Calle Real a continuous heritage storefront row, and the riverside a railed promenade. These are stylized interpretations rather than finished models. Traffic behavior, a more distinctive neighborhood at the departure point, and measured travel-time tuning still need work.

## Experience

Courses → Open World → first-person manual driving with an automatically displayed optional destination venue name. The player ends the session from pause when ready to review. Reuse the current sedan, cockpit, engine/stall behavior, seatbelt, handbrake, pause controls, and attempt history.

- There is one Open World mode, with no Free Drive / Destination selection. Every session allows unrestricted exploration of the connected streets.
- At spawn A, automatically show only the venue name for suggested destination B. The player chooses how to get there or ignores it entirely; never arriving causes no failure or penalty.
- Reaching the painted stopping box awards a small destination badge shown in a brief toast. Driving continues immediately, without a completion screen, modal, required choice or automatic new objective. Clear the completed destination name.
- Target about three minutes for the default A–B drive, measured from departure. Taking another road, waiting for pedestrians, or driving cautiously may take longer without a time penalty.
- Interpret two lanes as two total: one lane in each direction, with right-hand traffic. This is a proposed layout assumption, not two lanes per direction.

## Map and local identity

Build one compact, continuous Iloilo-inspired district, initially about 800 × 650 m, with roughly 2–3 km of connected road centerline. These are blockout targets, to be adjusted after driving. Compress the distances between landmark areas and label the map as inspired by Iloilo; do not imply an accurate navigation map or real three-minute journey between distant districts.

| Area | Visual identity | Driving purpose |
| --- | --- | --- |
| Calle Real-inspired heritage street | Distinctive heritage facades, shop arcades, recognizable storefront rhythm, local shop names | Commercial traffic, jeepney stops, intersection approach |
| Molo Church and plaza-inspired area | Recognizable church silhouette, plaza planting and pedestrian edges | Landmark for navigation, turning, pedestrian activity, nearby off-road destination bay |
| Iloilo River Esplanade-inspired frontage | River, landscaped promenade, railings, trees and a bridge approach | Open sight lines, bridge passage, gentle bends; promenade remains for pedestrians |
| Neighborhood/market connector | Sari-sari stores, houses, batchoy/food stalls, awnings, drainage, appropriate utility poles | Vendors narrowing the road, tricycles and intermittent pedestrian crossings |

First-release art acceptance requires three recognizable anchors: Calle Real, Molo Church/plaza, and the river/Esplanade. Jaro Cathedral and its plaza are a later extension if the first map has enough visual quality and performance headroom. Landmark models need recognizable proportions and silhouettes from the driver's seat, not only name signs on generic buildings.

Use location-specific photo references before modeling each area. Apply overhead wiring, curb treatments and road wear selectively; do not cover every district with the same generic Philippine props. Match the approved stylized art direction with warm masonry, painted concrete, readable signs, vegetation and consistent asset scale. Make scenery dense near the road and simpler farther away.

### Road network

- A two-way perimeter loop plus at least two cross-connections; junctions offer real route choices.
- At least two T-junctions, one four-way intersection and one compact single-lane roundabout, with connected exits.
- Start with 3.0–3.25 m per lane as a game-design dimension, then validate clearances using the sedan, jeepney and tricycle envelopes.
- Sidewalks, corners, crossings, stop lines and appropriate center markings. Build clear sight lines at junctions before adding clutter.
- A small bridge connects the riverside segment. Natural map edges use buildings, riverbanks and signed road closures; avoid reachable unfinished roads.
- The connected streets provide left and right turns, at least one traffic-controlled junction, and a traversable roundabout. The player chooses which streets to use.

## Optional destination only

Place A in a safe neighborhood departure bay and B in an off-road stopping bay beside the Molo-inspired plaza. Multiple connected streets lead between them. There is no assigned itinerary or required intermediate landmark.

Space A and B so a practical drive is approximately 1.0 km and typically takes around three minutes with turns and traffic stops. Tune their placement through actual manual-driving runs. This is an internal map-sizing target; the chosen streets and exploration determine the actual distance and time. There is no prescribed route, countdown or time requirement.

- Show only the destination venue name, for example “Molo Plaza.” Players identify venues through readable signs on the actual buildings or entrances and recognizable landmarks. Do not add floating markers, waypoint icons, arrows, route lines, turn instructions, navigation maps or distance readouts.
- Driving down any connected street is valid exploration; there is no wrong-turn state.
- B is a painted rectangle, initially about 3.5 × 7 m, beside readable physical venue signage. Keep it outside the through lane and clear of pedestrian paths.
- Arrival requires all four vehicle footprint corners inside the box, speed below 0.5 km/h, and staying there for two seconds. Crossing the trigger at speed must not count.
- Award one destination badge per destination per session and show it in a short, non-blocking toast, for example “Destination reached · Molo Explorer.” Prevent repeated awards from remaining in or re-entering the box. The badge recognizes arrival only, not safe-driving certification.
- Clear the completed destination name and keep free exploration active. Review is available when the player chooses to end the session from pause. Do not prompt for another destination or automatically end the drive.

## Shared traffic

Start with a tunable cap of 8–12 active vehicles near the player, containing ordinary cars, jeepneys and tricycles. This is a profiling target, not a measured capacity.

- Cars follow their lane, keep gaps, brake for obstacles, obey the simulated signal state, and select valid junction exits.
- Jeepneys follow connected routes and occasionally pause at authored roadside pickup locations. They resume only when the gap is clear.
- Tricycles travel more slowly and make occasional roadside stops. Include enough variation to require patience without making every vehicle an obstacle.
- Use a lane graph with straight/turn connectors and intersection reservations or signal permissions. Reserve a safe exit gap before entering a junction to reduce gridlock.
- Start with authored routes and longitudinal following. Add limited passing around a stopped vehicle only where visibility, markings and opposing gaps allow it. Waiting is a valid response.
- Detect the player and pedestrians as obstacles. Do not spawn vehicles inside the player's view or immediately ahead. Reset stuck NPCs only out of view and without removing an active encounter.

Existing jeepney/tricycle props are visual scenery. Reuse suitable meshes, but add wheels, colliders, motion and behavior as actual traffic actors. Do not mark them complete merely because the props already exist.

## Vendors and pedestrians

Place vendors at authored market/roadside positions. Some stalls partially encroach into a lane and require slowing or waiting for an opposing gap. Keep every generated configuration navigable, including by a jeepney. Do not place permanent stalls across both lanes, the destination bay, or all alternate routes.

Pedestrians use sidewalk paths, wait near shops/stops, and cross at authored crossing points. Initial target: 12–20 active people around nearby streets, profiled on the demo Mac.

Two behavior groups:

1. Ambient walkers follow sidewalks and ordinary crossings. Traffic yields when their crossing is occupied.
2. Occasional hazard encounters introduce a sudden crossing at selected visible locations. Later variants can pause or reverse direction while crossing.

Choose hazards with a per-session seed, cooldown, occupancy checks and a response-distance check based on approach speed. A pedestrian must exist at the roadside before entering the lane. Suppress the event if the player is already too close to respond. Avoid stacking a crossing, oncoming vehicle and blocked lane into an unavoidable collision. A changed seed varies encounters, while the same seed plus recorded events helps reproduce faults.

## Feedback and controls

- Reuse the current corrective toast style for actual detected events, without continuously interrupting free driving.
- Record elapsed time, suggested destination, earned destination badge, optional arrival, collisions, engine stalls and authored hazard encounters in the existing review timeline. Ending without arriving is a normal exploratory session, not a failed attempt. Keep badge persistence within the existing attempt record rather than introducing a separate achievement system.
- Record observable responses such as braking before a crossing. Do not claim that a player checked a mirror or anticipated a hazard solely from camera direction.
- Do not add legal fines or a general safety score before validated rules and detection criteria exist.
- Add functional left/right signals and visible NPC indicators before the final traffic demo; the current practice input set does not supply the complete secondary controls course.
- Start with daytime and dry roads. Night, rain, emergency vehicles and the remaining original feature list remain later work.

## Minimal Godot implementation

Preserve course ID `open_world` and lesson ID `philippine_roads`. Only give that catalog entry a scene path after the mode has a working start, drive, pause, exit and review path.

| Proposed owner | Responsibility |
| --- | --- |
| `scenes/lessons/open_world.tscn` + `scripts/open_world.gd` | Session ownership, menu context, spawn, pause, destination-name text, destination state and review events |
| `scenes/world/iloilo_district.tscn` | Roads, landmarks, collision, named spawn/stop/hazard locations, sidewalk paths |
| `scripts/world/road_network.gd` | Lane/turn connections for NPC traffic and junction permissions |
| `scripts/world/traffic_vehicle.gd` | One shared movement/following state machine configured for cars, jeepneys and tricycles |
| `scripts/world/pedestrian.gd` | Sidewalk, waiting and crossing states |
| `scripts/world/encounter_director.gd` | Seeded eligible encounters, population caps, cooldowns and safe spawning |
| `scripts/world/destination_zone.gd` | Painted-box geometry and full-vehicle stopping confirmation |

Use simple scene ownership and local signals. Keep this separate from the practice-lot controller and reuse the existing vehicle. Extract shared UI only when the second session needs it. Use the road graph for NPC traffic connectivity; player destination display needs only the venue name, while arrival detection uses the stopping zone. Use stable IDs for landmarks, destinations and encounter locations.

## Build order and acceptance gates

1. **Drivable map blockout:** connect the loop, alternate streets, junctions and A/B bays. Drive the existing sedan through all exits and tune A/B spacing for an ordinary drive of around three minutes. Check road seams, turning clearance and connectivity across freely chosen streets.
2. **Iloilo visual slice:** finish one heritage block and the three landmark anchors using references. Capture them from the actual cockpit. Establish local identity before copying buildings across the rest of the map.
3. **Optional destination within Open World:** automatically show only the destination venue name, detect stopping in B and award a badge/toast once. Verify venue signage is readable from the cockpit and there are no navigation markers, route lines or turn instructions, the player can ignore the destination, finish a session without arriving, and keep driving after earning the badge without a modal or mode choice. Check full containment, rolling-through rejection, duplicate-award prevention, pause/restart and returning to menus.
4. **Shared traffic:** introduce cars first, then jeepneys and tricycles, intersection control and indicators. Verify they share the road with the player, stop behind each other, clear junctions and recover from congestion.
5. **People and vendor encounters:** add sidewalk movement, ordinary crossings, constrained vendor placement and occasional sudden crossings. Verify encounters remain visible, escapable and reproducible, with NPC traffic also yielding.
6. **Export and tune:** manually drive multiple seeds and alternate routes in the macOS app. Measure typical A–B travel time, frame time, traffic stalls and input responsiveness with cockpit mirrors enabled. Tune population/detail to target 60 fps at the demo resolution; report actual measurements. Verify review persistence and complete the final art/reference/license pass.

First playable Open World is complete when entering directly starts free exploration with only an optional destination venue name, the player can earn a badge/toast by stopping within B and continue without interruption, and the connected two-lane roads contain all three traffic vehicle types, sidewalk walkers, occasional crossings, partial vendor obstructions and recognizable Iloilo landmarks.

## Reference sources and asset use

The city tourism listings identify Calle Real, Molo Church, the Iloilo River Esplanade and Jaro Metropolitan Cathedral as local attractions:

- [Iloilo City tourism listing](https://invest.iloilocity.app/?page_id=1224)
- [Iloilo City Government — About the city](https://iloilocity.gov.ph/about-us/)
- [Iloilo City Government — Discover Iloilo City](https://iloilocity.gov.ph/discover-iloilo-city/)

These establish reference locations, not the proposed fictional road connections or scene dimensions. Review photographs of each selected landmark before modeling. Reference photographs are not automatically licensed game textures. Build original meshes or incorporate assets with recorded source, creator, license and modifications in `assets/ASSET_REGISTER.md`.
