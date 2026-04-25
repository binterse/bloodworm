extends SceneTree

const TestSupport = preload("res://scripts/test_support.gd")

func _init() -> void:
	var game: Node = TestSupport.instantiate_game(self)
	if game == null:
		return

	await process_frame

	var people: Array[Vector2i] = [Vector2i(6, 6), Vector2i(9, 9), Vector2i(12, 12)]
	var types: Array[String] = ["man", "woman", "grandpa"]
	var cooldowns: Array[float] = [0.0, 0.0, 0.0]
	game.call("debug_set_people_state", people, types, cooldowns)
	game.set("score", 7)

	var exploded: bool = bool(game.call("maybe_trigger_random_human_explosion", true))
	if not TestSupport.assert_true(self, exploded, "Forced human explosion should report success"):
		return
	if not TestSupport.assert_true(self, game.get("people_cells").size() == 2, "Human explosion should remove exactly one human"):
		return
	if not TestSupport.assert_true(self, int(game.get("score")) == 7, "Human explosion should not award player points"):
		return
	if not TestSupport.assert_true(self, game.get("splat_cells").size() >= 1, "Human explosion should leave a blood splat"):
		return

	print("Explosion system test passed.")
	quit(0)
