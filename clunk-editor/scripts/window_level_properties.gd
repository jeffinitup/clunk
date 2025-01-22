### window_level_properties.gd
class_name WindowLevelProperties extends Window

## Sent when a field is changed
signal field_changed(property : String, value : Variant)

## Packed scene for LUT picker
@onready var lut_menu := preload("res://scene/color_lut_picker.tscn")

## Level title field
@onready var f_level_title : LineEdit = $margin/sort/level_title/field
## Level author field
@onready var f_level_author : LineEdit = $margin/sort/level_author/field

## Level resource ref
var level : Level

func _ready() -> void:
	f_level_title.text = level.level_name
	f_level_author.text = level.level_author

var temp_title := ""
func title_changed(string : String) -> void:
	temp_title = string

func title_submitted() -> void:
	field_changed.emit("level_title", temp_title)

var temp_author := ""
func author_changed(string : String) -> void:
	temp_author = string

func author_submitted() -> void:
	field_changed.emit("level_author", temp_author)
	
func open_palette_menu() -> void:
	var menu = lut_menu.instantiate()
	menu.show()
