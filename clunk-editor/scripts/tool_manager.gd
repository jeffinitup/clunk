### tool_manager.gd
class_name ToolManager extends Node

enum {
	Select,
	Vertex,
	Polygon,
	Spline
}

## Active tool
var current : Tool = null


func create_tool(i : int) -> Tool:
	var tool : Tool
	var editor : Editor = owner as Editor
	
	match i:
		Select:
			tool = Tool.Select.new()
		Vertex:
			tool = Tool.Vertex.new()
			
			tool.poly_size = editor.level.polygons.size()
			tool.temp_commit.connect(editor.set_poly_cur.bind())
			editor.polys_updated.connect(tool.update_size.bind())
		Polygon:
			tool = Tool.Polygon.new()
		Spline:
			tool = Tool.Spline.new()
	tool.name = tool.tool_name.to_lower()
	tool.action_manager = editor.action_manager
	tool.editor = editor
	editor.action_manager.action_modified.connect(tool._undo_redo.bind())
	
	if current != null:
		current.queue_free()
	current = tool
	add_child(tool)
	
	return tool
