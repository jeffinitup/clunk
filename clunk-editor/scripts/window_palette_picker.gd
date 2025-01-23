### window_palette_picker.gd
class_name WindowPalettePicker extends Window

## Fired when color in palette is changed
signal palette_color_changed(ind : int, color : Color)
## Fired when full palette is loaded
signal palette_loaded(palette : Palette)

## Color picker button to instance
@onready var cpick := $color as ColorPickerButton
## Grid container
@onready var grid := $margin/sort/center/grid as GridContainer

## Level palette
var level_palette : Palette

func _ready() -> void:
	build_buttons(level_palette)

func build_buttons(palette : Palette) -> void:
	# Clear grid container
	for child in grid.get_children():
		child.queue_free()
	
	# Populate container
	for i in range(Palette.SIZE):
		var button := cpick.duplicate() as ColorPickerButton
		button.visible = true
		button.color = palette.color[i]
		button.popup_closed.connect(func() -> void:
			palette_color_changed.emit(i, button.color)
			level_palette.color[i] = button.color
		)
		grid.add_child(button)

func load_mpal() -> void:
	var window := FileDialog.new()
	window.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	window.access = FileDialog.ACCESS_FILESYSTEM
	window.add_filter("*.mpal", "CLANG palette file")
	window.file_selected.connect(rebuild_palette.bind())
	window.show()

func rebuild_palette(path : String) -> void:
	var palette : Palette = Palette.new(path)
	palette_loaded.emit(palette)
	build_buttons(palette)
	level_palette = palette

func save_mpal() -> void:
	var window := FileDialog.new()
	window.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	window.access = FileDialog.ACCESS_FILESYSTEM
	window.add_filter("*.mpal", "CLANG palette file")
	window.file_selected.connect(func(path : String) -> void:
		level_palette.serialize(path))
	window.show()

func close_requested() -> void:
	queue_free()
