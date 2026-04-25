extends Control

@onready var wrap_checkbox: CheckBox = $CenterContainer/TitleCard/VBoxContainer/WrapPanel/WrapCheckBox
@onready var start_button: Button = $CenterContainer/TitleCard/VBoxContainer/ButtonRow/StartButton
@onready var exit_button: Button = $CenterContainer/TitleCard/VBoxContainer/ButtonRow/ExitButton

func _ready() -> void:
	start_button.pressed.connect(_start_game)
	exit_button.pressed.connect(_exit_game)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_start_game()

func _start_game() -> void:
	get_tree().root.set_meta("wrap_walls", wrap_checkbox.button_pressed)
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _exit_game() -> void:
	get_tree().quit()
