### tool.gd
class_name Tool extends Node2D

## The name of the tool
var tool_name : String = "Tool"
## Editor reference
var editor : Editor
## Action manager reference
var action_manager : ActionManager
## Canvas reference
var canvas : Control

## Virtual function called by canvas
func _draw_tool() -> void:
	pass

## Virtual function called when undo/redo is called
func _undo_redo() -> void:
	pass

class Select extends Tool:
	## Fired when something is selected
	signal thing_selected(thing : Variant)
	
	## Hovered polygon
	var hover_thing : Variant
	## Currently selected polygon
	var current_thing : Variant
	## Total movement
	var total_movement : Vector2 = Vector2()
	
	func _init() -> void:
		self.tool_name = "Select"
	
	func _draw_tool() -> void:
		# Color
		var time := Time.get_ticks_usec() / 1000000.0
		var fac := 0.5 + (sin(time * 2) * 0.25)
		
		# Draw selected
		if hover_thing || current_thing:
			# Hover draw
			if hover_thing is Editor.Polygon:
				var points := PackedVector2Array(hover_thing.points)
				var color := Color(Color.RED, fac) 
				points.push_back(hover_thing.points[0])
				canvas.draw_polyline(points, color, 2.0 + fac)
			
			if hover_thing is ActorBase:
				canvas.draw_circle(hover_thing.position, 10.0, Color.RED, false, 1.0)
	
	func _unhandled_input(event : InputEvent) -> void:
		if event is InputEventMouseMotion:
			if current_thing:
				total_movement += -event.relative
				
				# Set polygon position
				if current_thing is Editor.Polygon:
					var movement := Transform2D(0, -event.relative)
					var moved := current_thing.points * movement as PackedVector2Array
					current_thing.points = moved
				
				# Set actor position
				if current_thing is ActorBase:
					var movement := Transform2D(0, -event.relative)
					current_thing.position *= movement
			
			if !current_thing:
				# Pick object
				hover_thing = pick_object()
			
		if event is InputEventMouseButton:
			if !event.pressed && event.button_index == MOUSE_BUTTON_LEFT:
				var action : ActionMoveThing
				if !current_thing:
					return
				
				# Commit actor position
				if current_thing is ActorBase:
					action = ActionMoveThing.new(
						current_thing,
						current_thing.position - total_movement
					)
				
				# Commit polygon position
				elif current_thing is Editor.Polygon:
					action = ActionMoveThing.new(
						current_thing,
						current_thing.points * Transform2D(0, -total_movement)
					)
				
				action_manager.action_move_thing(action)
				current_thing = null
				total_movement = Vector2()
				
				return
			
			if event.is_pressed() && event.button_index == MOUSE_BUTTON_LEFT:
				# Pick object
				current_thing = pick_object()
				thing_selected.emit(current_thing)
				total_movement = Vector2()
	
	func pick_object() -> Variant:
		# Check for actors first
		var mpos := get_global_mouse_position()
		for actor in editor.level.actors:
			var rect := actor.rect
			rect = Rect2(actor.position + rect.position, rect.size)
			if rect.has_point(mpos):
				return actor
		
		# Next check for polygon
		for polygon in editor.level.polygons:
			if Geometry2D.is_point_in_polygon(mpos, polygon.points):
				return polygon
		
		return null
	
	class ActionMoveThing extends Node:
		var thing : Variant
		var original : Variant
		
		func _init(t : Variant, o : Variant) -> void:
			self.thing = t
			self.original = o
	
