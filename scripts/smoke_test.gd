extends SceneTree

func _init() -> void:
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	if game_scene == null:
		push_error("Failed to load game scene")
		quit(1)
		return

	var game: Node = game_scene.instantiate()
	root.add_child(game)
	await process_frame

	if not game.has_method("debug_board_ascii"):
		push_error("Game scene missing debug_board_ascii helper")
		quit(1)
		return

	print("=== Initial Board ===")
	print(game.call("debug_board_ascii"))

	var before_people: int = int(game.get("people_cells").size())
	var before_length: int = int(game.get("snake").size())
	if before_people < 1:
		push_error("Expected at least one person at startup")
		quit(1)
		return

	game.call("kill_person_at", 0, true)
	var after_people: int = int(game.get("people_cells").size())
	if after_people != before_people + 1:
		push_error("Expected person death to net +1 human (remove one, spawn two)")
		quit(1)
		return

	print("Reproduction check passed: %d -> %d" % [before_people, after_people])

	var forced_snake: Array[Vector2i] = [Vector2i(3, 3), Vector2i(2, 3), Vector2i(1, 3)]
	var forced_people: Array[Vector2i] = [Vector2i(4, 3)]
	var forced_types: Array[String] = ["man"]
	game.set("snake", forced_snake)
	game.set("direction", Vector2i.RIGHT)
	game.set("queued_direction", Vector2i.RIGHT)
	game.set("grow_pending", 0)
	game.set("people_cells", forced_people)
	game.set("people_types", forced_types)
	print("=== Growth Setup Board ===")
	print(game.call("debug_board_ascii"))
	game.call("step_snake")
	var after_growth_length: int = int(game.get("snake").size())
	print("=== Growth Result Board ===")
	print(game.call("debug_board_ascii"))
	print("Growth lengths: %d -> %d" % [before_length, after_growth_length])
	if after_growth_length != before_length + 1:
		push_error("Expected snake to grow by 1 after crushing a person")
		quit(1)
		return

	print("Growth check passed: %d -> %d" % [before_length, after_growth_length])

	var maniac_snake: Array[Vector2i] = [Vector2i(5, 5), Vector2i(4, 5), Vector2i(3, 5)]
	var empty_people: Array[Vector2i] = []
	var empty_types: Array[String] = []
	var empty_people_cooldowns: Array[float] = []
	var test_maniac: Array[Vector2i] = [Vector2i(6, 5)]
	var test_maniac_cooldowns: Array[float] = [0.0]
	game.call("debug_set_snake_state", maniac_snake, Vector2i.RIGHT)
	game.call("debug_set_people_state", empty_people, empty_types, empty_people_cooldowns)
	game.call("debug_set_maniac_state", test_maniac, test_maniac_cooldowns)
	game.set("score", 0)
	game.set("grow_pending", 0)
	game.call("step_snake")
	if int(game.get("score")) != 5:
		push_error("Expected chainsaw maniac crush to award 5 points")
		quit(1)
		return
	if game.get("snake").size() != 4:
		push_error("Expected chainsaw maniac crush to grow the snake by 1")
		quit(1)
		return
	if game.get("people_cells").size() != 2:
		push_error("Expected chainsaw maniac crush to spawn 2 humans")
		quit(1)
		return

	print("Maniac crush check passed: +5 score, +1 length, +2 humans")

	var empty_maniacs: Array[Vector2i] = []
	var empty_cooldowns: Array[float] = []
	game.call("debug_set_maniac_state", empty_maniacs, empty_cooldowns)
	game.set("maniac_has_appeared", false)
	game.set("regular_people_spawned", 19)
	game.call("spawn_regular_person")
	if game.get("maniac_cells").size() < 1:
		push_error("Expected chainsaw maniac to appear by the 20th regular person")
		quit(1)
		return

	print("Maniac guarantee check passed by spawn %d" % int(game.get("regular_people_spawned")))

	for i in range(10):
		game.call("step_snake")
		if bool(game.get("game_over")):
			push_error("Unexpected early game over in smoke test on step %d" % (i + 1))
			quit(1)
			return

	print("=== Board After 10 Snake Steps ===")
	print(game.call("debug_board_ascii"))

	game.call("move_people_once")
	print("=== Board After Human Panic Move ===")
	print(game.call("debug_board_ascii"))

	print("Smoke test passed: snake growth, people, reproduction, maniac guarantee, and panic movement all active.")
	quit(0)
