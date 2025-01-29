### actor.gd
class_name ActorBase extends Node

## Display name for property list
var _ANAME := "BASE"
## Resource id
var rid : int
## Bounding box for actor
var rect : Rect2
## Position of actor
var position : Vector2

func _draw_actor(canvas : Node2D) -> void:
	canvas.draw_set_transform(position)
	canvas.draw_rect(rect, Color.RED, false, 2.0)
	canvas.draw_string(Editor.font, rect.end, _ANAME)
	canvas.draw_set_transform(Vector2.ZERO)

func _serialize() -> Dictionary:
	return {
		rid : {
			"class" : get_class(),
			"position" : position,
			"args" : [],
			"signals" : []
		}
	}

func _deserialize(data : Dictionary) -> void:
	position = data.get("position", Vector2.ZERO)
