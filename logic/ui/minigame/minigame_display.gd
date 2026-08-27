extends Control
class_name MinigameDisplay

signal minigame_finished(result: Variant)

@onready var game_console: TextureRect = $GameConsole
@onready var screen: Control = $GameConsole/Screen

var current_minigame: Node = null

func _ready() -> void:
	visible = false

func show_display() -> void:
	visible = true

func hide_display() -> void:
	visible = false

func load_minigame(minigame_scene: PackedScene) -> void:
	_clear_minigame()
	current_minigame = minigame_scene.instantiate()
	screen.add_child(current_minigame)
	# Every minigame emits a finished signal when done
	if current_minigame.has_signal("finished"):
		current_minigame.finished.connect(_on_minigame_finished)

func _on_minigame_finished(result: Variant = null) -> void:
	_clear_minigame()
	minigame_finished.emit(result)

func _clear_minigame() -> void:
	if current_minigame:
		current_minigame.queue_free()
		current_minigame = null
