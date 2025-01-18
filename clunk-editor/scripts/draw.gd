### draw.gd
extends Node2D

## Polygon provider
@onready var editor := owner as Editor

func _draw() -> void:
	## Color
	var time := Time.get_ticks_usec() / 1000000.0
	var fac := 0.5 + (sin(time * 2) * 0.25)
	
	for polygon in editor.poly_list:
		draw_polygon(polygon.points, polygon.colors)
	if editor.poly_cur:
		var poly := PackedVector2Array(editor.poly_cur.points)
		poly.append(get_global_mouse_position())
		draw_colored_polygon(poly, Color(Color.WHITE, fac))

func _process(delta: float) -> void:
	queue_redraw()
