class_name Player
extends CharacterBody2D

@export_group("Movement")
@export var max_speed: float = 250.0
@export var acceleration: float = 1600.0
@export var friction: float = 1800.0
@export var air_acceleration: float = 1000.0
@export var air_friction: float = 800.0

@export_group("Jump")
@export var jump_velocity: float = -500.0
@export var jump_cut_multiplier: float = 0.5
@export var gravity_scale: float = 1.0
@export var fall_gravity_multiplier: float = 1.4
@export var max_fall_speed: float = 650.0
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1

@export_group("Dash")
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.35
@export var can_air_dash: bool = true
@export var dash_end_speed_cap: float = 300.0
@export var air_dash_safety_timeout: float = 2.0

@export_group("Trail Effect")
@export var trail_spawn_interval: float = 0.015
@export var trail_lifetime: float = 0.3
@export var trail_color: Color = Color(1, 1, 1, 0.65)
@export var trail_hard_fade: bool = true

@export_group("Juice")
@export var enable_landing_squash: bool = true

@onready var sprite: Sprite2D = $Sprite

const START_FRAME: int = 240
const ANIM_FPS: int = 10
const HFRAMES: int = 7
const VFRAMES: int = 4
const COL_GAP: int = 20

const IDLE_FRAME: int = 0
const RUN_FRAMES: Array[int] = [1, 2, 3, 4]
const JUMP_FRAME: int = 5
const DEATH_FRAME: int = 6

@export var wing_fps: float = 8.0

var _run_timer: float = 0.0
var _run_frame_index: int = 0

var _wing_timer: float = 0.0
var _wing_frame: int = 0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

enum State { NORMAL, DASH }
var state: State = State.NORMAL

# Timers
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_timer: float = 0.0
var _ground_trail_timer: float = 0.0
var _air_trail_timer: float = 0.0

# State flags
var has_air_dashed: bool = false
var is_ground_dash: bool = false
var _air_trailing: bool = false
var dash_direction: Vector2 = Vector2.ZERO
var facing_direction: int = 1

signal jumped
signal landed
signal dashed(direction: Vector2)
signal dash_ended

func _physics_process(delta: float) -> void:
	_update_timers(delta)

	if state == State.DASH:
		_process_dash(delta)
	else:
		_handle_horizontal_movement(delta)
		_apply_gravity(delta)
		_handle_jump_input()
		_handle_dash_input()

	var floor_before := is_on_floor()
	move_and_slide()
	var floor_after := is_on_floor()

	if _air_trailing:
		_update_air_trail(delta, floor_after)

	if floor_after and not floor_before:
		_on_landed()

	_update_facing()
	_update_animation(delta)

# Coyote and jump buffer timers
func _update_timers(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
		has_air_dashed = false
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)

	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer = max(dash_cooldown_timer - delta, 0.0)


# Normal movement
func _handle_horizontal_movement(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")
	var accel := acceleration if is_on_floor() else air_acceleration
	var fric := friction if is_on_floor() else air_friction

	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * max_speed, accel * delta)
		facing_direction = signi(int(dir))
	else:
		velocity.x = move_toward(velocity.x, 0.0, fric * delta)

func _apply_gravity(delta: float) -> void:
	if velocity.y < 0.0:
		velocity.y += gravity * gravity_scale * delta
	else:
		velocity.y += gravity * gravity_scale * fall_gravity_multiplier * delta
	velocity.y = min(velocity.y, max_fall_speed)

func _handle_jump_input() -> void:
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		jumped.emit()

	# Variable jump height
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier


# Dash
func _handle_dash_input() -> void:
	if dash_cooldown_timer > 0.0 or not Input.is_action_just_pressed("dash"):
		return

	var grounded := is_on_floor()
	if grounded or (can_air_dash and not has_air_dashed):
		_start_dash(grounded)


func _start_dash(grounded: bool) -> void:
	state = State.DASH
	is_ground_dash = grounded
	dash_timer = dash_duration
	if not grounded:
		has_air_dashed = true

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir == Vector2.ZERO:
		input_dir = Vector2(facing_direction, 0.0)
	dash_direction = input_dir.normalized()

	velocity = dash_direction * dash_speed
	_ground_trail_timer = 0.0
	_spawn_trail_ghost()
	dashed.emit(dash_direction)

