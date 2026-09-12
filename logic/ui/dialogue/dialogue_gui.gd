extends Control

@export_category("Minigames")
@export var minigame_entries: Array[MinigameEntry] = []

@export_category("Dialogue Box Textures")
@export_subgroup("Light Mode")
@export var dialogue_box_tex_light: Texture2D

@export_subgroup("Dark Mode")
@export var dialogue_box_tex_dark: Texture2D

@export_category("Choice Button Textures")
@export_subgroup("Light Mode")
@export var choice_normal_tex_light: Texture2D
@export var choice_hover_tex_light: Texture2D
@export var choice_pressed_tex_light: Texture2D

@export_subgroup("Dark Mode")
@export var choice_normal_tex_dark: Texture2D
@export var choice_hover_tex_dark: Texture2D
@export var choice_pressed_tex_dark: Texture2D

@onready var dialogue_box: TextureRect = $DialogueBox
@onready var name_label: Label = $DialogueBox/NameLabel
@onready var dialogue_label: DialogueLabel = $DialogueBox/DialogueLabel
@onready var choices_box: VBoxContainer = $DialogueBox/ChoicesBox
@onready var character_stage: CharacterStage = $CharacterStage
@onready var dialogue_menu: DialogueMenu = $DialogueMenu
@onready var minigame_display: MinigameDisplay = $MinigameDisplay

var resource: DialogueResource
var text_font: Font
var text_color: Color

var current_line: DialogueLine
var is_typing: bool = false
var waiting_for_tap: bool = false

var is_skipping: bool = false
var _last_speaker: String = ""

var minigame_active: bool = false
var _minigames: Dictionary = {}

var choices_box_base_y: float
var choice_button_w: float
var choice_button_h: float

func _ready() -> void:
	add_to_group("dialogue_balloon")
	
	# Initialize all minigames
	for entry in minigame_entries:
		_minigames[entry.minigame_id] = entry.scene
	
	# Connect to theme changes and set initial values
	if Settings:
		Settings.theme_changed.connect(_on_theme_changed)
		_update_theme(Settings.dark_mode)

	# Connect signals to labels
	dialogue_label.started_typing.connect(func(): is_typing = true)
	dialogue_label.finished_typing.connect(func(): is_typing = false)

	# Load the font
	text_font = load("res://assets/fonts/font_xtypewriter_regular.ttf")

	# Configure the choice buttons
	choices_box_base_y = choices_box.position.y
	choice_button_w = choice_normal_tex_light.get_size().x * 0.65
	choice_button_h = choice_normal_tex_light.get_size().y * 0.85

	# Menu
	dialogue_menu.continue_pressed.connect(advance)
	dialogue_menu.skip_pressed.connect(toggle_skip)
	dialogue_menu.save_pressed.connect(SaveManager.save_game)
	dialogue_menu.load_pressed.connect(SaveManager.load_game)
	
	# Minigame
	minigame_display.minigame_finished.connect(_on_minigame_finished)
	
func _on_theme_changed(is_dark_mode: bool) -> void:
	_update_theme(is_dark_mode)

func _update_theme(is_dark: bool) -> void:
	# Update box texture & text color
	dialogue_box.texture = dialogue_box_tex_dark if is_dark else dialogue_box_tex_light
	text_color = Color.WHITE if is_dark else Color.BLACK
	dialogue_label.add_theme_color_override("default_color", text_color)
	
	# Update active choice buttons on screen if there are any
	for child in choices_box.get_children():
		if child is Button:
			_apply_button_theme(child)

func toggle_skip() -> void:
	is_skipping = not is_skipping
	
	if not is_skipping:
		return
		
	if choices_box.visible:
		is_skipping = false
		return
		
	if is_typing:
		dialogue_label.skip_typing()
		
	elif waiting_for_tap:
		waiting_for_tap = false
		_advance_past_current_line()
	
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
	
func _advance_past_current_line() -> void:
	# Launch minigame if there is one
	var minigame_id := current_line.get_tag_value("minigame")
	if minigame_id != "":
		var scene: PackedScene = _minigames.get(minigame_id)
		if scene:
			is_skipping = false
			start_minigame(scene)
			return
		else:
			push_warning("No minigame registered for id: '%s'" % minigame_id)
	_next(current_line.next_id)
	
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
		_advance_past_current_line()
		
	else:
		waiting_for_tap = true
		
func _make_choice_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	
	# Set base settings
	btn.custom_minimum_size = Vector2(choice_button_w, choice_button_h)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_override("font", load("res://assets/fonts/font_xtypewriter_regular.ttf"))
	btn.add_theme_font_size_override("font_size", 28)
	
	# Apply stylebox and colors
	_apply_button_theme(btn)
	
	return btn

func _apply_button_theme(btn: Button) -> void:
	var sb_normal := StyleBoxTexture.new()
	sb_normal.texture = choice_normal_tex_dark if Settings.dark_mode else choice_normal_tex_light
	var sb_hover := StyleBoxTexture.new()
	sb_hover.texture = choice_hover_tex_dark if Settings.dark_mode else choice_hover_tex_light
	var sb_pressed := StyleBoxTexture.new()
	sb_pressed.texture = choice_pressed_tex_dark if Settings.dark_mode else choice_pressed_tex_light
	
	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_stylebox_override("focus", sb_hover)
	
	btn.add_theme_color_override("font_color", text_color)
	btn.add_theme_color_override("font_hover_color", text_color)
	btn.add_theme_color_override("font_pressed_color", text_color)
	btn.add_theme_color_override("font_focus_color", text_color)

func advance() -> void:
	if not visible or choices_box.visible or minigame_active:
		return

	if is_typing:
		dialogue_label.skip_typing()

	elif waiting_for_tap:
		waiting_for_tap = false
		_advance_past_current_line()
		
func start_minigame(minigame_scene: PackedScene) -> void:
	minigame_active = true
	_set_dialogue_ui_visible(false)
	minigame_display.show_display()
	minigame_display.load_minigame(minigame_scene)

func _on_minigame_finished(_result: Variant) -> void:
	minigame_display.hide_display()
	_set_dialogue_ui_visible(true)
	minigame_active = false
	_next(current_line.next_id)

func _set_dialogue_ui_visible(should_show: bool) -> void:
	dialogue_box.visible = should_show
	character_stage.visible = should_show

func _unhandled_input(event: InputEvent) -> void:
	if not visible or choices_box.visible or minigame_active:
		return

	# Handle input
	if event.is_action_pressed("ui_accept") or (event is InputEventScreenTouch and event.pressed):
		advance()
		get_viewport().set_input_as_handled()
