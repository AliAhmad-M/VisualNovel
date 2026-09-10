extends Node2D

@export var door: Door

func _on_area_body_entered(body: Node2D) -> void:
	if body is Player and door:
		door.is_locked = false
		door.sprite.frame_coords.x = door.UNLOCKED_FRAME_X
		queue_free()
