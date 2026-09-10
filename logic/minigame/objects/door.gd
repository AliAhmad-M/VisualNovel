class_name Door
extends Node2D

@export var is_locked: bool = false
@export var current_level: Level

@onready var sprite: Sprite2D = $Sprite
@onready var animation: AnimationPlayer = $AnimationPlayer

const UNLOCKED_FRAME_X = 16
const LOCKED_FRAME_X = 17

func _ready() -> void:
	sprite.frame_coords.x = LOCKED_FRAME_X if is_locked else UNLOCKED_FRAME_X 

func _on_area_body_entered(body: Node2D) -> void:
	if body is Player and not is_locked:
		animation.play("open")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "open" and current_level != null:
		current_level.finish()
		
