extends Control
class_name CharacterStage

@onready var slot: TextureRect = $Slot

@export var slide_time: float = 0.35
@export var slide_trans : = Tween.TRANS_CUBIC
@export var slide_ease := Tween.EASE_OUT
@export var portrait_entries: Array[CharacterPortrait] = []

var portraits: Dictionary = {}
var _current_character: String = ""
var _rest_x: float

func _ready() -> void:
	# Initialize portraits
	for entry in portrait_entries:
		portraits[entry.character_name] = entry.texture
		
	_rest_x = slot.position.x
	slot.modulate.a = 0.0
	slot.position.x = _enter_x()

func show_speaker(character_name: String) -> void:
	# No character sprite (e.g. narrator)
	if not portraits.has(character_name):
		return
	
	# Character already in the scene
	if character_name == _current_character:
		return
		
	# Slide in the first character
	if _current_character == "":
		_slide_in(character_name)
	
	# Swap to new character otherwise
	else:
		_swap_to(character_name)

func clear_all() -> void:
	# End of scene
	if _current_character != "":
		await _slide_out()

func _slide_in(character_name: String) -> void:
	slot.texture = portraits[character_name]
	slot.position.x = _enter_x()
	_current_character = character_name

	# Interpolate to rest position
	var tw := create_tween().set_parallel(true)
	tw.set_trans(slide_trans).set_ease(slide_ease)
	tw.tween_property(slot, "position:x", _rest_x, slide_time)
	tw.tween_property(slot, "modulate:a", 1.0, slide_time)

func _slide_out() -> void:
	_current_character = ""

	# Interpolate out of screen
	var tw := create_tween().set_parallel(true)
	tw.set_trans(slide_trans).set_ease(slide_ease)
	tw.tween_property(slot, "position:x", _exit_x(), slide_time)
	tw.tween_property(slot, "modulate:a", 0.0, slide_time)
	await tw.finished


func _swap_to(character_name: String) -> void:
	# Slide out old character, slide in new one
	await _slide_out()
	_slide_in(character_name)

func _enter_x() -> float:
	return get_viewport_rect().size.x

func _exit_x() -> float:
	return -slot.size.x
