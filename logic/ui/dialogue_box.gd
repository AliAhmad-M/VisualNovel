extends Control

@export var choice_normal_tex: Texture2D
@export var choice_hover_tex: Texture2D
@export var choice_pressed_tex: Texture2D

@onready var name_label: Label = $DialogueTexture/NameLabel
@onready var dialogue_label: DialogueLabel = $DialogueTexture/DialogueLabel
@onready var choices_box: VBoxContainer = $DialogueTexture/ChoicesBox

var resource: DialogueResource
var current_line: DialogueLine
var is_typing := false
var waiting_for_tap := false

var choices_box_base_y: float
var choice_button_height: float

func _ready() -> void:
	dialogue_label.started_typing.connect(func(): is_typing = true)
	dialogue_label.finished_typing.connect(func(): is_typing = false)
	choices_box_base_y = choices_box.position.y
	choice_button_height = choice_normal_tex.get_size().y

func start(dialogue_resource: DialogueResource, cue: String = "", extra_game_states: Array = []) -> void:
	resource = dialogue_resource
	visible = true
	_next(cue, extra_game_states)

func _next(cue: String, extra_game_states: Array = []) -> void:
	current_line = await DialogueManager.get_next_dialogue_line(resource, cue, extra_game_states)
	if not current_line:
		visible = false
		return
	_show_line(current_line)

func _show_line(line: DialogueLine) -> void:
	for c in choices_box.get_children():
		c.queue_free()
	choices_box.visible = false
	choices_box.position.y = choices_box_base_y  # reset before repositioning

	name_label.text = line.character
	dialogue_label.dialogue_line = line
	dialogue_label.type_out()
	await dialogue_label.finished_typing

	var allowed_responses := line.responses.filter(func(r): return r.is_allowed)

	if allowed_responses.size() > 0:
		for i in range(allowed_responses.size()):
			var response = allowed_responses[i]
			var btn := _make_choice_button(response.text)
			btn.pressed.connect(_next.bind(response.next_id, []))
			choices_box.add_child(btn)
			if i > 0:
				choices_box.position.y -= choice_button_height
		choices_box.visible = true
	else:
		waiting_for_tap = true

func _make_choice_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text

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

	# Keep native texture size, don't stretch to container width
	btn.custom_minimum_size = choice_normal_tex.get_size()
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	# Text color + size
	btn.add_theme_color_override("font_color", Color.BLACK)
	btn.add_theme_color_override("font_hover_color", Color.BLACK)
	btn.add_theme_color_override("font_pressed_color", Color.BLACK)
	btn.add_theme_color_override("font_focus_color", Color.BLACK)
	btn.add_theme_font_size_override("font_size", 24)

	return btn

func _unhandled_input(event: InputEvent) -> void:
	if not visible or choices_box.visible:
		return
	if event.is_action_pressed("ui_accept") or (event is InputEventScreenTouch and event.pressed):
		if is_typing:
			dialogue_label.visible_ratio = 1.0
			is_typing = false
		elif waiting_for_tap:
			waiting_for_tap = false
			_next(current_line.next_id)

		get_viewport().set_input_as_handled()
