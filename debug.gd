extends Control
@export var dialogue_resource: DialogueResource

func _ready() -> void:
	DialogueManager.show_dialogue_balloon(dialogue_resource, "start")
