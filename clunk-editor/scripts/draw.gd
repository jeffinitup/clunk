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
	
	# Draw existing actors
	for actor in editor.level.actors:
		actor._draw_actor(self)
		
	# Draw grid
	var camera := get_tree().root.get_camera_2d()
	var size = get_viewport_rect().size / camera.zoom
	var cam_pos = camera.position
	var col : Color
	
	for i in range(int((cam_pos.x - size.x) / 64) - 1, int((size.x + cam_pos.x) / 64) + 1):
		col = Color(Color.DARK_GRAY if i * 64 != 0 else Color.LIME_GREEN, 0.5)
		draw_line(Vector2(i * 64, cam_pos.y + size.y + 100), Vector2(i * 64, cam_pos.y - size.y - 100), col)
	for i in range(int((cam_pos.y - size.y) / 64) - 1, int((size.y + cam_pos.y) / 64) + 1):
		col = Color(Color.DARK_GRAY if i * 64 != 0 else Color.INDIAN_RED, 0.5)
		draw_line(Vector2(cam_pos.x + size.x + 100, i * 64), Vector2(cam_pos.x - size.x - 100, i * 64), col)


func _physics_process(delta : float) -> void:
	# Redraw
	queue_redraw()

static func should_draw(points : PackedVector2Array) -> bool:
	if Geometry2D.triangulate_polygon(points).is_empty():
		return false
	return true
