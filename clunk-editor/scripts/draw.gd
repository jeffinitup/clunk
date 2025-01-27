### draw.gd
class_name Draw extends Node2D

## Polygon provider
@onready var editor := owner as Editor

func _draw() -> void:
	# Draw existing polygons
	for polygon in editor.level.polygons:
		# If polygon has less than three points, dont draw
		if polygon.points.size() < 3:
			continue
		draw_colored_polygon(polygon.points, editor.level.palette.color[polygon.color])
		draw_circle(polygon.origin, 4.0, Color.RED, false)
		
		# Draw additional border if polygon is hovered over
		#if polygon.selected:
			#var lines := PackedVector2Array(polygon.points)
			#lines.append(lines[0])
			#draw_polyline(lines, Color.RED, 2.0)
		#
		#elif polygon.focused:
			#var lines := PackedVector2Array(polygon.points)
			#lines.append(lines[0])
			#draw_polyline(lines, Color(Color.RED, fac), 2.0)

func _physics_process(delta : float) -> void:
	# Redraw
	queue_redraw()

static func should_draw(points : PackedVector2Array) -> bool:
	if Geometry2D.triangulate_polygon(points).is_empty():
		return false
	return true
