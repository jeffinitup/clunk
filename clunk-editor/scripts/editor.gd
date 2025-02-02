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
## Editor font
static var font : Font = preload("uid://b6gqlupalgea3")

## Current, uncommited polygon
var poly_cur : Polygon

func set_poly_cur(poly : Polygon) -> void:
	poly_cur = poly
