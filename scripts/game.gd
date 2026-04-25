extends Node2D

class SnakeRenderRun:
	var points: Array[Vector2] = []
	var widths: Array[float] = []
	var distances: Array[float] = []
	var raw_start := 0
	var raw_end := 0
	var raw_count := 0

const GRID_SIZE := Vector2i(24, 16)
const CELL_SIZE := 58
const TICK_RATE := 0.12
const START_LENGTH := 3

const AI_PHASE_INTERVAL := 1.0
const AI_MOVE_FRACTION := 0.20
const ENTITY_COOLDOWN_MIN := 2.0
const ENTITY_COOLDOWN_MAX := 3.5
const HUMAN_EXPLOSION_DENOMINATOR := 18
const PERSON_GUN_DENOMINATOR := 4
const PERSON_SHOOT_CHANCE := 0.18
const PERSON_SHOOT_RANGE := 6
const SHOT_TRACE_DURATION := 0.14
const AI_SUBPHASE_GAP := 0.08
const SNAKE_STEP_ANIM_DURATION := 0.105
const SNAKE_CORNER_ROUNDING_RATIO := 0.34
const SNAKE_CORNER_SAMPLES := 4
const SNAKE_STRAIGHT_SEGMENT_SAMPLES := 2
const SNAKE_BODY_WAVE_AMPLITUDE := 0.018
const SNAKE_TAIL_SWAY_AMPLITUDE := 0.038
const SNAKE_HEAD_SCALE := 1.24
const SNAKE_ZIG_ZAG_SPACING := 28.0
const SNAKE_ZIG_ZAG_INNER_RATIO := 0.42
const SNAKE_FACE_EXPRESSION_DURATION := 0.82
const PERSON_STEP_ANIM_DURATION := 0.68
const MANIAC_STEP_ANIM_DURATION := 0.46
const MANIAC_SPAWN_DENOMINATOR := 64
const INITIAL_PERSON_COUNT := 2
const SPLAT_DURATION := 0.95
const STAIN_DURATION := 9.5
const PERSON_RANDOM_STEP_CHANCE := 0.34
const PERSON_RANDOM_WEIGHT := 3.4
const MANIAC_RANDOM_STEP_CHANCE := 0.22
const MANIAC_RANDOM_WEIGHT := 0.95
const MANIAC_CHASE_WEIGHT := 0.92
const RAPTOR_SPAWN_MIN := 30.0
const RAPTOR_SPAWN_MAX := 30.0
const RAPTOR_ACTIVE_STEPS := 18
const RAPTOR_MOVE_INTERVAL := 0.32
const RAPTOR_MAX_HUMAN_MEALS := 4
const RAPTOR_SNAKE_BITE_SEGMENTS := 2

