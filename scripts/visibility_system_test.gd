extends SceneTree

const TestSupport = preload("res://scripts/test_support.gd")

func _init() -> void:
	var title_scene: PackedScene = load("res://scenes/title_screen.tscn")
	if title_scene == null:
		push_error("Failed to load title screen scene")
		quit(1)
		return

	var title: Control = title_scene.instantiate()
	root.add_child(title)
	await process_frame

	var title_label: Label = title.get_node("CenterContainer/TitleCard/VBoxContainer/TitleLabel")
	var subtitle_label: Label = title.get_node("CenterContainer/TitleCard/VBoxContainer/SubtitleLabel")
	var start_label: Label = title.get_node("CenterContainer/TitleCard/VBoxContainer/StartLabel")
	var wrap_panel: PanelContainer = title.get_node("CenterContainer/TitleCard/VBoxContainer/WrapPanel")
	var wrap_checkbox: CheckBox = title.get_node("CenterContainer/TitleCard/VBoxContainer/WrapPanel/WrapCheckBox")
	var exit_button: Button = title.get_node("CenterContainer/TitleCard/VBoxContainer/ButtonRow/ExitButton")

	if not TestSupport.assert_true(self, title_label.visible, "Title label should be visible"):
		return
	if not TestSupport.assert_true(self, subtitle_label.visible, "Subtitle label should be visible"):
		return
	if not TestSupport.assert_true(self, start_label.visible, "Start label should be visible"):
		return
	if not TestSupport.assert_true(self, wrap_panel.visible, "Wrap panel should be visible"):
		return
	if not TestSupport.assert_true(self, wrap_checkbox.visible, "Wrap checkbox should be visible"):
		return
	if not TestSupport.assert_true(self, exit_button.visible, "Title exit button should be visible"):
		return

	title.queue_free()
	await process_frame

	var game: Node = TestSupport.instantiate_game(self)
	if game == null:
		return

	await process_frame

	var score_label: Label = game.get_node("HUDPanel/StatsMargin/StatsRow/ScoreBox/ScoreLabel")
	var hud_panel: PanelContainer = game.get_node("HUDPanel")
	var game_over_overlay: Control = game.get_node("GameOverOverlay")
	var pause_overlay: Control = game.get_node("PauseOverlay")
	var board_string: String = TestSupport.board_string(game)
	var board_rect: Rect2 = game.call("board_rect")

	if not TestSupport.assert_true(self, score_label.visible, "Score label should be visible at game start"):
		return
	if not TestSupport.assert_true(self, not game_over_overlay.visible, "Game over overlay should be hidden at game start"):
		return
	if not TestSupport.assert_true(self, not pause_overlay.visible, "Pause overlay should be hidden at game start"):
		return
	if not TestSupport.assert_true(self, board_rect.position.y >= hud_panel.position.y + hud_panel.size.y + 12.0, "Board should start below the HUD without overlap"):
		return
	if not TestSupport.assert_true(self, board_string.contains("H"), "Board debug output should include the snake head"):
		return
	if not TestSupport.assert_true(self, board_string.contains("P"), "Board debug output should include at least one visible person"):
		return

	game.call("toggle_pause")
	if not TestSupport.assert_true(self, pause_overlay.visible, "Pause overlay should become visible when paused"):
		return
	var pause_panel: PanelContainer = game.get_node("PauseOverlay/CenterContainer/Panel")
	var viewport_size: Vector2 = game.get_viewport().get_visible_rect().size
	var pause_center: Vector2 = pause_panel.position + pause_panel.size * 0.5
	if not TestSupport.assert_true(self, pause_center.distance_to(viewport_size * 0.5) < 4.0, "Pause panel should be centered on the viewport"):
		return
	game.call("resume_game")
	if not TestSupport.assert_true(self, not pause_overlay.visible, "Pause overlay should hide when resumed"):
		return

	TestSupport.setup_wrap_snake_case(game)
	if not TestSupport.assert_true(self, not bool(game.call("are_screen_neighbors", Vector2i(0, 4), Vector2i(23, 4))), "Wrapped snake segments should not be treated as adjacent for screen drawing"):
		return

	game.call("trigger_game_over")
	if not TestSupport.assert_true(self, game_over_overlay.visible, "Game over overlay should become visible after losing"):
		return

	print("Visibility system test passed.")
	quit(0)
