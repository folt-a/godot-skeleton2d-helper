@tool
extends Button

signal dropped(path:String)

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return true

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if data is Dictionary:
		if data.type == "files":
			if not data.is_empty() and data.files[0].begins_with("res://"):
				dropped.emit(data.files[0])
