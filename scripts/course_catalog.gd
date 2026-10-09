extends RefCounted
## Stable course/lesson IDs. Keep curriculum data separate from UI and gameplay.

const COURSES = [
	{
		"id": "primary_controls",
		"title": "1. Primary Controls",
		"description": "Learn to operate a manual vehicle from the driver's seat.",
		"lessons": [
			{"id": "manual_basics", "title": "Manual driving basics", "objective": "Practice steering, accelerator, brake, clutch, manual gears, and handbrake. Combine them to move, shift, stop, and reverse.", "scene_path": "res://scenes/lessons/primary_controls.tscn"},
		],
	},
	{
		"id": "secondary_controls",
		"title": "2. Secondary Controls",
		"description": "Learn the supporting controls and when to use them.",
		"lessons": [
			{"id": "secondary_basics", "title": "Signals, lights, and other controls", "objective": "Practice turn signals, headlights, windshield wipers, horn, and hazard lights in relevant situations."},
		],
	},
	{
		"id": "maneuvers",
		"title": "3. Maneuvers",
		"description": "Choose one maneuver for focused practice.",
		"lessons": [
			{"id": "parking", "title": "Parking — Backing with Guide", "objective": "Reverse into a marked bay, straighten, stop fully inside, and secure the car.", "briefing": "Start beside the wide yellow bay. Follow the centered goal, reason and one action at a time. Check your mirrors and surroundings before backing; the small bay view helps you judge position. Move at walking pace, turn right in reverse, straighten, stop fully inside, then select neutral and hold the handbrake for two seconds. This is guided practice, not a timed test.", "scene_path": "res://scenes/lessons/backing_parking.tscn"},
			{"id": "reversing", "title": "Reversing", "objective": "Observe the surroundings and reverse with controlled speed and positioning."},
			{"id": "left_turn", "title": "Left Turn", "objective": "Select the appropriate lane, signal, yield, and make a permitted left turn."},
			{"id": "right_turn", "title": "Right Turn", "objective": "Observe signals and restrictions, check the surroundings, and make a permitted right turn."},
			{"id": "u_turn", "title": "U-turn", "objective": "Identify a permitted location and complete a U-turn with appropriate observation and yielding."},
			{"id": "lane_changing", "title": "Lane Changing", "objective": "Check the surrounding traffic, signal, and move into an available lane safely."},
			{"id": "merging", "title": "Merging", "objective": "Select a suitable gap and adjust speed and position to join traffic."},
			{"id": "overtaking", "title": "Overtaking", "objective": "Check markings, signs, and traffic before completing a permitted overtaking maneuver."},
			{"id": "lane_positioning", "title": "Lane Positioning", "objective": "Maintain an appropriate position within the permitted lane and available road space."},
		],
	},
	{
		"id": "open_world",
		"title": "4. Open World — Philippine Roads",
		"description": "Apply the lessons in a connected district with varied road situations.",
		"lessons": [
			{"id": "philippine_roads", "title": "Explore Iloilo", "objective": "Drive freely through Iloilo-inspired streets. Molo Plaza is an optional destination; stopping there earns a badge.", "scene_path": "res://scenes/lessons/open_world.tscn"},
			{"id": "trailer_market", "title": "Trailer Scenario — Palengke", "objective": "Drive through a compact, crowded Filipino market. Watch for shoppers, stalls narrowing both lanes, jeepneys, tricycles, and approaching motorcycles when counterflowing.", "briefing": "Explore the market loop at your own pace. Stalls take part of the lane, shoppers visit vendors, and jeepneys and tricycles make stops. Keep to your side of the road; counterflow can bring a fast oncoming motorcycle. End the drive from pause to review incidents.", "scene_path": "res://scenes/lessons/trailer_scenario.tscn"},
		],
	},
]


static func get_courses() -> Array:
	return COURSES.duplicate(true)


static func get_course(course_id: String) -> Dictionary:
	for course in COURSES:
		if course["id"] == course_id:
			return course.duplicate(true)
	return {}


static func get_lesson(course_id: String, lesson_id: String) -> Dictionary:
	var course := get_course(course_id)
	for lesson in course.get("lessons", []):
		if lesson["id"] == lesson_id:
			return lesson.duplicate(true)
	return {}
