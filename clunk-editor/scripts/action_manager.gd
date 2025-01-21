### action_manager.gd
class_name ActionManager extends Node

## Fired when any action is modified (undone, redone)
signal action_modified()
## Fired when action is made
signal action_made(descriptor : String)

## Depth of history to keep track of
const DEPTH = 10
## Data references
var data_ref : Array[Variant] = []

## Action history manager
@onready var history : UndoRedo = UndoRedo.new()

func _ready() -> void:
	history.max_steps = DEPTH

func _shortcut_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.ctrl_pressed && event.keycode == KEY_Z && event.is_pressed():
			if event.shift_pressed:
				history.redo()
				action_modified.emit()
				return
			action_modified.emit()
			history.undo()
			return

func on_level_loaded() -> void:
	## Clear data ref and history
	history.clear_history()
	data_ref.clear()

func action_move_poly(poly : Editor.Polygon, action : Tool.Select.SelectAction) -> void:
	history.create_action("Polygon moved")
	
	history.add_do_property(poly, &"points", poly.points)
	history.add_do_method(func() -> void:
		action_made.emit("Polygon %d moved to new position" % action.rid)
	)

	history.add_undo_property(poly, &"points", action.original)
	history.add_undo_method(func() -> void:
		action_made.emit("Polygon %d moved to old position" % action.rid)
	)
	history.add_undo_reference(action)
	
	history.commit_action()

func action_make_poly(poly : Editor.Polygon) -> void:
	history.create_action("Add polygon to scene")
		
	## Add a data reference to stack
	data_ref.push_back(poly)
	
	## Redo/Undo
	history.add_do_method(func() -> void:
		var hist_poly := data_ref.pop_back() as Editor.Polygon
		owner.level.polygons.append(hist_poly)
		action_made.emit("Polygon %d added to scene" % hist_poly.rid)
		owner.polys_updated.emit(owner.level.polygons)
	)
	history.add_undo_method(func() -> void:
		var hist_poly := owner.level.polygons.pop_back() as Editor.Polygon
		data_ref.push_back(hist_poly)
		action_made.emit("Polygon %d removed from scene" % hist_poly.rid)
		owner.polys_updated.emit(owner.level.polygons)
	)
	
	## Commit
	history.commit_action()
