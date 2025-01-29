### tool_manager.gd
class_name ToolManager extends Node

enum {
	Select,
	Vertex,
	Polygon,
	Stamper,
	Spline
}

## Active tool
var current : Tool = null
## Element tools can draw to
@onready var canvas : Control = $canvas

func _physics_process(delta: float) -> void:
	canvas.queue_redraw()

func create_tool(i : int) -> Tool:
	var tool : Tool
	var editor : Editor = owner as Editor
	
	match i:
		Select:
			tool = Tool.Select.new()
		Vertex:
			tool = Tool.Vertex.new()
		Polygon:
			tool = Tool.Polygon.new()
		Stamper:
			tool = Tool.Stamper.new()
		Spline:
			tool = Tool.Spline.new()
	
	tool.name = tool.tool_name.to_lower()
	tool.action_manager = editor.action_manager
	tool.editor = editor
	tool.canvas = canvas
	
	canvas.draw.connect(tool._draw_tool.bind())
	editor.action_manager.action_modified.connect(tool._undo_redo.bind())
	
	if current != null:
		canvas.draw.disconnect(current._draw_tool.bind())
		current.queue_free()
	current = tool
	add_child(tool)
	
	return tool
