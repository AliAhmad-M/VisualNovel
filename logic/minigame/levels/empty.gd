extends Control

signal finished(result: Variant)

func _ready() -> void:
	# Auto-finish after 2 seconds so you can watch the display appear/disappear
	await get_tree().create_timer(2.0).timeout
	finished.emit(null)

func _unhandled_input(event: InputEvent) -> void:
	# Or tap/click to end it early
	if event is InputEventScreenTouch and event.pressed or event.is_action_pressed("ui_accept"):
		finished.emit(null)
		get_viewport().set_input_as_handled()
