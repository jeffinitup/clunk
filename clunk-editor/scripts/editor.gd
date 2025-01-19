### editor.gd
class_name Editor extends Node

## Fired when poly_list is updated
signal polys_updated(list : Array[Polygon])

## Array of different points
var poly_list : Array[Polygon]
## Current, uncommited polygon
var poly_cur : Polygon

func _ready() -> void:
	pass

func set_poly_cur(poly : Polygon) -> void:
	poly_cur = poly

func add_to_polygon_list(poly : Polygon) -> void:
	poly_list.append(poly)
	polys_updated.emit(poly_list)
	poly_cur = null

class Polygon extends Resource:
	var rid : int
	var focused : bool = false
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	
	func _init(rid : int):
		self.rid = rid
	
	func append(point : Vector2, color : Color = Color.WHITE) -> Polygon:
		self.points.append(point)
		self.colors.append(color)
		return self
