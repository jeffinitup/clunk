### window_level_properties.gd
class_name WindowLevelProperties extends Window

## Sent when a field is changed
signal field_changed(property : String, value : Variant)

## Packed scene for LUT picker
@onready var lut_menu := preload("res://scene/color_lut_picker.tscn")

## Reference to level
var level : Level
## Reference to action manager
var action_manager : ActionManager

func title_changed(string : String) -> void:
	pass

func author_changed(string : String) -> void:
	pass

func open_palette_menu() -> void:
	pass
