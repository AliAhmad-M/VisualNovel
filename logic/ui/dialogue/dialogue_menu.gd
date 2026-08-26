extends HBoxContainer
class_name DialogueMenu

signal continue_pressed
signal skip_pressed
signal save_pressed
signal load_pressed
signal history_pressed
signal options_pressed

func _on_continue_pressed() -> void:
	continue_pressed.emit()

func _on_skip_pressed() -> void:
	skip_pressed.emit()

func _on_save_pressed() -> void:
	save_pressed.emit()

func _on_load_pressed() -> void:
	load_pressed.emit()

func _on_history_pressed() -> void:
	history_pressed.emit()

func _on_options_pressed() -> void:
	options_pressed.emit()