class Vertex extends Tool:
	## Current, modified polygon
	var cur_poly : Editor.Polygon
	
	func _init() -> void:
		self.tool_name = "Vertex"
	
	func _draw_tool() -> void:
		# Color
		var time := Time.get_ticks_usec() / 1000000.0
		var fac := 0.5 + (sin(time * 2) * 0.25)
		
		if cur_poly:
			var poly := PackedVector2Array(cur_poly.points)
			poly.append(get_global_mouse_position())
			
			var line := PackedVector2Array(poly)
			line.append(line[0])
			canvas.draw_polyline(line, Color.BLUE)
			
			# Stop drawing if less than three points
			if poly.size() < 3 || !Draw.should_draw(poly):
				return
			
			canvas.draw_colored_polygon(poly, Color(Color.WHITE, fac))
	
	func _unhandled_input(event: InputEvent) -> void:
		## Check for mouse input
		if event is InputEventMouseButton:
			## Place polygon point
			if event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed():
				var pos : Vector2 = event.position
				if !self.cur_poly:
					var size := editor.level.polygons.size()
					self.cur_poly = Editor.Polygon.new(size)
				self.cur_poly.append(pos)
				
			## Commit polygon
			if event.button_index == MOUSE_BUTTON_MASK_RIGHT && event.is_pressed():
				if !self.cur_poly || self.cur_poly.points.size() < 3:
					return
				commit_polygon()
				
		## Delete polygon
		if event is InputEventKey:
			if (event.keycode == KEY_BACKSPACE || event.keycode == KEY_DELETE || \
				event.keycode == KEY_ESCAPE) and event.is_pressed():
					self.cur_poly = null
	
	func _undo_redo() -> void:
		## Remove temp polygon
		self.cur_poly = null
	
	func commit_polygon() -> void:
		# If collision triangulation fails, we have a bad polygon
		if Geometry2D.triangulate_polygon(cur_poly.points).is_empty():
			push_warning("Bad triangulation! - " + str(cur_poly.rid))
			self.cur_poly = null
			return
		
		# If collision decomposition fails, we also have a bad polygon
		if Geometry2D.decompose_polygon_in_convex(cur_poly.points).is_empty():
			push_warning("Bad decompisition! - " + str(cur_poly.rid))
			self.cur_poly = null
			return

		# Add to list
		add_to_polygon_list(self.cur_poly)
		self.cur_poly = null
	
	func add_to_polygon_list(poly : Editor.Polygon) -> void:
		action_manager.action_make_poly(poly)
		cur_poly = null

