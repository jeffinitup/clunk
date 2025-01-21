### interface.gd
class_name Interface extends CanvasLayer

## Lines to print
const CONSOLE_HISTORY = 8

## Editor reference
@onready var editor : Editor = owner as Editor
## Main gui panel
@onready var main_panel : PanelContainer = $gui/vsort/main/panel
## Tools list
@onready var tools_list : ItemList = $gui/vsort/main/panel/sort/tools
## Tabs list
@onready var tabs : MenuBar = $gui/vsort/main/tabs
## Tool manager
@onready var tool_manager : ToolManager = $tool_manager
## Console node
@onready var console : RichTextLabel = $gui/vsort/console/text

func _ready() -> void:
	# Print identifier to console
	var version := ProjectSettings.get_setting("application/config/version") as String
	print_to_console("CLUNK Editor Initialized - Version %s" % version)
	
	# Make sure vertex mode is selected
	tools_list.select(1)

func on_level_load() -> void:
	console.text = ""
	
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
			var diag := FileDialog.new()
			diag.file_mode = FileDialog.FILE_MODE_OPEN_FILE
			diag.access = FileDialog.ACCESS_FILESYSTEM
			diag.add_filter("*.mlf", "CLANG level format")
			diag.file_selected.connect(file_selected.bind())
			diag.show()
		
		# Save level
		2:
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
			var diag := FileDialog.new()
			diag.file_mode = FileDialog.FILE_MODE_SAVE_FILE
			diag.access = FileDialog.ACCESS_FILESYSTEM
			diag.add_filter("*.mlf", "CLANG level format")
			diag.show()
			diag.file_selected.connect(file_selected_save.bind())

func edit_option_pressed(id: int) -> void:
	pass

func file_selected(path : String) -> void:
	editor.level = Level.new(path)
	editor.level_loaded.emit()

func file_selected_save(path : String) -> void:
	editor.level.path = path
	editor.level.serialize()
