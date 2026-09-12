extends Control
@export var dialogue_resource: DialogueResource

func _ready() -> void:
	if SaveManager.is_loading:
		return
		
	DialogueManager.show_dialogue_balloon(dialogue_resource, "start")
