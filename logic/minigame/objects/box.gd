extends Node2D

@onready var rb: RigidBody2D = $Rigidbody
@onready var sprite: Sprite2D = $Rigidbody/Sprite
@onready var collider: CollisionShape2D = $Rigidbody/Collider

@export var moveable: bool = true:
	set(value):
		moveable = value
		_update_moveable()

func _ready() -> void:
	rb.lock_rotation = true
	sprite.scale = Vector2(4, 4)
	collider.shape = collider.shape.duplicate()
	collider.shape.size *= 4
		
	_update_moveable()

func _update_moveable() -> void:
	rb.freeze = !moveable
