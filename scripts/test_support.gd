extends RefCounted
class_name TestSupport

static func instantiate_game(tree: SceneTree) -> Node:
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	if game_scene == null:
		push_error("Failed to load game scene")
		tree.quit(1)
		return null

	var game: Node = game_scene.instantiate()
	tree.root.add_child(game)
	return game

static func assert_true(tree: SceneTree, condition: bool, message: String) -> bool:
	if condition:
		return true

	push_error(message)
	tree.quit(1)
	return false

static func setup_growth_case(game: Node) -> void:
	var forced_snake: Array[Vector2i] = [Vector2i(3, 3), Vector2i(2, 3), Vector2i(1, 3)]
	var forced_people: Array[Vector2i] = [Vector2i(4, 3)]
	var forced_types: Array[String] = ["man"]
	var forced_cooldowns: Array[float] = [0.0]

	game.call("debug_set_snake_state", forced_snake, Vector2i.RIGHT)
	game.set("grow_pending", 0)
	game.call("debug_set_people_state", forced_people, forced_types, forced_cooldowns)
	game.set("game_over", false)

static func setup_wrap_snake_case(game: Node) -> void:
	var wrapped_snake: Array[Vector2i] = [Vector2i(0, 4), Vector2i(23, 4), Vector2i(22, 4)]
	game.call("debug_set_snake_state", wrapped_snake, Vector2i.RIGHT)
	game.set("wrap_walls", true)
	game.set("game_over", false)

static func board_string(game: Node) -> String:
	if game.has_method("debug_board_ascii"):
		return str(game.call("debug_board_ascii"))
	return "<no debug board>"
