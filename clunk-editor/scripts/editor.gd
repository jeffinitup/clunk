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
	var origin := Vector2()
	var points := PackedVector2Array() :
		set(value) : 
			points = value
			self.calculate_centroid()
	var color := 0
	
	func _init(id : int):
		self.rid = id
	
	func append(point : Vector2) -> Polygon:
		self.points.append(point)
		self.calculate_centroid()
		return self
	
	func insert(ind : int, point : Vector2) -> Polygon:
		self.points.insert(ind, point)
		self.calculate_centroid()
		return self
	
	func remove(ind : int) -> Polygon:
		self.points.remove_at(ind)
		self.calculate_centroid()
		return self
	
	## Calculates area using Gauss' shoelace formula
	func calculate_area() -> float:
		var result : float = 0.0
		var size : int = self.points.size()
		
		for i in range(size):
			var v := (i - 1 + size) % size
			result += self.points[i].cross(points[v])
		
		return result * 0.5
	
	## Calculates centroid using area
	func calculate_centroid() -> void:
		var centroid := Vector2()
		var area := calculate_area()
		var size := self.points.size()
		var factor := 0.0
		
		for i in range(size):
			var v := (i - 1 + size) % size
			factor = self.points[i] .cross(self.points[v])
			centroid += (self.points[i] + self.points[v]) * factor
		
		centroid /= (6.0 * area)
		self.origin = centroid
