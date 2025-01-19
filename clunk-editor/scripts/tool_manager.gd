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
			
			tool.temp_commit.connect(editor.set_poly_cur.bind())
			tool.commit.connect(editor.add_to_polygon_list.bind())
			tool.size_request.connect(func() -> void: 
				editor.polys_updated.emit(editor.poly_list))
		Polygon:
			tool = Tool.Polygon.new()
		Spline:
			tool = Tool.Spline.new()
	tool.name = tool.tool_name.to_lower()
	
	if current != null:
		current.queue_free()
	current = tool
	add_child(tool)
	
	return tool
