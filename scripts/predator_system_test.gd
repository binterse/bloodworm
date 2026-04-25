extends SceneTree

const TestSupport = preload("res://scripts/test_support.gd")

func _init() -> void:
	var game: Node = TestSupport.instantiate_game(self)
	if game == null:
		return

	await process_frame

	var shooter_people: Array[Vector2i] = [Vector2i(5, 5), Vector2i(8, 5)]
	var shooter_types: Array[String] = ["man", "woman"]
	var shooter_cooldowns: Array[float] = [0.0, 0.0]
	var shooter_flags: Array[bool] = [true, false]
	game.call("debug_set_people_state", shooter_people, shooter_types, shooter_cooldowns, shooter_flags)
	game.set("score", 9)
	var fired: bool = bool(game.call("maybe_trigger_human_gunfire", true))
	if not TestSupport.assert_true(self, fired, "Armed humans should be able to force a gunshot event"):
		return
	if not TestSupport.assert_true(self, game.get("people_cells").size() == 1, "Human gunfire should remove the target human"):
		return
	if not TestSupport.assert_true(self, int(game.get("score")) == 9, "Human gunfire should not award player points"):
		return
	if not TestSupport.assert_true(self, game.get("shot_trace_timers").size() == 1, "Human gunfire should create a visible shot trace"):
		return

	var raptor_people: Array[Vector2i] = [Vector2i(10, 6)]
	var raptor_types: Array[String] = ["grandpa"]
	var raptor_cooldowns: Array[float] = [0.0]
	var raptor_flags: Array[bool] = [false]
	game.call("debug_set_people_state", raptor_people, raptor_types, raptor_cooldowns, raptor_flags)
	var small_snake: Array[Vector2i] = [Vector2i(3, 3), Vector2i(2, 3), Vector2i(1, 3)]
	game.call("debug_set_snake_state", small_snake, Vector2i.RIGHT)
	game.call("debug_set_raptor_state", true, Vector2i(9, 6), 6)
	game.call("move_raptor_once")
	if not TestSupport.assert_true(self, game.get("people_cells").size() == 0, "Velociraptor should eat a human when it reaches the cell"):
		return

	var snake_case: Array[Vector2i] = [Vector2i(8, 8), Vector2i(7, 8), Vector2i(6, 8), Vector2i(5, 8), Vector2i(4, 8)]
	var empty_people: Array[Vector2i] = []
	var empty_types: Array[String] = []
	var empty_cooldowns: Array[float] = []
	var empty_flags: Array[bool] = []
	game.call("debug_set_snake_state", snake_case, Vector2i.RIGHT)
	game.call("debug_set_people_state", empty_people, empty_types, empty_cooldowns, empty_flags)
	game.call("debug_set_raptor_state", true, Vector2i(6, 7), 6)
	game.call("move_raptor_once")
	if not TestSupport.assert_true(self, game.get("snake").size() == 3, "Velociraptor should shorten the snake when it bites it"):
		return

	print("Predator system test passed.")
	quit(0)