class Polygon extends Tool:
	## Dist from cursor -> vertex needed to grab vertex
	const DIST := 8.0
	## Radius of vertex
	const RADIUS := 3.0
	
	## Hovered polygon
	var hover_poly : Editor.Polygon
	## Selected polygon
	var cur_poly : Editor.Polygon
	## Selected vertex ind
	var cur_ind : int = -1
	## Selected side ind
	var cur_side : int = -1
	## Original vertex pos
	var cur_ind_original : Vector2
	
	func _init() -> void:
		self.tool_name = "Polygon"
	
	func _draw_tool() -> void:
		# Color
		var time := Time.get_ticks_usec() / 1000000.0
		var fac := 0.5 + (sin(time * 2) * 0.25)
		
		# Draw selected
		if hover_poly && cur_poly != hover_poly:
			var points := PackedVector2Array(hover_poly.points)
			var color := Color(Color.RED, fac)
			points.push_back(hover_poly.points[0])
			canvas.draw_polyline(points, color, 2.0 + fac)
		
		if cur_poly:
			var points := PackedVector2Array(cur_poly.points)
			for ind in range(points.size()):
				canvas.draw_circle(points[ind], RADIUS, Color.RED if ind != cur_ind else Color.WHITE)
	
	func _unhandled_input(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			# Highlighting
			var mpos := get_global_mouse_position()
			for polygon in editor.level.polygons:
				if Geometry2D.is_point_in_polygon(mpos, polygon.points):
					hover_poly = polygon
					break
				hover_poly = null
			
			if cur_poly:
				# Add point
				if cur_side != -1:
					var pos := event.global_position as Vector2
					var action := ActionModifyPoint.new(cur_poly, cur_side, Vector2.ZERO, pos)
					action_manager.action_create_point(action)
					
					cur_ind = cur_side
					cur_ind_original = pos
					cur_side = -1
				
				# Move point (temp)
				if cur_ind != -1:
					var movement := event.relative as Vector2
					var moved := cur_poly.points[cur_ind] + movement
					cur_poly.points[cur_ind] = moved
					return
		
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.is_pressed():
					# Select vertex
					if cur_poly:
						cur_ind = closest_ind()
						cur_side = closest_line()
						if cur_ind != -1:
							cur_ind_original = cur_poly.points[cur_ind]
						return
					
					# Select polygon
					if cur_poly != hover_poly:
						var mpos := get_global_mouse_position()
						for polygon in editor.level.polygons:
							if Geometry2D.is_point_in_polygon(mpos, polygon.points):
								cur_poly = polygon
								return
						cur_poly = null
			
				# End move point
				if !event.is_pressed():
					if cur_ind != -1:
						var action := ActionModifyPoint.new(
							cur_poly, cur_ind, 
							cur_ind_original, cur_poly.points[cur_ind]
						)
						action_manager.action_move_point(action) 
					
					cur_ind = -1
					cur_side = -1
					cur_ind_original = Vector2()
			
			if event.button_index == MOUSE_BUTTON_RIGHT:
				if event.is_pressed() and cur_poly:
					var temp_points : PackedVector2Array = PackedVector2Array(cur_poly.points)
					cur_ind = closest_ind()
					
					if cur_ind != -1:
						temp_points.remove_at(cur_ind)
						
						# Delete poly
						if temp_points.size() < 3 || !Draw.should_draw(temp_points):
							var action := ActionDeletePolygon.new(cur_poly)
							action_manager.action_delete_poly(action)
							cur_poly = null
							cur_ind = -1
							return
						
						# Otherwise remove vertex
						var action := ActionModifyPoint.new(cur_poly, cur_ind, Vector2.ZERO, cur_poly.points[cur_ind])
						action_manager.action_delete_point(action)
						cur_ind = -1
					
	func closest_ind() -> int:
		if !cur_poly:
			return -1
		
		var cursor := get_global_mouse_position()
		var size := cur_poly.points.size()
		for index in range(size):
			if (cursor - cur_poly.points[index]).length() < DIST:
				return index
		return -1
	
	func closest_line() -> int:
		if !cur_poly || cur_ind != -1:
			return -1
		
		var cursor := get_global_mouse_position()
		var size := cur_poly.points.size()
		for index in range(size):
			# Check if cursor is between poly side verts
			var point_a := cur_poly.points[index]
			var point_b := cur_poly.points[index + 1 if index + 1 < size else 0]
			var a_b := (point_b - point_a).length()
			var a_c := (cursor - point_a).length()
			var b_c := (cursor - point_b).length()
			
			if (a_c + b_c) - a_b < DIST:
				# Check height of triangle
				var avg := (a_b + a_c + b_c) * 0.5
				avg = sqrt(avg * (avg - a_b) * (avg - a_c) * (avg - b_c))
				var height := 2.0 * avg / a_b
				
				if height < DIST:
					return index + 1
		
		return -1

	class ActionModifyPoint extends Node:
		var poly : Editor.Polygon
		var ind : int
		var original : Vector2
		var new : Vector2
		func _init(p : Editor.Polygon, i : int, o : Vector2, n : Vector2) -> void:
			self.poly = p
			self.ind = i
			self.original = o
			self.new = n
	
	class ActionDeletePolygon extends Node:
		var poly : Editor.Polygon
		func _init(p : Editor.Polygon) -> void:
			self.poly = p

class Stamper extends Tool:
	## Stamp menu
	@onready var _stamp_menu := preload("res://scene/stamper_picker.tscn")
	## Thing to stamp
	var stamp : Variant :
		set(value) : stamp = is_stamp(value)
	
	func _init() -> void:
		self.tool_name = "Stamper"
	
	func _draw_tool() -> void:
		# Color
		var time := Time.get_ticks_usec() / 1000000.0
		var fac := 0.5 + (sin(time * 2) * 0.25)
		
		if stamp is ActorBase:
			draw_actor(fac)
		elif stamp is Editor.Polygon:
			draw_poly(fac)
	
	func _unhandled_input(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			# Handle left click
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.is_pressed():
					# If no stamp, open stamp menu
					if !stamp:
						open_stamp_menu()
						return
					
					# Otherwise, stamp thing
					var action := ActionStamp.new(
						stamp.duplicate(),
						get_global_mouse_position()
					)
					action_manager.action_stamp(action)
				
			# Handle right click
			if event.button_index == MOUSE_BUTTON_RIGHT:
				if event.is_pressed():
					if stamp:
						stamp = null
						return
					
					open_stamp_menu()
	
	func open_stamp_menu() -> void:
		# Create stamp menu
		var menu := _stamp_menu.instantiate() as WindowStamperPicker
		add_child(menu)
		menu.stamp_picked.connect(func(thing : Variant) -> void: stamp = thing)
	
	func is_stamp(thing : Variant) -> Variant:
		if thing is ActorBase || thing is Editor.Polygon:
			return thing
		return null
	
	func draw_actor(fac : float) -> void:
		var pos := get_global_mouse_position() as Vector2
		
		stamp = stamp as ActorBase
		canvas.draw_rect(Rect2(stamp.rect.position + pos, stamp.rect.size), Color(Color.RED, fac))
		canvas.draw_string(editor.font, pos + stamp.rect.position + stamp.rect.size, stamp._ANAME)
	
	func draw_poly(fac : float) -> void:
		stamp = stamp as Editor.Polygon
		canvas.draw_polygon_colored(stamp.points, Color(Color.RED, fac))
	
	class ActionStamp extends Node:
		var thing : Variant
		var mouse_pos : Vector2
		func _init(t : Variant, mp : Vector2) -> void:
			self.thing = t
			self.mouse_pos = mp
	
class Spline extends Tool:
	func _init() -> void:
		self.tool_name = "Spline"
