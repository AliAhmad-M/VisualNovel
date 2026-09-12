extends Control

@export var tutorial: PackedScene

func _on_start_pressed() -> void:
	if not tutorial:
		return
		
	get_tree().change_scene_to_packed(tutorial)

func _on_load_pressed() -> void:
	if not SaveManager.has_save():
		get_tree().change_scene_to_packed(tutorial)

	SaveManager.load_game()

func _on_options_pressed() -> void:
	pass # Replace with function body.

func _on_exit_pressed() -> void:
	get_tree().quit()
