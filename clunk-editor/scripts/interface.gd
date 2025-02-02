### interface.gd
class_name Interface extends CanvasLayer

## Lines to print
const CONSOLE_HISTORY = 20

## Level properties window
@onready var level_properties_window := preload("res://scene/level_properties.tscn")

## Editor reference
@onready var editor : Editor = owner as Editor
## Main gui panel
@onready var main_panel : PanelContainer = $gui/vsort/main/panel
## Tools list
@onready var tools_list : ItemList = $gui/vsort/main/panel/sort/tools
## Tabs list
@onready var tabs : MenuBar = $gui/vsort/main/tabs
## Tool manager
@onready var tool_manager : ToolManager = %tool_manager
## Console node
@onready var console : RichTextLabel = $gui/vsort/console/text
## Property container
@onready var _properties : VBoxContainer = $gui/vsort/main/panel/sort/properties/container

func _ready() -> void:
	# Print identifier to console
	var version := ProjectSettings.get_setting("application/config/version") as String
	Logger.message_logged.connect(print_to_console.bind())
	Logger.log_default("CLUNK Editor Initialized - Version %s" % version)
	
	# Handle web
	if WebHelper.is_web():
		%File.remove_item(3)

func on_level_load() -> void:
	console.text = ""
	Logger.log_default("Level loaded - %s" % editor.level.level_name)
	
func show_hide() -> void:
	main_panel.visible = not main_panel.visible

func tool_selected(index: int) -> void:
	tool_manager.create_tool(index)

func print_to_console(message : String) -> void:
	var msg := console.text.split("\n") if console.text != "" else PackedStringArray()
	msg.append(message)
	msg = msg.slice(max(0, msg.size() - CONSOLE_HISTORY))
	console.text = "\n".join(msg)

func file_option_pressed(id: int) -> void:
	match id:
		# New level
		0:
			editor.level = Level.new()
			editor.level_loaded.emit()
	
		# Load level
		1:
			if WebHelper.is_web():
				WebHelper.loaded.connect(file_selected_web.bind(), CONNECT_ONE_SHOT)
				WebHelper.open(".mlf")
				return
			
			var diag := FileDialog.new()
			diag.file_mode = FileDialog.FILE_MODE_OPEN_FILE
			diag.access = FileDialog.ACCESS_FILESYSTEM
			diag.add_filter("*.mlf", "CLANG level format")
			diag.file_selected.connect(file_selected.bind())
			diag.show()
		
		# Save level
		2:
			if WebHelper.is_web():
				editor.level.serialize()
				return
			
			if editor.level.path != "":
				editor.level.serialize()
				return
			
			var diag := FileDialog.new()
			diag.file_mode = FileDialog.FILE_MODE_SAVE_FILE
			diag.access = FileDialog.ACCESS_FILESYSTEM
			diag.add_filter("*.mlf", "CLANG level format")
			diag.show()
			diag.file_selected.connect(file_selected_save.bind())
		
		# Save level as
		3:
			if WebHelper.is_web():
				return
			
			var diag := FileDialog.new()
			diag.file_mode = FileDialog.FILE_MODE_SAVE_FILE
			diag.access = FileDialog.ACCESS_FILESYSTEM
			diag.add_filter("*.mlf", "CLANG level format")
			diag.show()
			diag.file_selected.connect(file_selected_save.bind())

func edit_option_pressed(id: int) -> void:
	match id:
		# Level properties
		5: 
			var window : WindowLevelProperties = level_properties_window.instantiate()
			window.field_changed.connect(editor.action_manager.action_update_level_property.bind())
			window.palette_menu_opened.connect(palette_menu_setup.bind())
			window.level = editor.level
			add_child(window)
			window.show()
		_:
			pass

func fill_properties(thing : Variant) -> void:
	# Check thing
	if !thing:
		clear_properties() 
		return
	
	# Get property list
	var script := thing.get_script() as Script
	var properties := script.get_script_property_list() as Array[Dictionary]
	print(JSON.stringify(properties, " "))
	
	# Iterate through properties
	clear_properties()
	for property in properties:
		var entry := create_entry(thing, property)
		if entry:
			_properties.add_child(entry)
	

func clear_properties() -> void:
	for child in _properties.get_children():
		child.queue_free()

func create_entry(t : Variant, property : Dictionary) -> HBoxContainer:
	# Get information
	var type := property.get("type", 0) as int
	var usage := property.get("usage", 0) as int
	var pname := property.get("name", "") as String
	
	# Verify
	if usage != PROPERTY_USAGE_SCRIPT_VARIABLE:
		return null
	
	# Create container
	var c := HBoxContainer.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var n := Label.new()
	n.text = pname.to_pascal_case()
	c.add_child(n)
	
	# Create field
	var field : Variant
	match type:
		TYPE_INT:		
			field = create_entry_int(c)
			field.value = t.get(pname)
			field.value_changed.connect(%action_manager.action_update_property.bind(t, pname))
		TYPE_FLOAT:		
			field = create_entry_float(c)
			field.value = t.get(pname)
			field.value_changed.connect(%action_manager.action_update_property.bind(t, pname))
		TYPE_STRING:	
			field = create_entry_string(c)
			field.text = t.get(pname)
			field.text_changed.connect(%action_manager.action_update_property.bind(t, pname))
		TYPE_COLOR:		
			field = create_entry_color(c)
			field.color = t.get(pname)
			field.color_changed.connect(%action_manager.action_update_property.bind(t, pname))
		_:
			return null
	
	# Return entry
	return c

func create_entry_int(container : HBoxContainer) -> SpinBox:
	var field := SpinBox.new()
	
	field.size_flags_horizontal = Control.SIZE_SHRINK_END | Control.SIZE_EXPAND
	field.step = 1
	
	container.add_child(field)
	return field

func create_entry_float(container : HBoxContainer) -> SpinBox:
	var field := SpinBox.new()
	
	field.size_flags_horizontal = Control.SIZE_SHRINK_END | Control.SIZE_EXPAND
	
	container.add_child(field)
	return field

func create_entry_string(container : HBoxContainer) -> LineEdit:
	var field := LineEdit.new()
	
	field.size_flags_horizontal = Control.SIZE_SHRINK_END | Control.SIZE_EXPAND
	
	container.add_child(field)
	return field

func create_entry_color(container : HBoxContainer) -> ColorPickerButton:
	var field := ColorPickerButton.new()
	
	field.size_flags_horizontal = Control.SIZE_SHRINK_END | Control.SIZE_EXPAND
	
	container.add_child(field)
	return field

func palette_menu_setup(menu : WindowPalettePicker) -> void:
	menu.palette_color_changed.connect(editor.action_manager.action_update_lut_color.bind())
	menu.palette_loaded.connect(editor.action_manager.action_update_palette.bind())

func file_selected(path : String) -> void:
	editor.level = Level.new(path)
	editor.level_loaded.emit()
	
func file_selected_web(_fn : String, _ft : String, data : String) -> void:
	var level := Level.new()
	var bdata := Marshalls.base64_to_raw(data) as PackedByteArray
	var buf := StreamPeerBuffer.new()
	buf.data_array = bdata
	level.deserialize(buf)
	
	editor.level = level
	editor.level_loaded.emit()

func file_selected_save(path : String) -> void:
	editor.level.path = path
	editor.level.serialize()
