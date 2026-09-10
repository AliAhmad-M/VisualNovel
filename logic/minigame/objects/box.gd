extends RigidBody2D

@export var moveable: bool = true:
	set(value):
		moveable = value
		_update_moveable()

func _ready() -> void:
	_update_moveable()

func _update_moveable() -> void:
	freeze_mode = FREEZE_MODE_KINEMATIC
