### tool.gd
class_name Tool extends Node2D

## The name of the tool
var tool_name : String = "Tool"

class Select extends Tool:
	func _init() -> void:
		self.tool_name = "Select"

class Vertex extends Tool:
	## Fired when temporary polygon is created
	signal temp_commit(polygon : Editor.Polygon)
	## Fired when ready to commit to level polygon list
	signal commit(polygon : Editor.Polygon)
	## Fired when requesting polygon list size
	signal size_request()
	
	## Current, modified polygon
	var poly_cur : Editor.Polygon
	## Our copy of polygon size
	var poly_size : int = 0
	
	func _init() -> void:
		self.tool_name = "Vertex"
	
	func _ready() -> void:
		self.size_request.emit()
	
	func _unhandled_input(event: InputEvent) -> void:
		## Check for mouse input
		if event is InputEventMouseButton:
			## Place polygon point
			if event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed():
				var pos : Vector2 = event.position
				if !self.poly_cur:
					self.poly_cur = Editor.Polygon.new(self.poly_size)
					self.temp_commit.emit(self.poly_cur)
				self.poly_cur.append(pos)
				
			## Commit polygon
			if event.button_index == MOUSE_BUTTON_MASK_RIGHT && event.is_pressed():
				if !self.poly_cur:
					return
				commit_polygon()
				
		## Delete polygon
		if event is InputEventKey:
			if (event.keycode == KEY_BACKSPACE || event.keycode == KEY_DELETE) \
				and event.is_pressed():
					self.poly_cur = null
	
	func update_size(size : int) -> void:
		poly_size = size
	
	func commit_polygon() -> void:
		# If collision triangulation fails, we have a bad polygon
		if Geometry2D.triangulate_polygon(poly_cur.points).is_empty():
			push_warning("Bad triangulation! - " + str(poly_cur.rid))
			self.poly_cur = null
			return
		
		# If collision decomposition fails, we also have a bad polygon
		if Geometry2D.decompose_polygon_in_convex(poly_cur.points).is_empty():
			push_warning("Bad decompisition! - " + str(poly_cur.rid))
			self.poly_cur = null
			return

		# Add to list
		self.commit.emit(self.poly_cur)
		self.poly_cur = null

class Polygon extends Tool:
	func _init() -> void:
		self.tool_name = "Polygon"

class Spline extends Tool:
	func _init() -> void:
		self.tool_name = "Spline"
