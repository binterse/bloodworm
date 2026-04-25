extends SceneTree

const TestSupport = preload("res://scripts/test_support.gd")

func _init() -> void:
	var game: Node = TestSupport.instantiate_game(self)
	if game == null:
		return

	await process_frame

	TestSupport.setup_growth_case(game)
	game.call("step_snake")

	var snake_prev: Array = game.get("snake_prev_cells")
	var snake_cells: Array = game.get("snake")
	if not TestSupport.assert_true(self, snake_prev.size() == snake_cells.size(), "Snake animation buffer should track snake length"):
		return
	if not TestSupport.assert_true(self, snake_prev[0] == Vector2i(3, 3), "Snake head animation should begin at the previous head cell"):
		return
	if not TestSupport.assert_true(self, snake_cells[0] == Vector2i(4, 3), "Snake head should logically move to the next cell"):
		return

	game.set("snake_anim_elapsed", 0.052)
	var old_head_center: Vector2 = game.call("cell_center", Vector2i(3, 3))
	var new_head_center: Vector2 = game.call("cell_center", Vector2i(4, 3))
	var animated_head_center: Vector2 = game.call("snake_segment_center", 0)
	if not TestSupport.assert_true(self, animated_head_center.x > old_head_center.x and animated_head_center.x < new_head_center.x, "Snake head should draw between grid cells during movement"):
		return

	var old_people: Array[Vector2i] = [Vector2i(5, 5)]
	var new_people: Array[Vector2i] = [Vector2i(6, 5)]
	var person_types: Array[String] = ["woman"]
	var person_cooldowns: Array[float] = [0.0]
	game.call("debug_set_people_state", new_people, person_types, person_cooldowns)
	game.call("start_people_animation", old_people)
	game.set("people_anim_elapsed", 0.36)

	var old_person_center: Vector2 = game.call("cell_center", Vector2i(5, 5))
	var new_person_center: Vector2 = game.call("cell_center", Vector2i(6, 5))
	var animated_person_center: Vector2 = game.call("person_center", 0)
	if not TestSupport.assert_true(self, animated_person_center.x > old_person_center.x and animated_person_center.x < new_person_center.x, "People should draw between grid cells while walking"):
		return

	var stagger_people: Array[Vector2i] = [Vector2i(7, 7)]
	var stagger_types: Array[String] = ["man"]
	var stagger_maniacs: Array[Vector2i] = [Vector2i(8, 7)]
	var stagger_people_cooldowns: Array[float] = [0.0]
	var stagger_cooldowns: Array[float] = [0.0]
	game.call("debug_set_people_state", stagger_people, stagger_types, stagger_people_cooldowns)
	game.call("debug_set_maniac_state", stagger_maniacs, stagger_cooldowns)
	game.set("ai_phase_timer", 1.0)
	game.set("pending_maniac_phase", false)
	game.set("pending_maniac_delay", 0.0)

	game.call("update_ai_system", 0.0)
	var stagger_after: Array = game.get("maniac_cells")
	if not TestSupport.assert_true(self, bool(game.get("pending_maniac_phase")), "People and maniacs should be split into separate AI subphases"):
		return
	if not TestSupport.assert_true(self, stagger_after[0] == Vector2i(8, 7), "Maniacs should not move on the same frame as people"):
		return
	if not TestSupport.assert_true(self, float(game.get("people_anim_elapsed")) == 0.0, "Human walk animation should start immediately on the human subphase"):
		return
	var maniac_anim_before: Array = game.get("maniac_anim_elapsed")
	if not TestSupport.assert_true(self, float(maniac_anim_before[0]) > 0.0, "Maniac walk animation should not start until the delayed maniac subphase"):
		return

	game.call("update_ai_system", 0.80)
	var maniac_anim_after: Array = game.get("maniac_anim_elapsed")
	if not TestSupport.assert_true(self, not bool(game.get("pending_maniac_phase")), "Pending maniac phase should clear after the human animation window finishes"):
		return
	if not TestSupport.assert_true(self, float(maniac_anim_after[0]) == 0.0, "Maniac walk animation should begin only after the delayed subphase starts"):
		return

	var cooldown_source: Array[Vector2i] = [Vector2i(10, 10)]
	var cooldown_types: Array[String] = ["grandpa"]
	var cooldowns: Array[float] = [0.0]
	game.call("debug_set_people_state", cooldown_source, cooldown_types, cooldowns)
	game.call("run_people_phase")
	var refreshed_cooldowns: Array = game.get("people_move_cooldowns")
	if not TestSupport.assert_true(self, float(refreshed_cooldowns[0]) >= 2.0 and float(refreshed_cooldowns[0]) <= 3.5, "Human cooldowns should reset to the new 2.0-3.5 second range"):
		return

	var maniac_phase_cells: Array[Vector2i] = [Vector2i(12, 12)]
	var maniac_phase_cooldowns: Array[float] = [999.0]
	var maniac_target_people: Array[Vector2i] = [Vector2i(13, 12)]
	var maniac_target_types: Array[String] = ["man"]
	var maniac_target_cooldowns: Array[float] = [2.5]
	game.call("debug_set_people_state", maniac_target_people, maniac_target_types, maniac_target_cooldowns)
	game.call("debug_set_maniac_state", maniac_phase_cells, maniac_phase_cooldowns)
	game.call("run_maniac_phase")
	var forced_phase_anim: Array = game.get("maniac_anim_elapsed")
	if not TestSupport.assert_true(self, float(forced_phase_anim[0]) == 0.0, "Maniacs should still act on their one-second phase even without a human-style cooldown expiring"):
		return

	print("Movement animation test passed.")
	quit(0)
