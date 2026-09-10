extends Node

const SAVE_PATH := "user://savegame.save"

var current_resource_path: String = ""
var current_line_id: String = ""

func _ready() -> void:
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.got_dialogue.connect(_on_got_dialogue)

func _on_dialogue_started(resource: DialogueResource) -> void:
	current_resource_path = resource.resource_path

func _on_got_dialogue(line: DialogueLine) -> void:
	if line:
		current_line_id = line.id

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
	var data := {
		"resource_path": current_resource_path,
		"line_id": current_line_id,
		"game_states": _serialize_game_states(),
		"timestamp": Time.get_datetime_string_from_system()
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func load_game() -> void:
	if not has_save():
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	if data.is_empty() or not data.has("resource_path"):
		return

	_clear_current_balloon()
	_deserialize_game_states(data.get("game_states", {}))
	var resource: DialogueResource = load(data["resource_path"])
	DialogueManager.show_dialogue_balloon(resource, data["line_id"])

func _clear_current_balloon() -> void:
	for balloon in get_tree().get_nodes_in_group("dialogue_balloon"):
		balloon.queue_free()

func _serialize_game_states() -> Dictionary:
	var states := {}
	for state in DialogueManager.game_states:
		if typeof(state) == TYPE_DICTIONARY:
			states[str(state)] = state
			continue

		var state_name: String = state.get_script().get_global_name() if state.get_script() else str(state)
		var vars := {}
		for prop in state.get_property_list():
			if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
				vars[prop.name] = state.get(prop.name)
		states[state_name] = vars
	return states

func _deserialize_game_states(states: Dictionary) -> void:
	for state in DialogueManager.game_states:
		if typeof(state) == TYPE_DICTIONARY:
			continue

		var state_name: String = state.get_script().get_global_name() if state.get_script() else str(state)
		if states.has(state_name):
			for key in states[state_name]:
				state.set(key, states[state_name][key])