func _process_dash(delta: float) -> void:
	dash_timer -= delta
	velocity = dash_direction * dash_speed   # no gravity

	_ground_trail_timer -= delta
	if _ground_trail_timer <= 0.0:
		_spawn_trail_ghost()
		_ground_trail_timer = trail_spawn_interval

	if dash_timer <= 0.0:
		_end_dash()

func _check_dash_end(is_grounded_now: bool) -> void:
	var finished: bool
	if is_ground_dash:
		# On-ground horizontal dash
		finished = dash_timer <= 0.0
	else:
		# Air dash
		finished = is_grounded_now or dash_timer <= -air_dash_safety_timeout

	if finished:
		_end_dash()

func _end_dash() -> void:
	state = State.NORMAL
	dash_cooldown_timer = dash_cooldown
	velocity.x = clamp(velocity.x, -dash_end_speed_cap, dash_end_speed_cap)
	if velocity.y < 0.0:
		velocity.y = 0.0

	if not is_ground_dash:
		_air_trailing = true
		_air_trail_timer = air_dash_safety_timeout

	dash_ended.emit()

func _update_air_trail(delta: float, is_grounded_now: bool) -> void:
	_air_trail_timer -= delta
	if is_grounded_now or _air_trail_timer <= 0.0:
		_air_trailing = false
		return

	_ground_trail_timer -= delta
	if _ground_trail_timer <= 0.0:
		_spawn_trail_ghost()
		_ground_trail_timer = trail_spawn_interval

# Afterimage effect
func _spawn_trail_ghost() -> void:
	if not sprite or sprite.texture == null:
		return

	var ghost := Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.region_enabled = sprite.region_enabled
	ghost.region_rect = sprite.region_rect
	ghost.hframes = sprite.hframes
	ghost.vframes = sprite.vframes
	ghost.flip_h = sprite.flip_h

	var ghost_h_frame: int = RUN_FRAMES[_run_frame_index]
	ghost.frame = START_FRAME + ghost_h_frame + _wing_frame * COL_GAP

	ghost.position = position
	ghost.rotation = rotation
	ghost.scale = scale
	ghost.modulate = trail_color
	ghost.z_index = z_index
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	get_parent().add_child(ghost)

	if trail_hard_fade:
		var timer := get_tree().create_timer(trail_lifetime)
		timer.timeout.connect(ghost.queue_free)
	else:
		var tw := create_tween()
		tw.tween_property(ghost, "modulate:a", 0.0, trail_lifetime)
		tw.tween_callback(ghost.queue_free)
		
func _update_facing() -> void:
	if not sprite:
		return
	if facing_direction != 0:
		sprite.flip_h = facing_direction < 0

func _update_animation(delta: float) -> void:
	var h_frame := _get_h_frame(delta)
	var v_frame := _advance_wing_frame(delta)
	
	sprite.frame = START_FRAME + h_frame + v_frame * COL_GAP

func _get_h_frame(delta: float) -> int:
	if state == State.DASH:
		return JUMP_FRAME if not is_on_floor() else IDLE_FRAME
	elif not is_on_floor():
		return JUMP_FRAME
	elif absf(velocity.x) > 10.0:
		return _advance_run_frame(delta)
	else:
		_run_frame_index = 0
		_run_timer = 0.0
		return IDLE_FRAME

func _advance_run_frame(delta: float) -> int:
	_run_timer += delta
	var frame_time := 1.0 / float(ANIM_FPS)

	while _run_timer >= frame_time:
		_run_timer -= frame_time
		_run_frame_index = (_run_frame_index + 1) % (RUN_FRAMES.size() - 1)
		
	return RUN_FRAMES[_run_frame_index]

func _advance_wing_frame(delta: float) -> int:
	_wing_timer += delta
	var frame_time := 1.0 / wing_fps

	while _wing_timer >= frame_time:
		_wing_timer -= frame_time
		_wing_frame = (_wing_frame + 1) % VFRAMES   # loops 0,1,2,3,0,1,2,3...
	
	return _wing_frame

func _on_landed() -> void:
	has_air_dashed = false
	landed.emit()
	if enable_landing_squash:
		_play_land_squash()

func _play_land_squash() -> void:
	if not sprite:
		return
	var base_scale: Vector2 = sprite.scale
	sprite.scale = Vector2(base_scale.x * 1.2, base_scale.y * 0.7)
	var tw := create_tween()
	tw.tween_property(sprite, "scale", base_scale, 0.12) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
