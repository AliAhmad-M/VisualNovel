extends Control
class_name Level

signal finished(result: Variant)

func finish(result: Variant = null) -> void:
	finished.emit(result)
