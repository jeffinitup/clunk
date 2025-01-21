### editor.gd
class_name Editor extends Node

## Fired when poly_list is updated
signal polys_updated(list : Array[Polygon])
## Fired when level is loaded
signal level_loaded()

## Action manager reference
@onready var action_manager := $action_manager as ActionManager
## Current level
@onready var level : Level = Level.new()
## Current, uncommited polygon
var poly_cur : Polygon

func _ready() -> void:
	pass

func set_poly_cur(poly : Polygon) -> void:
	poly_cur = poly

class Polygon extends Resource:
	var rid : int
	var focused : bool = false
	var origin := Vector2()
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	
	func _init(id : int):
		self.rid = id
	
	func append(point : Vector2, color : Color = Color.WHITE) -> Polygon:
		self.points.append(point)
		self.colors.append(color)
		return self
	
	## Calculates area using Gauss' shoelace formula
	func calculate_area() -> float:
		var result : float = 0.0
		var size : int = points.size()
		
		for i in range(size):
			var v := (i - 1 + size) % size
			result += points[i].cross(points[v])
		
		return result * 0.5
