### tool.gd
class_name Tool extends Node2D

## The name of the tool
var tool_name : String = "Tool"
## Editor reference
var editor : Editor
## Action manager reference
var action_manager : ActionManager

## Virtual function called when undo/redo is called
func _undo_redo() -> void:
	pass

class Select extends Tool:
	## Currently selected polygon
	var cur_poly : Editor.Polygon
	## Original collection of points
	var original : PackedVector2Array
	
	func _init() -> void:
		self.tool_name = "Select"
	
	func _unhandled_input(event : InputEvent) -> void:
		if event is InputEventMouseMotion:
			if cur_poly:
				var movement := Transform2D(0, -event.relative)
				var moved := cur_poly.points * movement
				cur_poly.points = moved
			
			if !cur_poly:
				var mpos := get_global_mouse_position()
				for polygon in editor.level.polygons:
					if Geometry2D.is_point_in_polygon(mpos, polygon.points):
						polygon.focused = true
						continue
					polygon.focused = false
		
		if event is InputEventMouseButton:
			if !event.pressed || event.button_index != MOUSE_BUTTON_LEFT:
				if !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) && cur_poly:
					var action := SelectAction.new(cur_poly.rid, self.original)
					action_manager.action_move_poly(cur_poly, action)
					
					cur_poly = null
					original = PackedVector2Array()
				return
			
			var mpos := get_global_mouse_position()
			for polygon in editor.level.polygons:
				if Geometry2D.is_point_in_polygon(mpos, polygon.points):
					cur_poly = polygon
					original = cur_poly.points
					return
	
	class SelectAction extends Node:
		var rid : int 
		var original : PackedVector2Array
		
		func _init(i : int, o : PackedVector2Array) -> void:
			self.rid = i
			self.original = o
	
class Vertex extends Tool:
	## Fired when temporary polygon is created
	signal temp_commit(polygon : Editor.Polygon)
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
				if !self.poly_cur || self.poly_cur.points.size() < 3:
					return
				commit_polygon()
				
		## Delete polygon
		if event is InputEventKey:
			if (event.keycode == KEY_BACKSPACE || event.keycode == KEY_DELETE || \
				event.keycode == KEY_ESCAPE) and event.is_pressed():
					self.poly_cur = null
					temp_commit.emit(null)
	
	func _undo_redo() -> void:
		## Remove temp polygon
		self.poly_cur = null
		temp_commit.emit(null)
	
	func update_size(polygons : Array[Editor.Polygon]) -> void:
		var size = polygons.size()
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
		add_to_polygon_list(self.poly_cur)
		self.poly_cur = null
		self.temp_commit.emit(null)
	
	func add_to_polygon_list(poly : Editor.Polygon) -> void:
		action_manager.action_make_poly(poly)
		poly_cur = null

class Polygon extends Tool:
	func _init() -> void:
		self.tool_name = "Polygon"

class Spline extends Tool:
	func _init() -> void:
		self.tool_name = "Spline"
