extends Resource
class_name CharacterPortrait

@export var character_name: String
@export var expressions: Array[CharacterExpression] = []

func get_texture(expression_name: String) -> Texture2D:
	for e in expressions:
		if e.expression_name == expression_name:
			return e.texture
	return null
