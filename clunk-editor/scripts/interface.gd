### interface.gd
class_name Interface extends CanvasLayer

## Main gui panel
@onready var main_panel : PanelContainer = $gui/main/panel
## Tools list
@onready var tools_list : ItemList = $gui/main/panel/sort/tools
## Tool manager
@onready var tool_manager : ToolManager = $tool_manager


func _ready() -> void:
	# Make sure vertex mode is selected
	tools_list.select(1)

func show_hide() -> void:
	main_panel.visible = not main_panel.visible

func tool_selected(index: int) -> void:
	tool_manager.create_tool(index)
