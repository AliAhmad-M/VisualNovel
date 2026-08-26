extends HBoxContainer
class_name DialogueMenu

@export_category("Light Mode")
@export_subgroup("Continue")
@export var continue_normal_tex_light: Texture2D
@export var continue_hover_tex_light: Texture2D
@export var continue_pressed_tex_light: Texture2D

@export_subgroup("Skip")
@export var skip_normal_tex_light: Texture2D
@export var skip_hover_tex_light: Texture2D
@export var skip_pressed_tex_light: Texture2D

@export_subgroup("Save")
@export var save_normal_tex_light: Texture2D
@export var save_hover_tex_light: Texture2D
@export var save_pressed_tex_light: Texture2D

@export_subgroup("Load")
@export var load_normal_tex_light: Texture2D
@export var load_hover_tex_light: Texture2D
@export var load_pressed_tex_light: Texture2D

@export_subgroup("History")
@export var history_normal_tex_light: Texture2D
@export var history_hover_tex_light: Texture2D
@export var history_pressed_tex_light: Texture2D

@export_subgroup("Options")
@export var options_normal_tex_light: Texture2D
@export var options_hover_tex_light: Texture2D
@export var options_pressed_tex_light: Texture2D

@export_category("Dark Mode")
@export_subgroup("Continue")
@export var continue_normal_tex_dark: Texture2D
@export var continue_hover_tex_dark: Texture2D
@export var continue_pressed_tex_dark: Texture2D

@export_subgroup("Skip")
@export var skip_normal_tex_dark: Texture2D
@export var skip_hover_tex_dark: Texture2D
@export var skip_pressed_tex_dark: Texture2D

@export_subgroup("Save")
@export var save_normal_tex_dark: Texture2D
@export var save_hover_tex_dark: Texture2D
@export var save_pressed_tex_dark: Texture2D

@export_subgroup("Load")
@export var load_normal_tex_dark: Texture2D
@export var load_hover_tex_dark: Texture2D
@export var load_pressed_tex_dark: Texture2D

@export_subgroup("History")
@export var history_normal_tex_dark: Texture2D
@export var history_hover_tex_dark: Texture2D
@export var history_pressed_tex_dark: Texture2D

@export_subgroup("Options")
@export var options_normal_tex_dark: Texture2D
@export var options_hover_tex_dark: Texture2D
@export var options_pressed_tex_dark: Texture2D

@onready var continue_btn: TextureButton = $Continue
@onready var skip_btn: TextureButton = $Skip
@onready var save_btn: TextureButton = $Save
@onready var load_btn: TextureButton = $Load
@onready var history_btn: TextureButton = $History
@onready var options_btn: TextureButton = $Options

signal continue_pressed
signal skip_pressed
signal save_pressed
signal load_pressed
signal history_pressed
signal options_pressed

func _ready() -> void:
	if Settings:
		Settings.theme_changed.connect(_on_theme_changed)
		_update_theme(Settings.dark_mode)

func _on_theme_changed(is_dark_mode: bool) -> void:
	_update_theme(is_dark_mode)
	
func _update_theme(is_dark: bool) -> void:
	if is_dark:
		_apply_textures(continue_btn, continue_normal_tex_dark, continue_hover_tex_dark, continue_pressed_tex_dark)
		_apply_textures(skip_btn, skip_normal_tex_dark, skip_hover_tex_dark, skip_pressed_tex_dark)
		_apply_textures(save_btn, save_normal_tex_dark, save_hover_tex_dark, save_pressed_tex_dark)
		_apply_textures(load_btn, load_normal_tex_dark, load_hover_tex_dark, load_pressed_tex_dark)
		_apply_textures(history_btn, history_normal_tex_dark, history_hover_tex_dark, history_pressed_tex_dark)
		_apply_textures(options_btn, options_normal_tex_dark, options_hover_tex_dark, options_pressed_tex_dark)
	else:
		_apply_textures(continue_btn, continue_normal_tex_light, continue_hover_tex_light, continue_pressed_tex_light)
		_apply_textures(skip_btn, skip_normal_tex_light, skip_hover_tex_light, skip_pressed_tex_light)
		_apply_textures(save_btn, save_normal_tex_light, save_hover_tex_light, save_pressed_tex_light)
		_apply_textures(load_btn, load_normal_tex_light, load_hover_tex_light, load_pressed_tex_light)
		_apply_textures(history_btn, history_normal_tex_light, history_hover_tex_light, history_pressed_tex_light)
		_apply_textures(options_btn, options_normal_tex_light, options_hover_tex_light, options_pressed_tex_light)

func _apply_textures(btn: TextureButton, normal: Texture2D, hover: Texture2D, pressed: Texture2D) -> void:
	btn.texture_normal = normal
	btn.texture_hover = hover
	btn.texture_pressed = pressed

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
