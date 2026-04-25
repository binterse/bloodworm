extends SceneTree

const TestSupport = preload("res://scripts/test_support.gd")

func _init() -> void:
	var game: Node = TestSupport.instantiate_game(self)
	if game == null:
		return

	await process_frame

	TestSupport.setup_growth_case(game)
	print("=== Growth Setup ===")
	print(TestSupport.board_string(game))

	var start_length: int = int(game.get("snake").size())
	var start_score: int = int(game.get("score"))
	game.call("step_snake")

	var grown_length: int = int(game.get("snake").size())
	var grown_score: int = int(game.get("score"))
	print("=== After Crush ===")
	print(TestSupport.board_string(game))

	if not TestSupport.assert_true(self, grown_length == start_length + 1, "Snake should grow by 1 after crushing a person"):
		return
	if not TestSupport.assert_true(self, grown_score == start_score + 1, "Score should increase by 1 after crushing a person"):
		return

	game.set("queued_direction", Vector2i.RIGHT)
	game.call("step_snake")
	var retained_length: int = int(game.get("snake").size())
	print("=== After Follow-up Move ===")
	print(TestSupport.board_string(game))

	if not TestSupport.assert_true(self, retained_length == grown_length, "Snake should keep its new length on the next non-crushing move"):
		return
	if not TestSupport.assert_true(self, not bool(game.get("game_over")), "Growth test should not end the game"):
		return

	print("Snake growth test passed.")
	quit(0)
