extends Control
@export var dialogue_resource: DialogueResource

func _ready() -> void:
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	
	if SaveManager.is_loading:
		return

	DialogueManager.show_dialogue_balloon(dialogue_resource, "start")

func _on_dialogue_ended(resource: DialogueResource) -> void:
	if resource != dialogue_resource:
		return

	var next_act_name = GameState["next_act"]
	if next_act_name:
		get_tree().change_scene_to_file("res://logic/acts/%s.tscn" % next_act_name)
