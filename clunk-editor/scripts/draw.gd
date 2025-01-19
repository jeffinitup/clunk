### draw.gd
extends Node2D

## Polygon provider
@onready var editor := owner as Editor

func _draw() -> void:
	## Color
	var time := Time.get_ticks_usec() / 1000000.0
	var fac := 0.5 + (sin(time * 2) * 0.25)
	
	# Draw existing polygons
	for polygon in editor.poly_list:
		# If polygon has less than three points, dont draw
		if polygon.points.size() < 3:
			continue
		draw_polygon(polygon.points, polygon.colors)
		
		# Draw additional border if polygon is hovered over
		if polygon.focused:
			var lines := PackedVector2Array(polygon.points)
			lines.append(lines[0])
			draw_polyline(lines, Color.RED, 2.0)
	
	# Draw in progress polygon
	if editor.poly_cur:
		var poly := PackedVector2Array(editor.poly_cur.points)
		poly.append(get_global_mouse_position())
		
		var line := PackedVector2Array(poly)
		line.append(line[0])
		draw_polyline(line, Color.BLUE)
		
		# Stop drawing if less than three points
		if poly.size() < 3 || !should_draw(poly):
			return
		
		draw_colored_polygon(poly, Color(Color.WHITE, fac))

func _unhandled_input(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mpos := get_global_mouse_position()
		for polygon in editor.poly_list:
			if Geometry2D.is_point_in_polygon(mpos, polygon.points):
				polygon.focused = true
				continue
			polygon.focused = false

func _physics_process(delta : float) -> void:
	# Redraw
	queue_redraw()

func should_draw(points : PackedVector2Array) -> bool:
	if Geometry2D.triangulate_polygon(points).is_empty():
		return false
	return true
