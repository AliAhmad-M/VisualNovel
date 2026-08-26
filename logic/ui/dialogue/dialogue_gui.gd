extends Control

@export var choice_normal_tex: Texture2D
@export var choice_hover_tex: Texture2D
@export var choice_pressed_tex: Texture2D

@onready var name_label: Label = $DialogueTexture/NameLabel
@onready var dialogue_label: DialogueLabel = $DialogueTexture/DialogueLabel
@onready var choices_box: VBoxContainer = $DialogueTexture/ChoicesBox
@onready var character_stage: CharacterStage = $CharacterStage
@onready var dialogue_menu: DialogueMenu = $DialogueMenu

var resource: DialogueResource
var current_line: DialogueLine
var is_typing: bool = false
var waiting_for_tap: bool = false

var is_skipping: bool = false
var _last_speaker: String = ""

var choices_box_base_y: float
var choice_button_w: float
var choice_button_h: float

func _ready() -> void:
	# Connect signals to labels
	dialogue_label.started_typing.connect(func(): is_typing = true)
	dialogue_label.finished_typing.connect(func(): is_typing = false)

	# Configure the choice buttons
	choices_box_base_y = choices_box.position.y
	choice_button_w = choice_normal_tex.get_size().x * 0.5
	choice_button_h = choice_normal_tex.get_size().y * 0.7

	# Menu
	dialogue_menu.continue_pressed.connect(advance)
	dialogue_menu.skip_pressed.connect(toggle_skip)

func toggle_skip() -> void:
	is_skipping = not is_skipping
	
	if not is_skipping:
		return
		
	if choices_box.visible:
		is_skipping = false
		return
		
	if is_typing:
		dialogue_label.visible_ratio = 1.0
		
	elif waiting_for_tap:
		waiting_for_tap = false
		_next(current_line.next_id)
	
func start(dialogue_resource: DialogueResource, cue: String = "", extra_game_states: Array = []) -> void:
	resource = dialogue_resource
	is_skipping = false
	_last_speaker = ""
	visible = true
	_next(cue, extra_game_states)

func _next(cue: String, extra_game_states: Array = []) -> void:
	# Get next line
	current_line = await DialogueManager.get_next_dialogue_line(resource, cue, extra_game_states)
	
	if not current_line:
		is_skipping = false
		await character_stage.clear_all()
		visible = false
		return
	
	# Display the line
	_show_line(current_line)
	
func _show_line(line: DialogueLine) -> void:
	# Skip stops the moment the speaker changes
	if is_skipping and _last_speaker != "" and line.character != _last_speaker:
		is_skipping = false
	_last_speaker = line.character

	# Clear previous choices
	for c in choices_box.get_children():
		c.queue_free()
	choices_box.visible = false
	choices_box.position.y = choices_box_base_y

	# Display name
	name_label.text = line.character
	character_stage.show_speaker(line.character, line.get_tag_value("mood"))

	# Show dialogue
	dialogue_label.dialogue_line = line
	if is_skipping:
		dialogue_label.visible_ratio = 1.0
	else:
		dialogue_label.type_out()
		await dialogue_label.finished_typing

	# Show choices
	var allowed_responses := line.responses.filter(func(r): return r.is_allowed)
	if allowed_responses.size() > 0:
		# Stop and wait for the player to pick
		is_skipping = false
		for i in range(allowed_responses.size()):
			var response = allowed_responses[i]
			var btn := _make_choice_button(response.text)
			btn.pressed.connect(_next.bind(response.next_id, []))
			choices_box.add_child(btn)
			
			if i > 0:
				choices_box.position.y -= choice_button_h
		choices_box.visible = true
		
	elif is_skipping:
		# keep chaining
		_next(current_line.next_id)
		
	else:
		waiting_for_tap = true
		
func _make_choice_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	
	# Add textures for button
	var sb_normal := StyleBoxTexture.new()
	sb_normal.texture = choice_normal_tex
	var sb_hover := StyleBoxTexture.new()
	sb_hover.texture = choice_hover_tex
	var sb_pressed := StyleBoxTexture.new()
	sb_pressed.texture = choice_pressed_tex
	
	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_stylebox_override("focus", sb_hover)
	
	# Set texture size
	btn.custom_minimum_size = Vector2(choice_button_w, choice_button_h)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Configure font
	btn.add_theme_color_override("font_color", Color.BLACK)
	btn.add_theme_color_override("font_hover_color", Color.BLACK)
	btn.add_theme_color_override("font_pressed_color", Color.BLACK)
	btn.add_theme_color_override("font_focus_color", Color.BLACK)
	btn.add_theme_font_size_override("font_size", 24)
	
	return btn
	
func advance() -> void:
	if not visible or choices_box.visible:
		return

	if is_typing:
		dialogue_label.visible_ratio = 1.0
		is_typing = false

	elif waiting_for_tap:
		waiting_for_tap = false
		_next(current_line.next_id)

func _unhandled_input(event: InputEvent) -> void:
	if not visible or choices_box.visible:
		return

	# Handle input
	if event.is_action_pressed("ui_accept") or (event is InputEventScreenTouch and event.pressed):
		advance()
		get_viewport().set_input_as_handled()
