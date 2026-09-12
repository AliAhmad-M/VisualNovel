extends Node

signal theme_changed(is_dark_mode: bool)

const SETTINGS_PATH := "user://settings.cfg"

var dark_mode: bool = true:
	set(value):
		if dark_mode != value:
			dark_mode = value
			theme_changed.emit(dark_mode)
			save_settings()

func _ready() -> void:
	load_settings()
	theme_changed.emit(dark_mode)

func toggle_theme() -> void:
	self.dark_mode = !dark_mode

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("display", "dark_mode", dark_mode)
	config.save(SETTINGS_PATH)

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		dark_mode = config.get_value("display", "dark_mode", true)
