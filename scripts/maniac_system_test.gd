extends SceneTree

const TestSupport = preload("res://scripts/test_support.gd")
const GRID_SIZE := Vector2i(24, 16)

func _init() -> void:
	var game: Node = TestSupport.instantiate_game(self)
	if game == null:
		return

	await process_frame

	var snake_case: Array[Vector2i] = [Vector2i(5, 5), Vector2i(4, 5), Vector2i(3, 5)]
	var empty_people: Array[Vector2i] = []
	var empty_types: Array[String] = []
	var empty_people_cooldowns: Array[float] = []
	game.call("debug_set_snake_state", snake_case, Vector2i.RIGHT)
	game.set("grow_pending", 0)
	game.call("debug_set_people_state", empty_people, empty_types, empty_people_cooldowns)
	var target_maniacs: Array[Vector2i] = [Vector2i(6, 5)]
	var target_cooldowns: Array[float] = [0.0]
	game.call("debug_set_maniac_state", target_maniacs, target_cooldowns)
	game.set("score", 0)
	game.set("game_over", false)
	game.call("step_snake")

	if not TestSupport.assert_true(self, game.get("maniac_cells").size() == 0, "Crushed maniac should be removed immediately"):
		return
	if not TestSupport.assert_true(self, int(game.get("score")) == 5, "Crushing a chainsaw maniac should award 5 points"):
		return
	if not TestSupport.assert_true(self, game.get("people_cells").size() == 2, "Crushing a chainsaw maniac should spawn two people"):
		return
	if not TestSupport.assert_true(self, game.get("snake").size() == 4, "Crushing a chainsaw maniac should grow the snake by 1"):
		return
	if not TestSupport.assert_true(self, not bool(game.get("game_over")), "Crushing a maniac should not end the game"):
		return

	var victim_people: Array[Vector2i] = [Vector2i(8, 8)]
	var victim_types: Array[String] = ["woman"]
	var victim_cooldowns: Array[float] = [0.0]
	var hunter_maniacs: Array[Vector2i] = [Vector2i(8, 7)]
	var hunter_cooldowns: Array[float] = [0.0]
	game.call("debug_set_snake_state", snake_case, Vector2i.RIGHT)
	game.call("debug_set_people_state", victim_people, victim_types, victim_cooldowns)
	game.call("debug_set_maniac_state", hunter_maniacs, hunter_cooldowns)
	game.set("score", 10)
	game.call("kill_person_at", 0, false)
	if not TestSupport.assert_true(self, int(game.get("score")) == 10, "Chainsaw kills should not award player points"):
		return
	if not TestSupport.assert_true(self, game.get("people_cells").size() == 0, "Chainsaw kills should not spawn replacement people"):
		return

	var capped_maniacs: Array[Vector2i] = [Vector2i(10, 1), Vector2i(11, 1), Vector2i(12, 1)]
	var capped_cooldowns: Array[float] = [0.0, 0.0, 0.0]
	game.call("debug_set_maniac_state", capped_maniacs, capped_cooldowns)
	game.call("spawn_maniac")
	if not TestSupport.assert_true(self, game.get("maniac_cells").size() == 3, "There should never be more than 3 maniacs at once"):
		return

	var full_people: Array[Vector2i] = []
	var full_types: Array[String] = []
	for x in range(GRID_SIZE.x):
		for y in range(GRID_SIZE.y):
			var cell := Vector2i(x, y)
			if snake_case.has(cell):
				continue
			full_people.append(cell)
			full_types.append("man")

	var full_cooldowns: Array[float] = []
	for i in range(full_people.size()):
		full_cooldowns.append(0.0)
	var empty_maniacs: Array[Vector2i] = []
	var empty_cooldowns: Array[float] = []
	game.call("debug_set_snake_state", snake_case, Vector2i.RIGHT)
	game.call("debug_set_people_state", full_people, full_types, full_cooldowns)
	game.call("debug_set_maniac_state", empty_maniacs, empty_cooldowns)
	game.set("game_over", false)
	game.call("spawn_regular_person")

	if not TestSupport.assert_true(self, not bool(game.get("game_over")), "Full board pressure should not trigger game over"):
		return
	if not TestSupport.assert_true(self, game.get("maniac_cells").size() == 1, "Full board without maniacs should promote exactly one chainsaw maniac"):
		return

	print("Maniac system test passed.")
	quit(0)