const PERSON_TYPES: PackedStringArray = ["man", "woman", "grandma", "grandpa"]
const CARDINAL_DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const CARDINAL_OR_STAY: Array[Vector2i] = [Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const MANIAC_GUARANTEE_SPAWN_COUNT := 20
const MAX_MANIACS := 3

var snake: Array[Vector2i] = []
var snake_prev_cells: Array[Vector2i] = []
var snake_anim_elapsed := SNAKE_STEP_ANIM_DURATION
var direction := Vector2i.RIGHT
var queued_direction := Vector2i.RIGHT
var move_timer := 0.0
var grow_pending := 0
var snake_expression_mode := "alert"
var snake_expression_timer := 0.0
var score := 0
var game_over := false
var is_paused := false

var wrap_walls := false

var people_cells: Array[Vector2i] = []
var people_prev_cells: Array[Vector2i] = []
var people_move_cooldowns: Array[float] = []
var people_types: Array[String] = []
var people_has_gun: Array[bool] = []
var people_anim_elapsed := PERSON_STEP_ANIM_DURATION

var splat_cells: Array[Vector2i] = []
var splat_timers: Array[float] = []
var splat_intensities: Array[float] = []

var stain_cells: Array[Vector2i] = []
var stain_timers: Array[float] = []
var stain_intensities: Array[float] = []

var shot_trace_starts: Array[Vector2] = []
var shot_trace_ends: Array[Vector2] = []
var shot_trace_timers: Array[float] = []

var maniac_cells: Array[Vector2i] = []
var maniac_prev_cells: Array[Vector2i] = []
var maniac_move_cooldowns: Array[float] = []
var maniac_anim_elapsed: Array[float] = []
var raptor_active := false
var raptor_cell := Vector2i.ZERO
var raptor_prev_cell := Vector2i.ZERO
var raptor_anim_elapsed := PERSON_STEP_ANIM_DURATION
var raptor_spawn_timer := 0.0
var raptor_move_timer := 0.0
var raptor_steps_remaining := 0
var raptor_humans_eaten := 0
var person_anim_time := 0.0
var regular_people_spawned := 0
var maniac_has_appeared := false
var ai_phase_timer := 0.0
var pending_maniac_phase := false
var pending_maniac_delay := 0.0

@onready var score_label: Label = $HUDPanel/StatsMargin/StatsRow/ScoreBox/ScoreLabel
@onready var people_label: Label = $HUDPanel/StatsMargin/StatsRow/PeopleBox/PeopleLabel
@onready var maniacs_label: Label = $HUDPanel/StatsMargin/StatsRow/ManiacsBox/ManiacsLabel
@onready var mode_label: Label = $HUDPanel/StatsMargin/StatsRow/ModeBox/ModeLabel
@onready var hud_panel: PanelContainer = $HUDPanel
@onready var pause_overlay: Control = $PauseOverlay
@onready var pause_center: CenterContainer = $PauseOverlay/CenterContainer
@onready var pause_panel: PanelContainer = $PauseOverlay/CenterContainer/Panel
@onready var game_over_overlay: Control = $GameOverOverlay
@onready var game_over_center: CenterContainer = $GameOverOverlay/CenterContainer
@onready var game_over_panel: PanelContainer = $GameOverOverlay/CenterContainer/Panel
@onready var game_over_label: Label = $GameOverOverlay/CenterContainer/Panel/VBoxContainer/GameOverLabel
@onready var resume_button: Button = $PauseOverlay/CenterContainer/Panel/VBoxContainer/PauseButtonRow/ResumeButton
@onready var pause_title_button: Button = $PauseOverlay/CenterContainer/Panel/VBoxContainer/PauseButtonRow/PauseTitleButton
@onready var pause_exit_button: Button = $PauseOverlay/CenterContainer/Panel/VBoxContainer/PauseButtonRow/PauseExitButton
@onready var restart_button: Button = $GameOverOverlay/CenterContainer/Panel/VBoxContainer/GameOverButtonRow/RestartButton
@onready var game_over_title_button: Button = $GameOverOverlay/CenterContainer/Panel/VBoxContainer/GameOverButtonRow/GameOverTitleButton
@onready var game_over_exit_button: Button = $GameOverOverlay/CenterContainer/Panel/VBoxContainer/GameOverButtonRow/GameOverExitButton

func _ready() -> void:
	randomize()
	resume_button.pressed.connect(resume_game)
	pause_title_button.pressed.connect(return_to_title)
	pause_exit_button.pressed.connect(quit_game)
	restart_button.pressed.connect(reset_game)
	game_over_title_button.pressed.connect(return_to_title)
	game_over_exit_button.pressed.connect(quit_game)

	wrap_walls = false
	if get_tree().root.has_meta("wrap_walls"):
		wrap_walls = bool(get_tree().root.get_meta("wrap_walls"))

	get_window().size_changed.connect(_layout_ui)
	reset_game()
	call_deferred("_layout_ui")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if game_over:
				return
			toggle_pause()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_R and game_over:
			reset_game()

func _process(delta: float) -> void:
	if game_over or is_paused:
		return

	handle_direction_input()
	person_anim_time += delta
	snake_anim_elapsed = minf(snake_anim_elapsed + delta, SNAKE_STEP_ANIM_DURATION)
	snake_expression_timer = maxf(0.0, snake_expression_timer - delta)
	if snake_expression_timer <= 0.0:
		snake_expression_mode = "alert"
	people_anim_elapsed = minf(people_anim_elapsed + delta, PERSON_STEP_ANIM_DURATION)
	for i in range(maniac_anim_elapsed.size()):
		maniac_anim_elapsed[i] = minf(maniac_anim_elapsed[i] + delta, MANIAC_STEP_ANIM_DURATION)
	raptor_anim_elapsed = minf(raptor_anim_elapsed + delta, PERSON_STEP_ANIM_DURATION)
	update_splats(delta)
	update_stains(delta)
	update_shot_traces(delta)
	update_ai_system(delta)
	update_raptor(delta)

	move_timer += delta
	while move_timer >= TICK_RATE:
		move_timer -= TICK_RATE
		step_snake()

	queue_redraw()

func reset_game() -> void:
	snake.clear()
	snake_prev_cells.clear()
	people_cells.clear()
	people_prev_cells.clear()
	people_move_cooldowns.clear()
	people_types.clear()
	people_has_gun.clear()
	splat_cells.clear()
	splat_timers.clear()
	splat_intensities.clear()
	stain_cells.clear()
	stain_timers.clear()
	stain_intensities.clear()
	shot_trace_starts.clear()
	shot_trace_ends.clear()
	shot_trace_timers.clear()
	maniac_cells.clear()
	maniac_prev_cells.clear()
	maniac_move_cooldowns.clear()
	maniac_anim_elapsed.clear()

	var center := Vector2i(GRID_SIZE.x / 2, GRID_SIZE.y / 2)
	for i in range(START_LENGTH):
		snake.append(center - Vector2i(i, 0))
	snake_prev_cells = copy_cell_array(snake)

	direction = Vector2i.RIGHT
	queued_direction = direction
	move_timer = 0.0
	snake_anim_elapsed = SNAKE_STEP_ANIM_DURATION
	snake_expression_mode = "alert"
	snake_expression_timer = 0.0
	grow_pending = 0
	people_anim_elapsed = PERSON_STEP_ANIM_DURATION
	person_anim_time = 0.0
	raptor_active = false
	raptor_cell = Vector2i.ZERO
	raptor_prev_cell = Vector2i.ZERO
	raptor_anim_elapsed = PERSON_STEP_ANIM_DURATION
	raptor_spawn_timer = random_raptor_spawn_time()
	raptor_move_timer = 0.0
	raptor_steps_remaining = 0
	raptor_humans_eaten = 0
	regular_people_spawned = 0
	maniac_has_appeared = false
	ai_phase_timer = 0.0
	pending_maniac_phase = false
	pending_maniac_delay = 0.0
	score = 0
	game_over = false
	is_paused = false
	pause_overlay.visible = false
	game_over_overlay.visible = false

	for i in range(INITIAL_PERSON_COUNT):
		spawn_regular_person()

	update_stats_ui()
	queue_redraw()

func _layout_ui() -> void:
	var viewport_size := get_viewport_rect().size
	hud_panel.position = Vector2(38, 28)
	hud_panel.size = Vector2(viewport_size.x - 76.0, 110.0)

	_place_overlay(pause_overlay, pause_center, pause_panel, viewport_size, Vector2(660, 260))
	_place_overlay(game_over_overlay, game_over_center, game_over_panel, viewport_size, Vector2(740, 300))

	queue_redraw()

func _place_overlay(overlay: Control, center: Control, panel: Control, viewport_size: Vector2, panel_size: Vector2) -> void:
	overlay.set_anchors_preset(Control.PRESET_TOP_LEFT)
	overlay.position = Vector2.ZERO
	overlay.size = viewport_size
	center.set_anchors_preset(Control.PRESET_TOP_LEFT)
	center.position = Vector2.ZERO
	center.size = viewport_size
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.custom_minimum_size = panel_size
	panel.size = panel_size
	panel.position = (viewport_size - panel_size) * 0.5

func toggle_pause() -> void:
	if game_over:
		return
	is_paused = not is_paused
	pause_overlay.visible = is_paused

func resume_game() -> void:
	is_paused = false
	pause_overlay.visible = false

func return_to_title() -> void:
	is_paused = false
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func quit_game() -> void:
	get_tree().quit()

func handle_direction_input() -> void:
	var wanted := queued_direction
	if Input.is_action_pressed("move_up"):
		wanted = Vector2i.UP
	elif Input.is_action_pressed("move_down"):
		wanted = Vector2i.DOWN
	elif Input.is_action_pressed("move_left"):
		wanted = Vector2i.LEFT
	elif Input.is_action_pressed("move_right"):
		wanted = Vector2i.RIGHT

	if wanted + direction != Vector2i.ZERO:
		queued_direction = wanted

func step_snake() -> void:
	direction = queued_direction
	var next_head := snake[0] + direction
	if wrap_walls:
		next_head = wrap_cell(next_head)
	elif is_outside(next_head):
		trigger_game_over()
		return

	var old_snake := copy_cell_array(snake)
	var tail: Vector2i = snake[snake.size() - 1]
	var eaten_idx := find_person_index_at_cell(next_head)
	var crushes_person := eaten_idx != -1
	var crushed_maniac_idx := find_maniac_index_at_cell(next_head)
	var crushes_maniac := crushed_maniac_idx != -1
	var crushes_raptor := raptor_active and next_head == raptor_cell
	var will_grow := crushes_person or crushes_maniac

	if snake.has(next_head) and (will_grow or next_head != tail):
		trigger_game_over()
		return

	snake.push_front(next_head)

	if crushes_person:
		kill_person_at(eaten_idx, true)
		grow_pending += 1
	if crushes_maniac:
		kill_maniac_at(crushed_maniac_idx)
		grow_pending += 1
	if crushes_raptor:
		despawn_raptor(true)

	if grow_pending > 0:
		grow_pending -= 1
	else:
		snake.pop_back()

	start_snake_animation(old_snake)
	queue_redraw()

func update_ai_system(delta: float) -> void:
	ensure_people_cooldowns()
	ensure_maniac_cooldowns()
	step_entity_cooldowns(delta)

	if pending_maniac_phase:
		pending_maniac_delay -= delta
		if pending_maniac_delay <= 0.0:
			pending_maniac_phase = false
			run_maniac_phase()

	ai_phase_timer += delta
	while ai_phase_timer >= AI_PHASE_INTERVAL:
		ai_phase_timer -= AI_PHASE_INTERVAL
		begin_ai_phase()

func begin_ai_phase() -> void:
	ensure_people_weapon_flags()
	maybe_trigger_random_human_explosion()
	var people_moved := run_people_phase()
	maybe_trigger_human_gunfire()
	if people_moved and not maniac_cells.is_empty():
		pending_maniac_phase = true
		pending_maniac_delay = PERSON_STEP_ANIM_DURATION + AI_SUBPHASE_GAP
	elif not maniac_cells.is_empty():
		run_maniac_phase()

func run_people_phase() -> bool:
	var selected_indices := select_phase_indices(people_move_cooldowns)
	if selected_indices.is_empty():
		return false

	move_people_subset(selected_indices)
	for idx in selected_indices:
		if idx >= 0 and idx < people_move_cooldowns.size():
			people_move_cooldowns[idx] = random_entity_cooldown()
	return true

func move_people_once() -> void:
	ensure_people_cooldowns()
	var selected_indices: Array[int] = []
	for i in range(people_cells.size()):
		selected_indices.append(i)
	move_people_subset(selected_indices)
	for idx in selected_indices:
		if idx >= 0 and idx < people_move_cooldowns.size():
			people_move_cooldowns[idx] = random_entity_cooldown()

func move_people_subset(selected_indices: Array[int]) -> void:
	if people_cells.is_empty() or selected_indices.is_empty():
		return

	ensure_people_anim_buffers()
	var old_people := copy_cell_array(people_cells)
	var occupied: Dictionary = {}
	for cell in people_cells:
		occupied[cell] = true

	selected_indices.shuffle()
	for idx in selected_indices:
		if idx < 0 or idx >= people_cells.size():
			continue
		var current_cell: Vector2i = people_cells[idx]
		var best_cell: Vector2i = current_cell
		var best_score: float = -1e9

		var directions := copy_direction_array(CARDINAL_OR_STAY)
		directions.shuffle()
		for dir: Vector2i in directions:
			var candidate: Vector2i = current_cell + dir
			if wrap_walls:
				candidate = wrap_cell(candidate)
			elif is_outside(candidate):
				continue

			if dir != Vector2i.ZERO and snake.has(candidate):
				continue
			if find_maniac_index_at_cell(candidate) != -1:
				continue
			if candidate != current_cell and occupied.has(candidate):
				continue

			var score_here: float = panic_score(candidate) + randf() * PERSON_RANDOM_WEIGHT
			if score_here > best_score:
				best_score = score_here
				best_cell = candidate

		if randf() < PERSON_RANDOM_STEP_CHANCE:
			best_cell = pick_random_person_step(current_cell, occupied)

		occupied.erase(current_cell)
		occupied[best_cell] = true
		people_cells[idx] = best_cell

	start_people_animation(old_people)
	queue_redraw()

func panic_score(cell: Vector2i) -> float:
	var head_dist := grid_distance_sq(cell, snake[0])
	var maniac_dist := 0.0
	if not maniac_cells.is_empty():
		maniac_dist = nearest_maniac_distance_sq(cell)
	return head_dist * 1.1 + maniac_dist * 0.95 + randf() * 1.7

func run_maniac_phase() -> bool:
	var selected_indices: Array[int] = []
	for i in range(maniac_cells.size()):
		selected_indices.append(i)
	if selected_indices.is_empty():
		return false

	move_maniac_subset(selected_indices)
	return true

func move_maniac_once(index: int) -> void:
	var selected_indices: Array[int] = [index]
	move_maniac_subset(selected_indices)

func move_maniac_subset(selected_indices: Array[int]) -> void:
	if maniac_cells.is_empty() or selected_indices.is_empty():
		return

	ensure_maniac_anim_buffers()
	var occupied: Dictionary = {}
	for i in range(maniac_cells.size()):
		occupied[maniac_cells[i]] = i

	selected_indices.shuffle()
	for index in selected_indices:
		if index < 0 or index >= maniac_cells.size():
			continue

		var current_cell: Vector2i = maniac_cells[index]
		var target: Vector2i = choose_maniac_target(current_cell)
		var best_cell: Vector2i = current_cell
		var best_score: float = 1e9
		var valid_steps: Array[Vector2i] = []

		var directions := copy_direction_array(CARDINAL_OR_STAY)
		directions.shuffle()
		for dir: Vector2i in directions:
			var candidate: Vector2i = current_cell + dir
			if wrap_walls:
				candidate = wrap_cell(candidate)
			elif is_outside(candidate):
				continue

			if snake.has(candidate):
				continue
			if occupied.has(candidate) and int(occupied[candidate]) != index:
				continue

			var chase_score: float = grid_distance_sq(candidate, target) * MANIAC_CHASE_WEIGHT + randf() * MANIAC_RANDOM_WEIGHT
			valid_steps.append(candidate)
			if chase_score < best_score:
				best_score = chase_score
				best_cell = candidate

		if not valid_steps.is_empty() and randf() < MANIAC_RANDOM_STEP_CHANCE:
			best_cell = valid_steps[randi() % valid_steps.size()]

		occupied.erase(current_cell)
		occupied[best_cell] = index
		maniac_cells[index] = best_cell
		start_maniac_animation(index, current_cell, best_cell)

		var victim_idx := find_person_index_at_cell(best_cell)
		if victim_idx != -1:
			kill_person_at(victim_idx, false)

	queue_redraw()

func choose_maniac_target(current_cell: Vector2i) -> Vector2i:
	if people_cells.is_empty():
		return snake[0]

	var best_cell: Vector2i = people_cells[0]
	var best_dist: float = grid_distance_sq(current_cell, best_cell)
	for cell in people_cells:
		var dist: float = grid_distance_sq(current_cell, cell)
		if dist < best_dist:
			best_dist = dist
			best_cell = cell
	return best_cell

func kill_person_at(index: int, by_snake: bool, splat_intensity: float = 1.1) -> void:
	if index < 0 or index >= people_cells.size():
		return

	ensure_people_anim_buffers()
	ensure_people_cooldowns()
	ensure_people_weapon_flags()
	var dead_cell: Vector2i = people_cells[index]
	people_cells.remove_at(index)
	people_prev_cells.remove_at(index)
	people_move_cooldowns.remove_at(index)
	people_types.remove_at(index)
	if index < people_has_gun.size():
		people_has_gun.remove_at(index)
	add_splat(dead_cell, splat_intensity)

	if by_snake:
		snake_expression_mode = "crush"
		snake_expression_timer = SNAKE_FACE_EXPRESSION_DURATION
		score += 1
		spawn_regular_person()
		spawn_regular_person()
	update_stats_ui()

func maybe_trigger_random_human_explosion(force: bool = false) -> bool:
	if people_cells.is_empty():
		return false
	if not force and people_cells.size() <= 1:
		return false
	if not force and randi() % HUMAN_EXPLOSION_DENOMINATOR != 0:
		return false

	var victim_idx := randi() % people_cells.size()
	kill_person_at(victim_idx, false, 2.2)
	return true

func kill_maniac_at(index: int) -> void:
	if index < 0 or index >= maniac_cells.size():
		return

	ensure_maniac_anim_buffers()
	ensure_maniac_cooldowns()
	var dead_cell: Vector2i = maniac_cells[index]
	maniac_cells.remove_at(index)
	maniac_prev_cells.remove_at(index)
	maniac_move_cooldowns.remove_at(index)
	maniac_anim_elapsed.remove_at(index)
	score += 5
	add_splat(dead_cell, 2.0)
	spawn_regular_person(false)
	spawn_regular_person(false)
	update_stats_ui()

func add_splat(cell: Vector2i, intensity: float) -> void:
	splat_cells.append(cell)
	splat_timers.append(SPLAT_DURATION)
	splat_intensities.append(intensity)
	stain_cells.append(cell)
	stain_timers.append(STAIN_DURATION)
	stain_intensities.append(intensity)

func update_splats(delta: float) -> void:
	for i in range(splat_timers.size() - 1, -1, -1):
		splat_timers[i] -= delta
		if splat_timers[i] <= 0.0:
			splat_timers.remove_at(i)
			splat_cells.remove_at(i)
			splat_intensities.remove_at(i)

func update_stains(delta: float) -> void:
	for i in range(stain_timers.size() - 1, -1, -1):
		stain_timers[i] -= delta
		if stain_timers[i] <= 0.0:
			stain_timers.remove_at(i)
			stain_cells.remove_at(i)
			stain_intensities.remove_at(i)

func update_shot_traces(delta: float) -> void:
	for i in range(shot_trace_timers.size() - 1, -1, -1):
		shot_trace_timers[i] -= delta
		if shot_trace_timers[i] <= 0.0:
			shot_trace_timers.remove_at(i)
			shot_trace_starts.remove_at(i)
			shot_trace_ends.remove_at(i)

func spawn_regular_person(allow_maniac_roll: bool = true) -> bool:
	ensure_people_anim_buffers()
	ensure_people_cooldowns()
	var open_cells: Array[Vector2i] = get_open_cells()
	if open_cells.is_empty():
		handle_full_board_pressure()
		return false

	var spawn_cell: Vector2i = open_cells[randi() % open_cells.size()]
	var person_kind: String = PERSON_TYPES[randi() % PERSON_TYPES.size()]
	people_cells.append(spawn_cell)
	people_prev_cells.append(spawn_cell)
	people_move_cooldowns.append(random_entity_cooldown())
	people_types.append(person_kind)
	people_has_gun.append(randi() % PERSON_GUN_DENOMINATOR == 0)
	regular_people_spawned += 1
	if allow_maniac_roll:
		consider_maniac_spawn()
	return true

func consider_maniac_spawn() -> void:
	if maniac_cells.size() >= MAX_MANIACS:
		return

	if (not maniac_has_appeared and regular_people_spawned >= MANIAC_GUARANTEE_SPAWN_COUNT) or randi() % MANIAC_SPAWN_DENOMINATOR == 0:
		spawn_maniac()

func spawn_maniac() -> bool:
	if maniac_cells.size() >= MAX_MANIACS:
		return false

	ensure_maniac_anim_buffers()
	ensure_maniac_cooldowns()
	var open_cells: Array[Vector2i] = get_open_cells()
	if open_cells.is_empty():
		return false

	maniac_has_appeared = true
	var spawn_cell: Vector2i = open_cells[randi() % open_cells.size()]
	maniac_cells.append(spawn_cell)
	maniac_prev_cells.append(spawn_cell)
	maniac_move_cooldowns.append(0.0)
	maniac_anim_elapsed.append(MANIAC_STEP_ANIM_DURATION)
	update_stats_ui()
	return true

func handle_full_board_pressure() -> void:
	if maniac_cells.is_empty():
		spawn_pressure_maniac()
	update_stats_ui()

func spawn_pressure_maniac() -> bool:
	if maniac_cells.size() >= MAX_MANIACS or people_cells.is_empty():
		return false

	ensure_people_anim_buffers()
	ensure_people_cooldowns()
	ensure_maniac_anim_buffers()
	ensure_maniac_cooldowns()
	var source_idx: int = randi() % people_cells.size()
	var source_cell: Vector2i = people_cells[source_idx]
	people_cells.remove_at(source_idx)
	people_prev_cells.remove_at(source_idx)
	people_move_cooldowns.remove_at(source_idx)
	people_types.remove_at(source_idx)
	people_has_gun.remove_at(source_idx)
	maniac_cells.append(source_cell)
	maniac_prev_cells.append(source_cell)
	maniac_move_cooldowns.append(0.0)
	maniac_anim_elapsed.append(MANIAC_STEP_ANIM_DURATION)
	maniac_has_appeared = true
	return true

func get_open_cells() -> Array[Vector2i]:
	var open_cells: Array[Vector2i] = []
	for x in range(GRID_SIZE.x):
		for y in range(GRID_SIZE.y):
			var cell := Vector2i(x, y)
			if snake.has(cell):
				continue
			if find_person_index_at_cell(cell) != -1:
				continue
			if find_maniac_index_at_cell(cell) != -1:
				continue
			if raptor_active and cell == raptor_cell:
				continue
			open_cells.append(cell)
	return open_cells

func find_person_index_at_cell(cell: Vector2i) -> int:
	for i in range(people_cells.size()):
		if people_cells[i] == cell:
			return i
	return -1

func find_maniac_index_at_cell(cell: Vector2i) -> int:
	for i in range(maniac_cells.size()):
		if maniac_cells[i] == cell:
			return i
	return -1

func nearest_maniac_distance_sq(cell: Vector2i) -> float:
	var best_dist: float = grid_distance_sq(cell, maniac_cells[0])
	for i in range(1, maniac_cells.size()):
		best_dist = minf(best_dist, grid_distance_sq(cell, maniac_cells[i]))
	return best_dist

func maybe_trigger_human_gunfire(force: bool = false) -> bool:
	if people_cells.size() < 2:
		return false

	var armed_indices: Array[int] = []
	for i in range(people_has_gun.size()):
		if people_has_gun[i]:
			armed_indices.append(i)
	armed_indices.shuffle()

	for shooter_idx in armed_indices:
		if shooter_idx < 0 or shooter_idx >= people_cells.size():
			continue
		if not force and randf() > PERSON_SHOOT_CHANCE:
			continue
		var target_idx := choose_gun_target(shooter_idx)
		if target_idx == -1:
			continue
		add_shot_trace(person_center(shooter_idx), person_center(target_idx))
		kill_person_at(target_idx, false, 1.4)
		return true
	return false

func choose_gun_target(shooter_idx: int) -> int:
	if shooter_idx < 0 or shooter_idx >= people_cells.size():
		return -1

	var shooter_cell: Vector2i = people_cells[shooter_idx]
	var best_idx := -1
	var best_dist := 999
	for i in range(people_cells.size()):
		if i == shooter_idx:
			continue
		var target_cell: Vector2i = people_cells[i]
		var same_row_or_column := target_cell.x == shooter_cell.x or target_cell.y == shooter_cell.y
		if not same_row_or_column:
			continue
		var dist := absi(target_cell.x - shooter_cell.x) + absi(target_cell.y - shooter_cell.y)
		if dist > PERSON_SHOOT_RANGE or dist >= best_dist:
			continue
		if not is_shot_path_clear(shooter_cell, target_cell):
			continue
		best_dist = dist
		best_idx = i
	return best_idx

func is_shot_path_clear(from_cell: Vector2i, to_cell: Vector2i) -> bool:
	var step := Vector2i.ZERO
	if from_cell.x == to_cell.x:
		step = Vector2i(0, signi(to_cell.y - from_cell.y))
	elif from_cell.y == to_cell.y:
		step = Vector2i(signi(to_cell.x - from_cell.x), 0)
	else:
		return false

	var cursor := from_cell + step
	while cursor != to_cell:
		if snake.has(cursor) or find_maniac_index_at_cell(cursor) != -1 or (raptor_active and cursor == raptor_cell):
			return false
		cursor += step
	return true

func add_shot_trace(start: Vector2, target: Vector2) -> void:
	shot_trace_starts.append(start + Vector2(0, -CELL_SIZE * 0.10))
	shot_trace_ends.append(target + Vector2(0, -CELL_SIZE * 0.10))
	shot_trace_timers.append(SHOT_TRACE_DURATION)

func random_raptor_spawn_time() -> float:
	return randf_range(RAPTOR_SPAWN_MIN, RAPTOR_SPAWN_MAX)

func update_raptor(delta: float) -> void:
	if raptor_active:
		raptor_move_timer += delta
		while raptor_move_timer >= RAPTOR_MOVE_INTERVAL:
			raptor_move_timer -= RAPTOR_MOVE_INTERVAL
			move_raptor_once()
			if not raptor_active:
				break
	else:
		raptor_spawn_timer -= delta
		if raptor_spawn_timer <= 0.0:
			if spawn_raptor():
				raptor_spawn_timer = random_raptor_spawn_time()
			else:
				raptor_spawn_timer = 8.0

func spawn_raptor() -> bool:
	if raptor_active:
		return false
	var edge_cells: Array[Vector2i] = []
	for x in range(GRID_SIZE.x):
		edge_cells.append(Vector2i(x, 0))
		edge_cells.append(Vector2i(x, GRID_SIZE.y - 1))
	for y in range(1, GRID_SIZE.y - 1):
		edge_cells.append(Vector2i(0, y))
		edge_cells.append(Vector2i(GRID_SIZE.x - 1, y))
	edge_cells.shuffle()
	for cell in edge_cells:
		if snake.has(cell) or find_person_index_at_cell(cell) != -1 or find_maniac_index_at_cell(cell) != -1:
			continue
		raptor_active = true
		raptor_cell = cell
		raptor_prev_cell = cell
		raptor_anim_elapsed = PERSON_STEP_ANIM_DURATION
		raptor_move_timer = 0.0
		raptor_steps_remaining = RAPTOR_ACTIVE_STEPS
		raptor_humans_eaten = 0
		return true
	return false

func despawn_raptor(crushed: bool = false) -> void:
	if crushed:
		add_splat(raptor_cell, 1.8)
	raptor_active = false
	raptor_prev_cell = raptor_cell
	raptor_anim_elapsed = PERSON_STEP_ANIM_DURATION
	raptor_move_timer = 0.0
	raptor_steps_remaining = 0
	raptor_humans_eaten = 0
	raptor_spawn_timer = random_raptor_spawn_time()

func move_raptor_once() -> void:
	if not raptor_active:
		return
	if raptor_steps_remaining <= 0:
		despawn_raptor()
		return

	var current_cell := raptor_cell
	var target := choose_raptor_target(current_cell)
	if target == current_cell and people_cells.is_empty():
		despawn_raptor()
		return

	var best_cell := current_cell
	var best_score := 1e9
	var directions := copy_direction_array(CARDINAL_DIRS)
	directions.shuffle()
	for dir in directions:
		var candidate := current_cell + dir
		if wrap_walls:
			candidate = wrap_cell(candidate)
		elif is_outside(candidate):
			continue
		if find_maniac_index_at_cell(candidate) != -1:
			continue
		var score_here := grid_distance_sq(candidate, target) + randf() * 0.35
		if score_here < best_score:
			best_score = score_here
			best_cell = candidate

	raptor_prev_cell = current_cell
	raptor_cell = best_cell
	raptor_anim_elapsed = 0.0
	raptor_steps_remaining -= 1

	var victim_idx := find_person_index_at_cell(best_cell)
	if victim_idx != -1:
		kill_person_at(victim_idx, false, 1.7)
		raptor_humans_eaten += 1
		if raptor_humans_eaten >= RAPTOR_MAX_HUMAN_MEALS:
			despawn_raptor()
			return
	elif snake.has(best_cell):
		bite_snake_tail()

func choose_raptor_target(current_cell: Vector2i) -> Vector2i:
	if not people_cells.is_empty():
		var best_person := people_cells[0]
		var best_dist := grid_distance_sq(current_cell, best_person)
		for cell in people_cells:
			var dist := grid_distance_sq(current_cell, cell)
			if dist < best_dist:
				best_person = cell
				best_dist = dist
		return best_person

	if snake.size() > 1:
		var best_snake := snake[1]
		var best_snake_dist := grid_distance_sq(current_cell, best_snake)
		for i in range(2, snake.size()):
			var cell := snake[i]
			var dist := grid_distance_sq(current_cell, cell)
			if dist < best_snake_dist:
				best_snake = cell
				best_snake_dist = dist
		return best_snake
	return current_cell

func bite_snake_tail() -> void:
	if snake.size() <= 2:
		return
	var old_snake := copy_cell_array(snake)
	var shrink_amount := mini(RAPTOR_SNAKE_BITE_SEGMENTS, snake.size() - 2)
	for i in range(shrink_amount):
		var bitten_cell := snake[snake.size() - 1]
		add_splat(bitten_cell, 1.5)
		snake.pop_back()
	start_snake_animation(old_snake)

func copy_cell_array(source: Array[Vector2i]) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell in source:
		result.append(cell)
	return result

func copy_string_array(source: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for value in source:
		result.append(value)
	return result

func copy_float_array(source: Array[float]) -> Array[float]:
	var result: Array[float] = []
	for value in source:
		result.append(value)
	return result

func copy_bool_array(source: Array[bool]) -> Array[bool]:
	var result: Array[bool] = []
	for value in source:
		result.append(value)
	return result

func copy_direction_array(source: Array[Vector2i]) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dir in source:
		result.append(dir)
	return result

func debug_set_snake_state(cells: Array[Vector2i], facing: Vector2i = Vector2i.RIGHT) -> void:
	snake = copy_cell_array(cells)
	snake_prev_cells = copy_cell_array(cells)
	direction = facing
	queued_direction = facing
	snake_expression_mode = "alert"
	snake_expression_timer = 0.0

func debug_snake_render_summary() -> Dictionary:
	var centers := build_snake_centers()
	var runs := snake_run_ranges()
	var render_runs := build_snake_render_runs(centers, runs)
	var first_run_samples := 0
	var first_run_raw_count := 0
	if not render_runs.is_empty():
		var first_run: SnakeRenderRun = render_runs[0]
		first_run_samples = first_run.points.size()
		first_run_raw_count = first_run.raw_count
	return {
		"run_count": runs.size(),
		"first_run_sample_count": first_run_samples,
		"first_run_raw_count": first_run_raw_count,
		"expression_mode": snake_expression_mode,
		"expression_timer": snake_expression_timer,
		"raptor_active": raptor_active
	}

func debug_set_people_state(cells: Array[Vector2i], types: Array[String], cooldowns: Array[float] = [], armed_flags: Array[bool] = []) -> void:
	people_cells = copy_cell_array(cells)
	people_prev_cells = copy_cell_array(cells)
	people_types = copy_string_array(types)
	people_move_cooldowns.clear()
	if cooldowns.size() == cells.size():
		people_move_cooldowns = copy_float_array(cooldowns)
	else:
		for i in range(cells.size()):
			people_move_cooldowns.append(random_entity_cooldown())
	people_has_gun.clear()
	if armed_flags.size() == cells.size():
		people_has_gun = copy_bool_array(armed_flags)
	else:
		for i in range(cells.size()):
			people_has_gun.append(false)
	people_anim_elapsed = PERSON_STEP_ANIM_DURATION

func debug_set_maniac_state(cells: Array[Vector2i], cooldowns: Array[float] = []) -> void:
	maniac_cells = copy_cell_array(cells)
	maniac_prev_cells = copy_cell_array(cells)
	maniac_move_cooldowns.clear()
	if cooldowns.size() == cells.size():
		maniac_move_cooldowns = copy_float_array(cooldowns)
	else:
		for i in range(cells.size()):
			maniac_move_cooldowns.append(0.0)
	maniac_anim_elapsed.clear()
	for i in range(cells.size()):
		maniac_anim_elapsed.append(MANIAC_STEP_ANIM_DURATION)

func debug_set_raptor_state(active: bool, cell: Vector2i = Vector2i.ZERO, steps_remaining: int = RAPTOR_ACTIVE_STEPS) -> void:
	raptor_active = active
	raptor_cell = cell
	raptor_prev_cell = cell
	raptor_anim_elapsed = PERSON_STEP_ANIM_DURATION
	raptor_move_timer = 0.0
	raptor_steps_remaining = steps_remaining
	raptor_humans_eaten = 0

func random_entity_cooldown() -> float:
	return randf_range(ENTITY_COOLDOWN_MIN, ENTITY_COOLDOWN_MAX)

func step_entity_cooldowns(delta: float) -> void:
	for i in range(people_move_cooldowns.size()):
		people_move_cooldowns[i] -= delta

func has_ready_entities(cooldowns: Array[float]) -> bool:
	for cooldown in cooldowns:
		if cooldown <= 0.0:
			return true
	return false

func select_phase_indices(cooldowns: Array[float]) -> Array[int]:
	var eligible: Array[int] = []
	for i in range(cooldowns.size()):
		if cooldowns[i] <= 0.0:
			eligible.append(i)
	if eligible.is_empty():
		return eligible

	eligible.shuffle()
	var move_count: int = maxi(1, int(ceili(float(eligible.size()) * AI_MOVE_FRACTION)))
	eligible.resize(move_count)
	return eligible

func pick_random_person_step(current_cell: Vector2i, occupied: Dictionary) -> Vector2i:
	var options: Array[Vector2i] = []
	var directions := copy_direction_array(CARDINAL_OR_STAY)
	directions.shuffle()
	for dir: Vector2i in directions:
		var candidate := current_cell + dir
		if wrap_walls:
			candidate = wrap_cell(candidate)
		elif is_outside(candidate):
			continue
		if dir != Vector2i.ZERO and snake.has(candidate):
			continue
		if find_maniac_index_at_cell(candidate) != -1:
			continue
		if candidate != current_cell and occupied.has(candidate):
			continue
		options.append(candidate)
	if options.is_empty():
		return current_cell
	return options[randi() % options.size()]

func ensure_people_cooldowns() -> void:
	if people_move_cooldowns.size() != people_cells.size():
		people_move_cooldowns.clear()
		for i in range(people_cells.size()):
			people_move_cooldowns.append(random_entity_cooldown())

func ensure_people_weapon_flags() -> void:
	if people_has_gun.size() != people_cells.size():
		var old_flags := copy_bool_array(people_has_gun)
		people_has_gun.clear()
		for i in range(people_cells.size()):
			people_has_gun.append(i < old_flags.size() and old_flags[i])

func ensure_maniac_cooldowns() -> void:
	if maniac_move_cooldowns.size() != maniac_cells.size():
		maniac_move_cooldowns.clear()
		for i in range(maniac_cells.size()):
			maniac_move_cooldowns.append(0.0)

func ensure_people_anim_buffers() -> void:
	if people_prev_cells.size() != people_cells.size():
		people_prev_cells = copy_cell_array(people_cells)
		people_anim_elapsed = PERSON_STEP_ANIM_DURATION

func ensure_maniac_anim_buffers() -> void:
	if maniac_prev_cells.size() != maniac_cells.size() or maniac_anim_elapsed.size() != maniac_cells.size():
		maniac_prev_cells = copy_cell_array(maniac_cells)
		maniac_anim_elapsed.clear()
		for i in range(maniac_cells.size()):
			maniac_anim_elapsed.append(MANIAC_STEP_ANIM_DURATION)

func start_snake_animation(old_snake: Array[Vector2i]) -> void:
	snake_prev_cells.clear()
	for i in range(snake.size()):
		var prev_cell := snake[i]
		if not old_snake.is_empty():
			prev_cell = old_snake[mini(i, old_snake.size() - 1)]
			if prev_cell != snake[i] and not are_screen_neighbors(prev_cell, snake[i]):
				prev_cell = snake[i]
		snake_prev_cells.append(prev_cell)
	snake_anim_elapsed = 0.0

func start_people_animation(old_people: Array[Vector2i]) -> void:
	people_prev_cells.clear()
	for i in range(people_cells.size()):
		var prev_cell := people_cells[i]
		if i < old_people.size():
			prev_cell = old_people[i]
			if prev_cell != people_cells[i] and not are_screen_neighbors(prev_cell, people_cells[i]):
				prev_cell = people_cells[i]
		people_prev_cells.append(prev_cell)
	people_anim_elapsed = 0.0

func start_maniac_animation(index: int, from_cell: Vector2i, to_cell: Vector2i) -> void:
	ensure_maniac_anim_buffers()
	if index < 0 or index >= maniac_cells.size():
		return
	if from_cell != to_cell and not are_screen_neighbors(from_cell, to_cell):
		from_cell = to_cell
	maniac_prev_cells[index] = from_cell
	maniac_anim_elapsed[index] = 0.0

func ease_motion(raw_alpha: float) -> float:
	var t := clampf(raw_alpha, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func anim_alpha(elapsed: float, duration: float) -> float:
	if duration <= 0.0:
		return 1.0
	return ease_motion(elapsed / duration)

func wrap_cell(cell: Vector2i) -> Vector2i:
	return Vector2i(posmod(cell.x, GRID_SIZE.x), posmod(cell.y, GRID_SIZE.y))

func is_outside(cell: Vector2i) -> bool:
	return cell.x < 0 or cell.y < 0 or cell.x >= GRID_SIZE.x or cell.y >= GRID_SIZE.y

func grid_distance_sq(a: Vector2i, b: Vector2i) -> float:
	var dx: int = absi(a.x - b.x)
	var dy: int = absi(a.y - b.y)
	if wrap_walls:
		dx = min(dx, GRID_SIZE.x - dx)
		dy = min(dy, GRID_SIZE.y - dy)
	return float(dx * dx + dy * dy)

func are_screen_neighbors(a: Vector2i, b: Vector2i) -> bool:
	return absi(a.x - b.x) + absi(a.y - b.y) == 1

func is_snake_corner(index: int) -> bool:
	if index <= 0 or index >= snake.size() - 1:
		return false
	if not are_screen_neighbors(snake[index], snake[index - 1]) or not are_screen_neighbors(snake[index], snake[index + 1]):
		return true
	var to_prev := snake[index - 1] - snake[index]
	var to_next := snake[index + 1] - snake[index]
	return to_prev.x != to_next.x and to_prev.y != to_next.y

func trigger_game_over() -> void:
	game_over = true
	is_paused = false
	pause_overlay.visible = false
	game_over_overlay.visible = true
	game_over_label.text = "Final Score: %d\nPeople Remaining: %d\nChainsaw Maniacs: %d" % [score, people_cells.size(), maniac_cells.size()]
	queue_redraw()

func update_stats_ui() -> void:
	score_label.text = str(score)
	people_label.text = str(people_cells.size())
	maniacs_label.text = str(maniac_cells.size())
	mode_label.text = "Wrap ON" if wrap_walls else "Wrap OFF"

func board_origin() -> Vector2:
	var board_size := Vector2(GRID_SIZE.x * CELL_SIZE, GRID_SIZE.y * CELL_SIZE)
	var viewport_size := get_viewport_rect().size
	var origin := (viewport_size - board_size) * 0.5
	origin.y = maxf(152.0, origin.y)
	return origin

func board_rect() -> Rect2:
	return Rect2(board_origin(), Vector2(GRID_SIZE.x * CELL_SIZE, GRID_SIZE.y * CELL_SIZE))

func cell_to_world(cell: Vector2i) -> Vector2:
	return board_origin() + Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE)

func cell_center(cell: Vector2i) -> Vector2:
	return cell_to_world(cell) + Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)

func animated_cell_center(from_cell: Vector2i, to_cell: Vector2i, alpha: float) -> Vector2:
	if from_cell != to_cell and not are_screen_neighbors(from_cell, to_cell):
		from_cell = to_cell
	return cell_center(from_cell).lerp(cell_center(to_cell), alpha)

func snake_segment_center(index: int) -> Vector2:
	var from_cell: Vector2i = snake[index]
	if snake_prev_cells.size() == snake.size():
		from_cell = snake_prev_cells[index]
	return animated_cell_center(from_cell, snake[index], anim_alpha(snake_anim_elapsed, SNAKE_STEP_ANIM_DURATION))

func person_center(index: int) -> Vector2:
	var from_cell: Vector2i = people_cells[index]
	if people_prev_cells.size() == people_cells.size():
		from_cell = people_prev_cells[index]
	return animated_cell_center(from_cell, people_cells[index], anim_alpha(people_anim_elapsed, PERSON_STEP_ANIM_DURATION))

func maniac_center(index: int) -> Vector2:
	var from_cell: Vector2i = maniac_cells[index]
	var alpha := 1.0
	if maniac_prev_cells.size() == maniac_cells.size() and maniac_anim_elapsed.size() == maniac_cells.size():
		from_cell = maniac_prev_cells[index]
		alpha = anim_alpha(maniac_anim_elapsed[index], MANIAC_STEP_ANIM_DURATION)
	return animated_cell_center(from_cell, maniac_cells[index], alpha)

func raptor_center() -> Vector2:
	var from_cell := raptor_prev_cell
	var alpha := anim_alpha(raptor_anim_elapsed, PERSON_STEP_ANIM_DURATION)
	return animated_cell_center(from_cell, raptor_cell, alpha)

func _draw() -> void:
	draw_board()
	draw_stains()
	draw_splats()
	draw_people()
	draw_shot_traces()
	draw_maniac()
	draw_raptor()
	draw_snake()

func draw_board() -> void:
	var rect := board_rect()
	draw_rect(Rect2(rect.position + Vector2(-26, 8), rect.size + Vector2(52, 26)), Color(0, 0, 0, 0.12), true)
	draw_rect(rect, Color(0.07, 0.10, 0.16), true)

	for x in range(GRID_SIZE.x):
		for y in range(GRID_SIZE.y):
			var pos := cell_to_world(Vector2i(x, y))
			var color := Color(0.10, 0.16, 0.25)
			if (x + y) % 2 == 0:
				color = Color(0.12, 0.19, 0.29)
			draw_rect(Rect2(pos, Vector2(CELL_SIZE, CELL_SIZE)), color, true)

	var gloss := Rect2(rect.position + Vector2(0, 0), Vector2(rect.size.x, rect.size.y * 0.24))
	draw_rect(gloss, Color(0.68, 0.84, 1.0, 0.04), true)

	if not wrap_walls:
		draw_rect(rect, Color(0.38, 0.58, 0.84), false, 3.0)

func draw_snake() -> void:
	if snake.is_empty():
		return

	var centers := build_snake_centers()
	var runs := snake_run_ranges()
	var render_runs := build_snake_render_runs(centers, runs)
	var outline_color := Color(0.11, 0.13, 0.07, 0.96)
	var body_color := Color(0.42, 0.66, 0.19)
	var back_color := Color(0.26, 0.50, 0.12)
	var highlight_color := Color(0.84, 0.92, 0.56, 0.28)
	var shadow_color := Color(0.00, 0.00, 0.00, 0.20)

	for render_run_variant in render_runs:
		var render_run: SnakeRenderRun = render_run_variant
		if render_run.points.size() < 2:
			continue
		var shadow_poly := offset_polygon(build_snake_strip_polygon(render_run.points, render_run.widths, CELL_SIZE * 0.048), Vector2(0, CELL_SIZE * 0.085))
		draw_colored_polygon(shadow_poly, shadow_color)

	for render_run_variant in render_runs:
		var render_run: SnakeRenderRun = render_run_variant
		if render_run.points.size() < 2:
			continue
		draw_colored_polygon(build_snake_strip_polygon(render_run.points, render_run.widths, CELL_SIZE * 0.042), outline_color)
		draw_colored_polygon(build_snake_strip_polygon(render_run.points, render_run.widths, 0.0), body_color)
		draw_colored_polygon(build_snake_strip_polygon(render_run.points, render_run.widths, -CELL_SIZE * 0.050), back_color)

	draw_snake_pattern(render_runs)
	draw_snake_side_highlights(render_runs, highlight_color)
	draw_snake_tail(render_runs)
	draw_snake_head(render_runs)

func build_snake_centers() -> Array[Vector2]:
	var centers: Array[Vector2] = []
	for i in range(snake.size()):
		centers.append(snake_segment_center(i))
	return centers

func snake_run_ranges() -> Array[Vector2i]:
	var runs: Array[Vector2i] = []
	if snake.is_empty():
		return runs
	var start_index := 0
	for i in range(1, snake.size()):
		if not are_screen_neighbors(snake[i - 1], snake[i]):
			runs.append(Vector2i(start_index, i - 1))
			start_index = i
	runs.append(Vector2i(start_index, snake.size() - 1))
	return runs

func snake_half_width(index: float) -> float:
	if snake.size() <= 1:
		return CELL_SIZE * 0.18

	if index < 0.85:
		return lerpf(CELL_SIZE * 0.13, CELL_SIZE * 0.16, clampf(index / 0.85, 0.0, 1.0))
	if index < 2.3:
		return lerpf(CELL_SIZE * 0.16, CELL_SIZE * 0.24, clampf((index - 0.85) / 1.45, 0.0, 1.0))

	var tail_index := float(maxi(1, snake.size() - 1))
	var t := clampf(index / tail_index, 0.0, 1.0)
	var base := lerpf(CELL_SIZE * 0.24, CELL_SIZE * 0.082, pow(t, 0.86))
	var swell := sin(t * PI) * CELL_SIZE * 0.038
	var width := base + swell
	if index > tail_index - 1.2:
		width = lerpf(width, CELL_SIZE * 0.055, clampf((index - (tail_index - 1.2)) / 1.2, 0.0, 1.0))
	return width

func build_snake_render_runs(centers: Array[Vector2], runs: Array[Vector2i]) -> Array:
	var render_runs: Array = []
	for run in runs:
		if run.y < run.x:
			continue
		var raw_points: Array[Vector2] = []
		var raw_cells: Array[Vector2i] = []
		var raw_widths: Array[float] = []
		var raw_indices: Array[float] = []
		for i in range(run.x, run.y + 1):
			raw_points.append(centers[i])
			raw_cells.append(snake[i])
			raw_widths.append(snake_half_width(float(i)))
			raw_indices.append(float(i))
		render_runs.append(build_smoothed_snake_run(raw_points, raw_cells, raw_widths, raw_indices, run.x, run.y))
	return render_runs

func build_smoothed_snake_run(raw_points: Array[Vector2], raw_cells: Array[Vector2i], raw_widths: Array[float], raw_indices: Array[float], raw_start: int, raw_end: int) -> SnakeRenderRun:
	var render_run: SnakeRenderRun = SnakeRenderRun.new()
	render_run.raw_start = raw_start
	render_run.raw_end = raw_end
	render_run.raw_count = raw_points.size()
	if raw_points.is_empty():
		return render_run

	append_snake_run_sample(render_run, raw_points[0], raw_widths[0])
	if raw_points.size() == 1:
		return render_run

	for i in range(1, raw_points.size() - 1):
		var prev_point: Vector2 = raw_points[i - 1]
		var current_point: Vector2 = raw_points[i]
		var next_point: Vector2 = raw_points[i + 1]
		var prev_cell: Vector2i = raw_cells[i - 1]
		var current_cell: Vector2i = raw_cells[i]
		var next_cell: Vector2i = raw_cells[i + 1]
		var dir_in: Vector2 = Vector2(current_cell - prev_cell)
		var dir_out: Vector2 = Vector2(next_cell - current_cell)
		if dir_in != Vector2.ZERO:
			dir_in = dir_in.normalized()
		if dir_out != Vector2.ZERO:
			dir_out = dir_out.normalized()
		var is_turn := dir_in != Vector2.ZERO and dir_out != Vector2.ZERO and dir_in.dot(dir_out) < 0.98

		if is_turn:
			var segment_in_length := prev_point.distance_to(current_point)
			var segment_out_length := current_point.distance_to(next_point)
			var corner_radius := minf(segment_in_length, segment_out_length) * SNAKE_CORNER_ROUNDING_RATIO
			var inset_t := corner_radius / maxf(segment_in_length, 0.001)
			var outset_t := corner_radius / maxf(segment_out_length, 0.001)
			var in_point := current_point - dir_in * corner_radius
			var out_point := current_point + dir_out * corner_radius
			var in_width := lerpf(raw_widths[i - 1], raw_widths[i], 1.0 - inset_t)
			var out_width := lerpf(raw_widths[i], raw_widths[i + 1], outset_t)
			var in_index := lerpf(raw_indices[i - 1], raw_indices[i], 1.0 - inset_t)
			var out_index := lerpf(raw_indices[i], raw_indices[i + 1], outset_t)

			append_snake_run_segment(render_run, in_point, in_width, maxf(1.0, absf(in_index - raw_indices[i - 1]) * 3.0))
			var arc_center := current_point - dir_in * corner_radius + dir_out * corner_radius
			var start_angle := (in_point - arc_center).angle()
			var end_angle := (out_point - arc_center).angle()
			for sample_index in range(1, SNAKE_CORNER_SAMPLES + 1):
				var t := float(sample_index) / float(SNAKE_CORNER_SAMPLES + 1)
				var curve_angle := lerp_angle(start_angle, end_angle, t)
				var curve_point := arc_center + Vector2.RIGHT.rotated(curve_angle) * corner_radius
				var curve_width := quadratic_bezier_float(in_width, raw_widths[i], out_width, t)
				append_snake_run_sample(render_run, curve_point, curve_width)
			append_snake_run_sample(render_run, out_point, out_width)
		else:
			append_snake_run_segment(render_run, current_point, raw_widths[i], SNAKE_STRAIGHT_SEGMENT_SAMPLES)

	var final_index := raw_points.size() - 1
	append_snake_run_segment(render_run, raw_points[final_index], raw_widths[final_index], SNAKE_STRAIGHT_SEGMENT_SAMPLES)
	apply_snake_body_wave(render_run)
	return render_run

func append_snake_run_segment(render_run: SnakeRenderRun, target_point: Vector2, target_width: float, subdivisions_variant) -> void:
	if render_run.points.is_empty():
		append_snake_run_sample(render_run, target_point, target_width)
		return

	var subdivisions: int = int(subdivisions_variant)
	var start_point: Vector2 = render_run.points[render_run.points.size() - 1]
	var start_width: float = render_run.widths[render_run.widths.size() - 1]
	for step in range(1, subdivisions + 1):
		var t := float(step) / float(subdivisions + 1)
		append_snake_run_sample(render_run, start_point.lerp(target_point, t), lerpf(start_width, target_width, t))
	append_snake_run_sample(render_run, target_point, target_width)

func append_snake_run_sample(render_run: SnakeRenderRun, point: Vector2, width: float) -> void:
	if not render_run.points.is_empty() and render_run.points[render_run.points.size() - 1].distance_to(point) < 0.01:
		render_run.widths[render_run.widths.size() - 1] = width
		return

	render_run.points.append(point)
	render_run.widths.append(width)
	if render_run.distances.is_empty():
		render_run.distances.append(0.0)
	else:
		var next_distance: float = render_run.distances[render_run.distances.size() - 1] + render_run.points[render_run.points.size() - 2].distance_to(point)
		render_run.distances.append(next_distance)

func apply_snake_body_wave(render_run: SnakeRenderRun) -> void:
	if render_run.points.size() < 3:
		return

	var total_distance: float = render_run.distances[render_run.distances.size() - 1]
	for i in range(1, render_run.points.size() - 1):
		var travel_t := 0.0
		if total_distance > 0.0:
			travel_t = render_run.distances[i] / total_distance
		var wave_scale := sin(travel_t * PI) * CELL_SIZE * SNAKE_BODY_WAVE_AMPLITUDE
		var tangent := snake_sample_tangent(render_run.points, i)
		if tangent == Vector2.ZERO:
			continue
		var side := Vector2(-tangent.y, tangent.x)
		var phase := person_anim_time * 5.2 + travel_t * 10.5
		var slither := sin(phase) * 0.72 + sin(phase * 0.5 + travel_t * 4.4) * 0.28
		render_run.points[i] += side * slither * wave_scale

	for i in range(1, render_run.points.size()):
		render_run.distances[i] = render_run.distances[i - 1] + render_run.points[i - 1].distance_to(render_run.points[i])

func quadratic_bezier_point(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var ab := a.lerp(b, t)
	var bc := b.lerp(c, t)
	return ab.lerp(bc, t)

func quadratic_bezier_float(a: float, b: float, c: float, t: float) -> float:
	var ab := lerpf(a, b, t)
	var bc := lerpf(b, c, t)
	return lerpf(ab, bc, t)

func snake_sample_tangent(points: Array[Vector2], index: int) -> Vector2:
	var prev_index := maxi(0, index - 1)
	var next_index := mini(points.size() - 1, index + 1)
	var tangent := points[next_index] - points[prev_index]
	if tangent == Vector2.ZERO:
		if index > 0:
			tangent = points[index] - points[index - 1]
		elif index < points.size() - 1:
			tangent = points[index + 1] - points[index]
	if tangent == Vector2.ZERO:
		tangent = Vector2.RIGHT
	return tangent.normalized()

func build_snake_strip_polygon(points: Array[Vector2], widths: Array[float], extra_width: float) -> PackedVector2Array:
	var left_points := PackedVector2Array()
	var right_points := PackedVector2Array()
	for i in range(points.size()):
		var tangent := snake_sample_tangent(points, i)
		var side := Vector2(-tangent.y, tangent.x)
		var half_width := maxf(CELL_SIZE * 0.02, widths[i] + extra_width)
		left_points.append(points[i] + side * half_width)
		right_points.append(points[i] - side * half_width)

	var polygon := PackedVector2Array()
	for point in left_points:
		polygon.append(point)
	for i in range(right_points.size() - 1, -1, -1):
		polygon.append(right_points[i])
	return polygon

func offset_polygon(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var shifted := PackedVector2Array()
	for point in points:
		shifted.append(point + offset)
	return shifted

func draw_snake_pattern(render_runs: Array) -> void:
	for render_run_variant in render_runs:
		var render_run: SnakeRenderRun = render_run_variant
		if render_run.points.size() < 7:
			continue
		var outer_points := PackedVector2Array()
		var inner_points := PackedVector2Array()
		var next_pick_distance := SNAKE_ZIG_ZAG_SPACING
		var zig_sign := 1.0
		for i in range(2, render_run.points.size() - 2):
			if render_run.distances[i] < next_pick_distance:
				continue
			next_pick_distance += SNAKE_ZIG_ZAG_SPACING
			var tangent := snake_sample_tangent(render_run.points, i)
			var side := Vector2(-tangent.y, tangent.x)
			var body_t := float(i) / float(maxi(1, render_run.points.size() - 1))
			var amplitude := render_run.widths[i] * lerpf(0.34, 0.16, body_t)
			if body_t < 0.18:
				amplitude *= lerpf(0.25, 1.0, body_t / 0.18)
			var zig_point := render_run.points[i] + side * amplitude * zig_sign
			outer_points.append(zig_point)
			inner_points.append(render_run.points[i] + side * amplitude * SNAKE_ZIG_ZAG_INNER_RATIO * zig_sign)
			zig_sign *= -1.0
		if outer_points.size() >= 2:
			draw_polyline(outer_points, Color(0.19, 0.29, 0.07, 0.86), 6.4, true)
			draw_polyline(inner_points, Color(0.58, 0.74, 0.28, 0.66), 2.4, true)

func draw_snake_side_highlights(render_runs: Array, highlight_color: Color) -> void:
	for render_run_variant in render_runs:
		var render_run: SnakeRenderRun = render_run_variant
		for i in range(render_run.points.size() - 1):
			var tangent := snake_sample_tangent(render_run.points, i)
			var next_tangent := snake_sample_tangent(render_run.points, i + 1)
			var side := Vector2(-tangent.y, tangent.x)
			var next_side := Vector2(-next_tangent.y, next_tangent.x)
			var upper_width := render_run.widths[i] * 0.46
			var next_width := render_run.widths[i + 1] * 0.46
			draw_line(render_run.points[i] - side * upper_width, render_run.points[i + 1] - next_side * next_width, highlight_color, 3.1)
			draw_line(render_run.points[i] + side * upper_width * 0.86, render_run.points[i + 1] + next_side * next_width * 0.86, Color(0.16, 0.24, 0.08, 0.18), 2.4)

func draw_snake_tail(render_runs: Array) -> void:
	if render_runs.is_empty():
		return
	var tail_run: SnakeRenderRun = render_runs[render_runs.size() - 1]
	var tail_index := tail_run.points.size() - 1
	if tail_index <= 0:
		return
	var tail_center := tail_run.points[tail_index]
	var tail_dir := (tail_center - tail_run.points[tail_index - 1]).normalized()
	if tail_dir == Vector2.ZERO:
		tail_dir = Vector2.LEFT
	var side := Vector2(-tail_dir.y, tail_dir.x)
	var tail_sway := sin(person_anim_time * 4.1 + float(tail_index) * 0.42) * CELL_SIZE * SNAKE_TAIL_SWAY_AMPLITUDE
	var tip := tail_center + tail_dir * CELL_SIZE * 0.44 + side * tail_sway
	var base := tail_center - tail_dir * CELL_SIZE * 0.10
	var outline := PackedVector2Array([
		tip + tail_dir * CELL_SIZE * 0.05,
		base + side * CELL_SIZE * 0.11,
		base - side * CELL_SIZE * 0.11
	])
	var fill := PackedVector2Array([
		tip,
		base + side * CELL_SIZE * 0.085,
		base - side * CELL_SIZE * 0.085
	])
	draw_colored_polygon(outline, Color(0.11, 0.13, 0.07, 0.96))
	draw_colored_polygon(fill, Color(0.36, 0.62, 0.16))

func draw_snake_head(render_runs: Array) -> void:
	if render_runs.is_empty():
		return

	var head_run: SnakeRenderRun = render_runs[0]
	var head_center := head_run.points[0]
	var head_dir := Vector2(direction)
	if head_run.points.size() > 2:
		head_dir = (head_run.points[0] - head_run.points[2]).normalized()
	elif snake.size() > 1 and are_screen_neighbors(snake[0], snake[1]):
		head_dir = (snake_segment_center(0) - snake_segment_center(1)).normalized()
	if head_dir == Vector2.ZERO:
		head_dir = Vector2.RIGHT
	var side := Vector2(-head_dir.y, head_dir.x)
	head_center += side * sin(person_anim_time * 3.6) * CELL_SIZE * 0.010 + head_dir * sin(person_anim_time * 2.8) * CELL_SIZE * 0.006

	var express_t := clampf(snake_expression_timer / SNAKE_FACE_EXPRESSION_DURATION, 0.0, 1.0)
	var head_length := CELL_SIZE * 0.82 * SNAKE_HEAD_SCALE
	var skull_width := CELL_SIZE * 0.36 * SNAKE_HEAD_SCALE
	var jaw_width := CELL_SIZE * 0.47 * SNAKE_HEAD_SCALE
	var nose := head_center + head_dir * head_length * 0.44
	var snout := head_center + head_dir * head_length * 0.20
	var eye_line := head_center + head_dir * head_length * 0.05
	var jaw_line := head_center - head_dir * head_length * 0.01
	var neck := head_center - head_dir * head_length * 0.40
	var outline := PackedVector2Array([
		nose + head_dir * head_length * 0.03,
		snout + side * skull_width * 0.34,
		eye_line + side * skull_width * 0.60,
		head_center + side * jaw_width * 0.84 - head_dir * head_length * 0.07,
		neck + side * CELL_SIZE * 0.12,
		neck - side * CELL_SIZE * 0.12,
		head_center - side * jaw_width * 0.84 - head_dir * head_length * 0.07,
		eye_line - side * skull_width * 0.60,
		snout - side * skull_width * 0.34
	])
	var fill := PackedVector2Array([
		nose,
		snout + side * skull_width * 0.28,
		eye_line + side * skull_width * 0.52,
		head_center + side * jaw_width * 0.70 - head_dir * head_length * 0.05,
		neck + side * CELL_SIZE * 0.08,
		neck - side * CELL_SIZE * 0.08,
		head_center - side * jaw_width * 0.70 - head_dir * head_length * 0.05,
		eye_line - side * skull_width * 0.52,
		snout - side * skull_width * 0.28
	])
	draw_colored_polygon(outline, Color(0.11, 0.13, 0.07, 0.96))
	draw_colored_polygon(fill, Color(0.50, 0.78, 0.23))
	draw_circle(head_center + head_dir * head_length * 0.02, CELL_SIZE * 0.23, Color(0.50, 0.78, 0.23, 0.92))
	draw_circle(head_center - head_dir * head_length * 0.02, CELL_SIZE * 0.21, Color(0.46, 0.73, 0.21, 0.90))

	var skull := PackedVector2Array([
		head_center + head_dir * head_length * 0.24,
		head_center + side * CELL_SIZE * 0.20,
		head_center - head_dir * head_length * 0.08,
		head_center - side * CELL_SIZE * 0.20
	])
	draw_colored_polygon(skull, Color(0.27, 0.44, 0.12, 0.50))
	var jaw_shadow := PackedVector2Array([
		jaw_line + side * jaw_width * 0.72,
		head_center + side * jaw_width * 0.36 - head_dir * head_length * 0.09,
		neck + side * CELL_SIZE * 0.05,
		neck - side * CELL_SIZE * 0.05,
		head_center - side * jaw_width * 0.36 - head_dir * head_length * 0.09,
		jaw_line - side * jaw_width * 0.72
	])
	draw_colored_polygon(jaw_shadow, Color(0.16, 0.26, 0.08, 0.22))
	draw_line(neck - side * CELL_SIZE * 0.05, snout - head_dir * head_length * 0.10 - side * CELL_SIZE * 0.10, Color(0.86, 0.95, 0.58, 0.34), 4.3)
	draw_line(neck + side * CELL_SIZE * 0.02, snout - head_dir * head_length * 0.12 + side * CELL_SIZE * 0.11, Color(0.16, 0.24, 0.08, 0.18), 3.1)

	var eye_open := lerpf(CELL_SIZE * 0.070, CELL_SIZE * 0.046, express_t)
	var brow_tilt := lerpf(-1.0, -0.25, express_t)
	var eye_track := head_dir * CELL_SIZE * 0.012
	var eye_signs: Array[float] = [-1.0, 1.0]
	for eye_sign in eye_signs:
		var eye_center: Vector2 = head_center + head_dir * head_length * 0.11 + side * CELL_SIZE * 0.20 * eye_sign
		draw_circle(eye_center, eye_open, Color(0.94, 0.96, 0.88))
		draw_circle(eye_center + eye_track, eye_open * 0.62, Color(0.90, 0.68, 0.16))
		draw_circle(eye_center + eye_track + head_dir * eye_open * 0.10, eye_open * 0.30, Color(0.02, 0.04, 0.02))
		draw_circle(eye_center + eye_track - head_dir * eye_open * 0.16 - side * eye_open * 0.16 * eye_sign, eye_open * 0.12, Color(1, 1, 1, 0.86))
		draw_line(
			eye_center - head_dir * CELL_SIZE * 0.05 + side * CELL_SIZE * 0.04 * eye_sign,
			eye_center + head_dir * CELL_SIZE * 0.04 + side * CELL_SIZE * 0.02 * eye_sign + Vector2(0, brow_tilt),
			Color(0.07, 0.08, 0.04),
			2.2
		)

	var nostril_left := nose - head_dir * head_length * 0.10 + side * CELL_SIZE * 0.07
	var nostril_right := nose - head_dir * head_length * 0.10 - side * CELL_SIZE * 0.07
	draw_circle(nostril_left, CELL_SIZE * 0.018, Color(0.04, 0.05, 0.03, 0.90))
	draw_circle(nostril_right, CELL_SIZE * 0.018, Color(0.04, 0.05, 0.03, 0.90))
	draw_line(jaw_line + side * jaw_width * 0.72, snout - head_dir * head_length * 0.02 + side * CELL_SIZE * 0.13, Color(0.17, 0.22, 0.08, 0.35), 2.2)
	draw_line(jaw_line - side * jaw_width * 0.72, snout - head_dir * head_length * 0.02 - side * CELL_SIZE * 0.13, Color(0.17, 0.22, 0.08, 0.35), 2.2)

	var mouth_start := jaw_line - head_dir * head_length * 0.06 - side * CELL_SIZE * 0.18
	var mouth_mid := jaw_line + head_dir * head_length * (0.05 + express_t * 0.05)
	var mouth_end := jaw_line - head_dir * head_length * 0.06 + side * CELL_SIZE * 0.18
	var mouth_curve_down := CELL_SIZE * lerpf(0.02, 0.08, express_t)
	draw_polyline(
		PackedVector2Array([
			mouth_start,
			mouth_mid + head_dir * head_length * 0.04 + Vector2(0, mouth_curve_down),
			mouth_end
		]),
		Color(0.18, 0.09, 0.06, 0.95),
		2.4,
		true
	)
	if express_t > 0.12:
		var tongue_start := mouth_mid + head_dir * head_length * 0.04
		var tongue_mid := tongue_start + head_dir * head_length * 0.10
		draw_line(tongue_start, tongue_mid, Color(0.90, 0.10, 0.16), 2.2)
		draw_line(tongue_mid, tongue_mid + head_dir * head_length * 0.08 + side * CELL_SIZE * 0.05, Color(0.90, 0.10, 0.16), 1.4)
		draw_line(tongue_mid, tongue_mid + head_dir * head_length * 0.08 - side * CELL_SIZE * 0.05, Color(0.90, 0.10, 0.16), 1.4)

func draw_people() -> void:
	ensure_people_weapon_flags()
	for i in range(people_cells.size()):
		var center := person_center(i)
		var step_alpha := anim_alpha(people_anim_elapsed, PERSON_STEP_ANIM_DURATION)
		var phase: float = person_anim_time * 2.2 + step_alpha * TAU + float(i) * 1.15
		var bob: float = sin(phase) * CELL_SIZE * 0.032
		var jitter: Vector2 = Vector2(sin(phase * 1.7), cos(phase * 1.3)) * (CELL_SIZE * 0.010)
		draw_person_shape(center + Vector2(0, bob) + jitter, people_types[i], 1.0, phase, people_has_gun[i])

func draw_shot_traces() -> void:
	for i in range(shot_trace_timers.size()):
		var alpha := clampf(shot_trace_timers[i] / SHOT_TRACE_DURATION, 0.0, 1.0)
		draw_line(shot_trace_starts[i], shot_trace_ends[i], Color(1.0, 0.92, 0.52, alpha * 0.95), 2.4)
		draw_circle(shot_trace_starts[i], CELL_SIZE * 0.030, Color(1.0, 0.84, 0.30, alpha * 0.95))
		draw_circle(shot_trace_ends[i], CELL_SIZE * 0.020, Color(1.0, 0.68, 0.24, alpha * 0.75))

func draw_stains() -> void:
	for i in range(stain_cells.size()):
		var alpha: float = clampf(stain_timers[i] / STAIN_DURATION, 0.0, 1.0)
		var intensity: float = stain_intensities[i]
		var center := cell_to_world(stain_cells[i]) + Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.72)
		draw_ellipse(center, CELL_SIZE * (0.30 + 0.12 * intensity), CELL_SIZE * (0.11 + 0.035 * intensity), Color(0.58, 0.02, 0.04, alpha * 0.58))
		draw_ellipse(center + Vector2(CELL_SIZE * 0.08, CELL_SIZE * 0.04), CELL_SIZE * (0.18 + 0.06 * intensity), CELL_SIZE * 0.07, Color(0.74, 0.03, 0.06, alpha * 0.40))
		draw_circle(center + Vector2(CELL_SIZE * 0.18, -CELL_SIZE * 0.02), CELL_SIZE * 0.050, Color(0.82, 0.04, 0.08, alpha * 0.34))
		draw_circle(center + Vector2(-CELL_SIZE * 0.22, CELL_SIZE * 0.03), CELL_SIZE * 0.035, Color(0.78, 0.03, 0.06, alpha * 0.28))

func draw_splats() -> void:
	for i in range(splat_cells.size()):
		var alpha: float = clampf(splat_timers[i] / SPLAT_DURATION, 0.0, 1.0)
		var intensity: float = splat_intensities[i]
		var center := cell_to_world(splat_cells[i]) + Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.70)
		draw_ellipse(center, CELL_SIZE * (0.32 + 0.08 * intensity), CELL_SIZE * (0.13 + 0.03 * intensity), Color(0.68, 0.01, 0.01, alpha * 0.96))
		draw_circle(center + Vector2(-CELL_SIZE * 0.15, -CELL_SIZE * 0.06), CELL_SIZE * (0.08 + intensity * 0.02), Color(0.95, 0.05, 0.05, alpha * 0.94))
		draw_circle(center + Vector2(CELL_SIZE * 0.13, -CELL_SIZE * 0.04), CELL_SIZE * (0.07 + intensity * 0.018), Color(0.91, 0.08, 0.08, alpha * 0.90))
		draw_circle(center + Vector2(-CELL_SIZE * 0.02, -CELL_SIZE * 0.11), CELL_SIZE * (0.05 + intensity * 0.016), Color(0.98, 0.15, 0.15, alpha * 0.84))
		for spray_idx in range(10):
			var angle := (float(spray_idx) * 0.43 + float(i) * 0.37) * PI
			var offset := Vector2(cos(angle), sin(angle)) * (CELL_SIZE * (0.16 + spray_idx * 0.045 * intensity))
			var droplet_alpha: float = maxf(0.08, 0.86 - spray_idx * 0.065)
			draw_circle(center + offset, CELL_SIZE * (0.016 + intensity * 0.010), Color(0.92, 0.02, 0.03, alpha * droplet_alpha))
			if spray_idx % 3 == 0:
				draw_line(center + offset * 0.55, center + offset, Color(0.86, 0.02, 0.03, alpha * 0.44), 1.2)

func draw_person_shape(center: Vector2, person_kind: String, alpha: float, anim_phase: float, has_gun: bool = false) -> void:
	var unit := CELL_SIZE / 36.0
	var skin := Color(1.00, 0.86, 0.70, alpha)
	var outfit := Color(0.78, 0.42, 0.36, alpha)
	var hair := Color(0.24, 0.16, 0.09, alpha)
	var accent := Color(0.10, 0.10, 0.10, alpha)
	var pants := Color(0.16, 0.18, 0.24, alpha)
	var sleeve := Color(0.86, 0.78, 0.70, alpha)

	match person_kind:
		"woman":
			outfit = Color(0.78, 0.38, 0.66, alpha)
			hair = Color(0.18, 0.11, 0.05, alpha)
			accent = Color(0.20, 0.12, 0.20, alpha)
			pants = Color(0.26, 0.16, 0.26, alpha)
		"grandma":
			outfit = Color(0.62, 0.70, 0.86, alpha)
			hair = Color(0.88, 0.88, 0.88, alpha)
			accent = Color(0.25, 0.30, 0.40, alpha)
			pants = Color(0.36, 0.38, 0.46, alpha)
		"grandpa":
			outfit = Color(0.60, 0.70, 0.56, alpha)
			hair = Color(0.84, 0.84, 0.84, alpha)
			accent = Color(0.22, 0.30, 0.22, alpha)
			pants = Color(0.24, 0.28, 0.24, alpha)
		_:
			outfit = Color(0.34, 0.58, 0.86, alpha)
			hair = Color(0.24, 0.16, 0.09, alpha)
			pants = Color(0.20, 0.24, 0.30, alpha)

	var head_center := center + Vector2(0, -8.0 * unit)
	var neck_rect := Rect2(center + Vector2(-1.3 * unit, -3.0 * unit), Vector2(2.6 * unit, 2.2 * unit))
	var body_rect := Rect2(center + Vector2(-6.2 * unit, -1.8 * unit), Vector2(12.4 * unit, 12.8 * unit))
	var hip_rect := Rect2(center + Vector2(-5.6 * unit, 8.4 * unit), Vector2(11.2 * unit, 4.2 * unit))
	var leg_swing: float = sin(anim_phase * 2.8) * 2.0 * unit
	var arm_swing: float = cos(anim_phase * 3.1) * 1.9 * unit
	var shoulder_sway: float = sin(anim_phase * 1.7) * 0.9 * unit
	var shadow_center := center + Vector2(0, 14.0 * unit)
	var torso_points := PackedVector2Array([
		center + Vector2(-7.2 * unit, -1.2 * unit + shoulder_sway),
		center + Vector2(7.2 * unit, -1.2 * unit - shoulder_sway),
		center + Vector2(5.4 * unit, 10.8 * unit),
		center + Vector2(-5.4 * unit, 10.8 * unit)
	])

	draw_ellipse(shadow_center, 7.0 * unit, 2.6 * unit, Color(0, 0, 0, 0.18))
	draw_circle(head_center + Vector2(-5.0 * unit, 0.5 * unit), 1.7 * unit, skin.darkened(0.04))
	draw_circle(head_center + Vector2(5.0 * unit, 0.5 * unit), 1.7 * unit, skin.darkened(0.04))
	draw_circle(head_center, 5.9 * unit, skin)
	draw_circle(head_center + Vector2(0, -3.7 * unit), 5.3 * unit, hair)
	draw_ellipse(head_center + Vector2(0, -2.6 * unit), 4.9 * unit, 2.3 * unit, hair.lightened(0.08))
	draw_rect(neck_rect, skin.darkened(0.05), true)
	draw_colored_polygon(torso_points, outfit.darkened(0.10))
	draw_rect(body_rect, outfit, true)
	draw_rect(Rect2(body_rect.position + Vector2(1.0 * unit, 1.0 * unit), Vector2(body_rect.size.x - 2.0 * unit, 2.2 * unit)), outfit.lightened(0.18), true)
	draw_rect(hip_rect, pants, true)
	draw_line(center + Vector2(-5.2 * unit, -0.4 * unit), center + Vector2(5.2 * unit, -0.4 * unit), outfit.lightened(0.16), 1.4)
	draw_line(center + Vector2(0, -1.2 * unit), center + Vector2(0, 10.0 * unit), outfit.darkened(0.18), 1.0)
	draw_circle(center + Vector2(0, 2.2 * unit), 0.65 * unit, Color(1, 1, 1, 0.60))
	draw_circle(center + Vector2(0, 5.8 * unit), 0.55 * unit, Color(1, 1, 1, 0.45))
	draw_rect(body_rect, accent.darkened(0.25), false, 1.0)
	draw_line(center + Vector2(-5.6 * unit, 0.8 * unit), center + Vector2(-9.8 * unit - arm_swing, 5.8 * unit), accent, 2.0)
	draw_line(center + Vector2(5.6 * unit, 0.8 * unit), center + Vector2(9.8 * unit + arm_swing, 5.8 * unit), accent, 2.0)
	draw_circle(center + Vector2(-9.8 * unit - arm_swing, 5.8 * unit), 1.2 * unit, sleeve)
	draw_circle(center + Vector2(9.8 * unit + arm_swing, 5.8 * unit), 1.2 * unit, sleeve)
	if has_gun:
		var gun_hand := center + Vector2(9.8 * unit + arm_swing, 5.8 * unit)
		var gun_tip := gun_hand + Vector2(4.6 * unit, -1.2 * unit)
		draw_line(gun_hand, gun_tip, Color(0.12, 0.12, 0.14, alpha), 2.7)
		draw_rect(Rect2(gun_tip + Vector2(-1.6 * unit, -0.9 * unit), Vector2(3.2 * unit, 1.8 * unit)), Color(0.20, 0.20, 0.24, alpha), true)
		draw_line(gun_hand + Vector2(-0.8 * unit, 0.2 * unit), gun_hand + Vector2(0.6 * unit, 2.6 * unit), Color(0.15, 0.15, 0.17, alpha), 1.8)
	draw_line(center + Vector2(-2.8 * unit, 12.0 * unit), center + Vector2(-4.0 * unit - leg_swing, 18.6 * unit), accent, 2.3)
	draw_line(center + Vector2(2.8 * unit, 12.0 * unit), center + Vector2(4.0 * unit + leg_swing, 18.6 * unit), accent, 2.3)
	draw_line(center + Vector2(-4.2 * unit - leg_swing, 18.6 * unit), center + Vector2(-1.8 * unit - leg_swing, 18.6 * unit), accent, 2.3)
	draw_line(center + Vector2(4.2 * unit + leg_swing, 18.6 * unit), center + Vector2(1.8 * unit + leg_swing, 18.6 * unit), accent, 2.3)
	draw_ellipse(center + Vector2(-3.0 * unit - leg_swing, 19.2 * unit), 2.4 * unit, 0.95 * unit, Color(0.05, 0.05, 0.06, alpha))
	draw_ellipse(center + Vector2(3.0 * unit + leg_swing, 19.2 * unit), 2.4 * unit, 0.95 * unit, Color(0.05, 0.05, 0.06, alpha))
	draw_line(head_center + Vector2(-3.2 * unit, -1.8 * unit), head_center + Vector2(-1.0 * unit, -2.4 * unit), Color(0.12, 0.08, 0.05, alpha), 1.1)
	draw_line(head_center + Vector2(1.0 * unit, -2.4 * unit), head_center + Vector2(3.2 * unit, -1.8 * unit), Color(0.12, 0.08, 0.05, alpha), 1.1)
	draw_circle(head_center + Vector2(-2.0 * unit, -0.5 * unit), 0.95 * unit, Color(0.10, 0.07, 0.05, alpha))
	draw_circle(head_center + Vector2(2.0 * unit, -0.5 * unit), 0.95 * unit, Color(0.10, 0.07, 0.05, alpha))
	draw_circle(head_center + Vector2(0, 0.8 * unit), 0.5 * unit, Color(0.88, 0.72, 0.62, alpha))
	draw_line(head_center + Vector2(0, 0.7 * unit), head_center + Vector2(-0.7 * unit, 1.8 * unit), Color(0.78, 0.55, 0.45, alpha), 0.9)
	draw_arc(head_center + Vector2(0, 2.3 * unit), 1.8 * unit, 0.15, PI - 0.15, 10, Color(0.45, 0.18, 0.18, alpha), 1.2)

	if person_kind == "woman":
		draw_colored_polygon(
			[
				center + Vector2(-7.0 * unit, 9.6 * unit),
				center + Vector2(7.0 * unit, 9.6 * unit),
				center + Vector2(0.0, (18.5 + sin(anim_phase * 2.2) * 0.7) * unit)
			],
			outfit.lightened(0.08)
		)
	elif person_kind == "grandma":
		var cane_tip := center + Vector2((11.0 + sin(anim_phase * 1.6) * 0.9) * unit, 14.0 * unit)
		draw_line(center + Vector2(7.0 * unit, 4.0 * unit), cane_tip, Color(0.55, 0.45, 0.30, alpha), 2.0)
		draw_circle(cane_tip, 1.8 * unit, Color(0.55, 0.45, 0.30, alpha))
	elif person_kind == "grandpa":
		var glasses_y := (2.6 + sin(anim_phase * 3.0) * 0.25) * unit
		draw_circle(head_center + Vector2(-2.1 * unit, 0.1 * unit), 1.7 * unit, Color(0.80, 0.86, 0.92, 0.55))
		draw_circle(head_center + Vector2(2.1 * unit, 0.1 * unit), 1.7 * unit, Color(0.80, 0.86, 0.92, 0.55))
		draw_line(head_center + Vector2(-3.5 * unit, glasses_y), head_center + Vector2(3.5 * unit, glasses_y), Color(0.72, 0.72, 0.72, alpha), 1.3)
		draw_line(head_center + Vector2(0, 4.0 * unit), head_center + Vector2(0, 5.4 * unit), Color(0.72, 0.72, 0.72, alpha), 1.2)

func draw_maniac() -> void:
	for i in range(maniac_cells.size()):
		var unit := CELL_SIZE / 36.0
		var center := maniac_center(i)
		var sway := sin(person_anim_time * 4.0 + float(i) * 1.4) * 1.2 * unit
		var body := Rect2(center + Vector2(-6.2 * unit, -1.2 * unit), Vector2(12.4 * unit, 14.8 * unit))
		var blade_start := center + Vector2(12.6 * unit + sway, 2.6 * unit + sway * 0.3)
		var blade_rect := Rect2(blade_start, Vector2(13.0 * unit, 4.2 * unit))
		draw_ellipse(center + Vector2(0, 14.0 * unit), 7.6 * unit, 2.8 * unit, Color(0, 0, 0, 0.22))
		draw_circle(center + Vector2(0, -8.0 * unit), 6.4 * unit, Color(0.42, 0.02, 0.02, 0.28))
		draw_circle(center + Vector2(0, -8.0 * unit), 5.6 * unit, Color(0.95, 0.82, 0.68))
		draw_circle(center + Vector2(0, -11.6 * unit), 5.1 * unit, Color(0.16, 0.13, 0.11))
		draw_rect(Rect2(center + Vector2(-6.8 * unit, -6.4 * unit), Vector2(13.6 * unit, 2.2 * unit)), Color(0.20, 0.06, 0.05), true)
		draw_rect(body, Color(0.66, 0.12, 0.12), true)
		draw_rect(Rect2(body.position + Vector2(1.0 * unit, 1.0 * unit), Vector2(body.size.x - 2.0 * unit, 2.0 * unit)), Color(0.86, 0.22, 0.20), true)
		draw_rect(body, Color(0.30, 0.05, 0.05), false, 1.0)
		draw_circle(center + Vector2(-2.0 * unit, -8.3 * unit), 0.9 * unit, Color(0.05, 0.03, 0.03))
		draw_circle(center + Vector2(2.0 * unit, -8.3 * unit), 0.9 * unit, Color(0.05, 0.03, 0.03))
		draw_arc(center + Vector2(0, -4.8 * unit), 2.3 * unit, 0.15, PI - 0.15, 10, Color(0.30, 0.02, 0.02), 1.4)
		draw_line(center + Vector2(6.0 * unit, 1.5 * unit), center + Vector2(14.0 * unit + sway, 4.0 * unit + sway * 0.3), Color(0.20, 0.20, 0.20), 2.8)
		draw_rect(blade_rect, Color(0.72, 0.72, 0.72), true)
		draw_rect(blade_rect, Color(0.22, 0.22, 0.22), false, 1.0)
		for tooth_idx in range(5):
			var tooth_x := blade_start.x + float(tooth_idx) * 2.4 * unit
			draw_line(Vector2(tooth_x, blade_start.y + 4.2 * unit), Vector2(tooth_x + 1.2 * unit, blade_start.y + 6.2 * unit), Color(0.93, 0.93, 0.93), 1.0)
		draw_line(center + Vector2(13.6 * unit + sway, 2.3 * unit + sway * 0.3), center + Vector2(24.0 * unit + sway, 2.3 * unit + sway * 0.3), Color(0.96, 0.17, 0.17), 1.5)
		draw_circle(blade_start + Vector2(8.0 * unit, 2.0 * unit), 1.7 * unit, Color(0.78, 0.03, 0.04, 0.80))
		draw_circle(blade_start + Vector2(12.0 * unit, 4.2 * unit), 1.2 * unit, Color(0.95, 0.04, 0.04, 0.72))
		draw_circle(blade_start + Vector2(16.0 * unit, 1.0 * unit), 0.8 * unit, Color(0.95, 0.04, 0.04, 0.50))
		draw_line(center + Vector2(-2.8 * unit, 12.0 * unit), center + Vector2(-4.0 * unit - sway * 0.3, 17.0 * unit), Color(0.18, 0.18, 0.18), 2.1)
		draw_line(center + Vector2(2.8 * unit, 12.0 * unit), center + Vector2(4.0 * unit + sway * 0.3, 17.0 * unit), Color(0.18, 0.18, 0.18), 2.1)
		draw_circle(center + Vector2(-2.0 * unit, -8.0 * unit), 0.85 * unit, Color(0.02, 0.02, 0.02))
		draw_circle(center + Vector2(2.0 * unit, -8.0 * unit), 0.85 * unit, Color(0.02, 0.02, 0.02))

func draw_raptor() -> void:
	if not raptor_active:
		return
	var center := raptor_center()
	var unit := CELL_SIZE / 34.0
	var pace := sin(person_anim_time * 8.0) * 1.1 * unit
	var tail_tip := center + Vector2(-16.0 * unit, -5.0 * unit + pace)
	var torso := PackedVector2Array([
		center + Vector2(-10.0 * unit, 3.2 * unit),
		center + Vector2(-3.0 * unit, -6.0 * unit),
		center + Vector2(8.8 * unit, -5.0 * unit),
		center + Vector2(13.0 * unit, 1.8 * unit),
		center + Vector2(5.4 * unit, 7.0 * unit),
		center + Vector2(-3.0 * unit, 7.8 * unit)
	])
	var head := PackedVector2Array([
		center + Vector2(11.5 * unit, -4.8 * unit),
		center + Vector2(18.0 * unit, -6.0 * unit),
		center + Vector2(22.0 * unit, -2.5 * unit),
		center + Vector2(19.0 * unit, 1.8 * unit),
		center + Vector2(12.0 * unit, 0.6 * unit)
	])
	draw_ellipse(center + Vector2(0, 10.8 * unit), 9.5 * unit, 2.8 * unit, Color(0, 0, 0, 0.22))
	draw_line(center + Vector2(-8.0 * unit, -0.5 * unit), tail_tip, Color(0.26, 0.48, 0.14), 4.6)
	draw_line(center + Vector2(-8.0 * unit, -0.5 * unit), tail_tip, Color(0.10, 0.18, 0.05), 1.2)
	draw_colored_polygon(torso, Color(0.48, 0.72, 0.22))
	draw_colored_polygon(head, Color(0.54, 0.78, 0.26))
	draw_polyline(PackedVector2Array([center + Vector2(-8.5 * unit, -2.2 * unit), center + Vector2(5.5 * unit, -4.2 * unit), center + Vector2(16.0 * unit, -3.5 * unit)]), Color(0.20, 0.34, 0.09, 0.85), 2.2, true)
	draw_line(center + Vector2(-2.0 * unit, 7.4 * unit), center + Vector2(-6.0 * unit, 16.0 * unit + pace), Color(0.18, 0.20, 0.14), 2.4)
	draw_line(center + Vector2(4.0 * unit, 7.4 * unit), center + Vector2(8.0 * unit, 15.5 * unit - pace), Color(0.18, 0.20, 0.14), 2.4)
	draw_line(center + Vector2(8.0 * unit, 1.0 * unit), center + Vector2(14.0 * unit, 8.0 * unit), Color(0.18, 0.20, 0.14), 2.0)
	draw_circle(center + Vector2(17.0 * unit, -3.6 * unit), 1.0 * unit, Color(0.10, 0.08, 0.04))
	draw_arc(center + Vector2(18.0 * unit, -0.4 * unit), 3.0 * unit, 0.08, PI - 0.08, 8, Color(0.28, 0.12, 0.08), 1.4)
	for tooth_idx in range(4):
		var tooth_x := 17.0 * unit + float(tooth_idx) * 1.4 * unit
		draw_line(center + Vector2(tooth_x, 0.6 * unit), center + Vector2(tooth_x + 0.6 * unit, 2.0 * unit), Color(0.92, 0.92, 0.86), 0.9)

func debug_board_ascii() -> String:
	var rows: Array[String] = []
	for y in range(GRID_SIZE.y):
		var row := ""
		for x in range(GRID_SIZE.x):
			var cell := Vector2i(x, y)
			if cell == snake[0]:
				row += "H"
			elif snake.has(cell):
				row += "S"
			elif raptor_active and cell == raptor_cell:
				row += "V"
			elif find_maniac_index_at_cell(cell) != -1:
				row += "X"
			elif find_person_index_at_cell(cell) != -1:
				row += "P"
			else:
				row += "."
		rows.append(row)
	return "\n".join(rows)
