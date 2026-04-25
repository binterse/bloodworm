extends SceneTree

const TestSupport = preload("res://scripts/test_support.gd")

func _init() -> void:
	var game: Node = TestSupport.instantiate_game(self)
	if game == null:
		return

	await process_frame

	var corner_snake: Array[Vector2i] = [Vector2i(7, 7), Vector2i(6, 7), Vector2i(6, 8), Vector2i(6, 9)]
	game.call("debug_set_snake_state", corner_snake, Vector2i.RIGHT)
	var corner_summary: Dictionary = game.call("debug_snake_render_summary")
	if not TestSupport.assert_true(self, int(corner_summary["first_run_sample_count"]) > int(corner_summary["first_run_raw_count"]), "Rounded snake corners should create extra smoothed samples across a bend"):
		return

	TestSupport.setup_wrap_snake_case(game)
	var wrap_summary: Dictionary = game.call("debug_snake_render_summary")
	if not TestSupport.assert_true(self, int(wrap_summary["run_count"]) == 2, "Wrapped snake runs should remain visually separated"):
		return

	TestSupport.setup_growth_case(game)
	game.call("step_snake")
	var crush_summary: Dictionary = game.call("debug_snake_render_summary")
	if not TestSupport.assert_true(self, float(crush_summary["expression_timer"]) > 0.0, "Crushing a human should activate the snake facial expression timer"):
		return
	if not TestSupport.assert_true(self, str(crush_summary["expression_mode"]) == "crush", "Crushing a human should switch the snake face into crush expression mode"):
		return

	print("Snake visual test passed.")
	quit(0)
