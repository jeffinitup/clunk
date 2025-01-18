### editor.gd
class_name Editor extends Node

## Array of different points
var poly_list : Array[Polygon]
## Current, modified polygon
var poly_cur : Polygon

func _ready() -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	## Check for mouse input
	if event is InputEventMouseButton:
		## Place polygon point
		if event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed():
			var pos : Vector2 = event.position
			if !poly_cur:
				poly_cur = Polygon.new(poly_list.size())
			poly_cur.append(pos)
			
		## Commit polygon
		if event.button_index == MOUSE_BUTTON_MASK_RIGHT && event.is_pressed():
			if !poly_cur:
				return
			poly_list.append(poly_cur)
			poly_cur = null
			
		## Delete polygon

class Polygon extends Resource:
	var rid : int
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	
	func _init(rid : int):
		self.rid = rid
	
	func append(point : Vector2, color : Color = Color.WHITE) -> Polygon:
		self.points.append(point)
		self.colors.append(color)
		return self
