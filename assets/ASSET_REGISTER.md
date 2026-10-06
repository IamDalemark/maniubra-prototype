# Asset register

The playable Primary Controls course uses project-created geometry and audio. The selection screens use seven generated illustrations inspired by the user's visual references. Those illustrations are concept art for the menu, not gameplay screenshots. No third-party asset pack has been imported. Candidate libraries in `PROTOTYPE_PLAN.md` remain research leads.

| Asset | Creator and source | License / use | Notes |
|---|---|---|---|
| Sedan exterior and cockpit | Maniubra prototype, `scripts/sedan.gd` | Original project work | Procedural Godot meshes/materials, including full roof shell, headliner, windshield header, wheel, dashboard, seats, hood, mirrors, and animated hand/arm visuals. |
| Streetscape kit | Maniubra prototype, `scripts/props/city_prop.gd` and `scenes/props/` | Original project work | Reusable Godot 3D scenes for sari-sari/shopfront façades, streetlamps, produce stalls with umbrellas, palms, a jeepney, and a tricycle. These are static visual props; traffic behavior is not implemented. |
| Primary Controls street | Maniubra prototype, `scripts/primary_controls.gd` | Original project work | Road, connected cross street, drivable roundabout with raised island, markings, curb/sidewalk, lighting, and placed streetscape assets. The playable lesson still follows the same seven control steps. |
| Engine and road loops | Maniubra prototype, `tools/generate_audio.py` | Original project work | Synthetic WAV files generated from source code. These are prototype sounds, not recordings of a specific vehicle. |
| Course and maneuver-card illustrations | OpenAI imagegen, generated for this project in `assets/ui/course_art/` | Generated project assets | Separate Primary, Secondary, Maneuvers, Open World, Reversing, Turning, and Lane Changing PNGs. The two user-provided images were style/composition references; menu copy, status labels, and frames are native Godot UI. |
| Current gameplay and map captures | Maniubra prototype, `docs/screenshots/primary_controls_city.png` and `docs/screenshots/roundabout_map.png` | Original project work | Rendered from the real Godot lesson and overview cameras for review; these are not concept art. |

For future external assets, add source URL, creator, exact license, required attribution, modifications, and where the asset appears. Retain source and license files with imported models. Evaluate cockpit suitability and visual style before importing a large pack.
