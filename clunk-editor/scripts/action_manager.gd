### action_manager.gd
class_name ActionManager extends Node

## Fired when any action is modified (undone, redone)
signal action_modified()

## Depth of history to keep track of
const DEPTH = 50
## Data references
var data_ref : Array[Variant] = []

## Action history manager
@onready var history : UndoRedo = UndoRedo.new()
## Editor reference
@onready var editor : Editor = owner as Editor

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
	# Clear data ref and history
	history.clear_history()
	data_ref.clear()

func action_create_point(action : Tool.Poly.ActionModifyPoint) -> void:
	history.create_action("Create polygon point")
	
	history.add_do_method(func() -> void:
		action.poly.insert(action.ind, action.new)
		Logger.log_history("Inserted new point on polygon")
	)
	history.add_undo_method(func() -> void:
		action.poly.remove(action.ind)
		Logger.log_history("Removed point on polygon")
	)
	history.add_do_reference(action)
	history.add_undo_reference(action)
	
	history.commit_action()

func action_delete_point(action : Tool.Poly.ActionModifyPoint) -> void:
	history.create_action("Delete polygon point")
	
	history.add_do_method(func() -> void:
		action.poly.remove(action.ind)
		Logger.log_history("Removed point on polygon")
	)
	history.add_undo_method(func() -> void:
		action.poly.insert(action.ind, action.new)
		Logger.log_history("Inserted new point on polygon")
	)
	history.add_do_reference(action)
	history.add_undo_reference(action)
	
	history.commit_action()

func action_delete_poly(action : Tool.Poly.ActionDeletePolygon) -> void:
	history.create_action("Delete polygon")
	
	history.add_do_method(func() -> void:
		editor.level.polygons.remove_at(action.poly.rid)
		Logger.log_history("Destructive operation on polygon %d, removed from scene" % action.poly.rid)
	)
	history.add_undo_method(func() -> void:
		editor.level.polygons.insert(action.poly.rid, action.poly)
		Logger.log_history("Restored polygon %d before destructive operation" % action.poly.rid)
	)
	history.add_do_reference(action)
	history.add_undo_reference(action)
	
	history.commit_action()

func action_move_thing(action : Tool.Select.ActionMoveThing) -> void:
	history.create_action("Move actor")
	
	if action.thing is Polygon:
		history.add_do_property(action.thing, &"points", action.thing.points)
		history.add_do_method(Logger.log_history.bind("Polygon %d moved to new position" % action.thing.rid))
		
		history.add_undo_property(action.thing, &"points", action.original)
		history.add_undo_method(Logger.log_history.bind("Polygon %d moved to old position" % action.thing.rid))
		
	elif action.thing is ActorBase:
		history.add_do_property(action.thing, &"position", action.thing.position)
		history.add_do_method(Logger.log_history.bind("Actor %s moved to new position" % action.thing._ANAME.to_lower()))
		
		history.add_undo_property(action.thing, &"position", action.original)
		history.add_undo_method(Logger.log_history.bind("Actor %s moved to old position" % action.thing._ANAME.to_lower()))
	
	history.add_do_reference(action)
	history.add_undo_reference(action)
	history.commit_action()

func action_move_point(action : Tool.Poly.ActionModifyPoint) -> void:
	history.create_action("Move polygon point")
	
	history.add_do_method(func() -> void:
		action.poly.points[action.ind] = action.new
		Logger.log_history("Moved polygon point to %d x %d y" % [action.new.x, action.new.y])
	)
	history.add_undo_method(func() -> void:
		action.poly.points[action.ind] = action.original
		Logger.log_history("Reverted polygon point to %d x %d y" % [action.original.x, action.original.y])
	)
	history.add_do_reference(action)
	history.add_undo_reference(action)
	
	history.commit_action()

#func action_move_poly(poly : Polygon, action : Tool.Select.SelectAction) -> void:
	#history.create_action("Polygon moved")
	#

	#history.add_undo_reference(action)
	#
	#history.commit_action()

func action_make_poly(poly : Polygon) -> void:
	history.create_action("Add polygon to scene")
		
	# Add a data reference to stack
	data_ref.push_back(poly)
	
	# Redo/Undo
	history.add_do_method(func() -> void:
		var hist_poly := data_ref.pop_back() as Polygon
		owner.level.polygons.append(hist_poly)
		Logger.log_history("Polygon %d added to scene" % hist_poly.rid)
		owner.polys_updated.emit(owner.level.polygons)
	)
	history.add_undo_method(func() -> void:
		var hist_poly := owner.level.polygons.pop_back() as Polygon
		data_ref.push_back(hist_poly)
		Logger.log_history("Polygon %d removed from scene" % hist_poly.rid)
		owner.polys_updated.emit(owner.level.polygons)
	)
	
	# Commit
	history.commit_action()

func action_stamp(action : Tool.Stamper.ActionStamp) -> void:
	history.create_action("Stamp thing")
	var thing : Variant = action.thing
	
	if thing is ActorBase:
		thing.rid = editor.level.actors.size()
		thing.position = action.mouse_pos
		
		history.add_do_method(func() -> void:
			editor.level.actors.append(thing)
			Logger.log_history("Stamped %s into scene" % thing._ANAME.to_lower())
		)
		history.add_undo_method(func() -> void:
			editor.level.actors.remove_at(thing.rid)
			Logger.log_history("Removed %s from scene" % thing._ANAME.to_lower())
		)
	
	history.add_do_reference(thing)
	history.add_undo_reference(thing)
	history.commit_action()

func action_update_level_property(property : String, value : Variant) -> void:
	history.create_action("Change level property")
	
	# Redo/Undo
	var original = editor.level.get(property)
	history.add_do_property(editor.level, property, value)
	history.add_do_method(func() -> void:
		Logger.log_history("Property %s changed to %s" % [property, value])
	)
	history.add_undo_property(editor.level, property, original)
	history.add_undo_method(func() -> void:
		Logger.log_history("Property %s reverted" % property)
	)
	
	# Commit
	history.commit_action()

func action_update_property(value : Variant, thing : Variant, property : String) -> void:
	history.create_action("Set property")
	var action := ActionProperty.new(thing, property, value, thing.get(property))

	history.add_do_method(func() -> void:
		action.thing.set(action.property, action.n_value)
		Logger.log_history("%s set to %s" % [action.property, action.n_value])
	)
	history.add_undo_method(func() -> void:
		action.thing.set(action.property, action.o_value)
		Logger.log_history("%s reverted to %s" % [action.property, action.o_value])
	)
	
	history.add_do_reference(action)
	history.add_undo_reference(action)
	
	history.commit_action()

class ActionProperty extends Node:
	var thing : Variant
	var property : String
	var n_value : Variant
	var o_value : Variant
	func _init(t : Variant, p : String, n_v : Variant, o_v : Variant) -> void:
		self.thing = t
		self.property = p
		self.n_value = n_v
		self.o_value = o_v

func action_update_lut_color(ind : int, color : Color) -> void:
	history.create_action("Change palette LUT color")
	
	# Redo/Undo
	var original := editor.level.palette.color[ind] as Color
	var action : ActionLUTColor = ActionLUTColor.new(ind, original, color)
	history.add_do_method(func() -> void:
		editor.level.palette.color[action.ind] = action.new
		Logger.log_history("Color %d updated to %s" % [action.ind, action.new.to_html(false)])
	)
	history.add_undo_method(func() -> void:
		editor.level.palette.color[action.ind] = action.original
		Logger.log_history("Color %d reverted to %s" % [action.ind, action.original.to_html(false)])
	)
	history.add_do_reference(action)
	history.add_undo_reference(action)
	
	# Commit action
	history.commit_action()

class ActionLUTColor extends Node:
	var ind : int
	var original : Color
	var new : Color
	func _init(i : int, o : Color, n : Color) -> void:
		self.ind = i
		self.original = o
		self.new = n

func action_update_palette(palette : Palette) -> void:
	history.create_action("Change palette file")
	
	# Redo/Undo
	var original := editor.level.palette as Palette
	var action : ActionPalette = ActionPalette.new(original, palette)
	history.add_do_method(func() -> void:
		editor.level.palette = action.new
		Logger.log_history("Palette file changed.")
	)
	history.add_undo_method(func() -> void:
		editor.level.palette = action.original
		Logger.log_history("Palette reverted to previous.")
	)
	history.add_do_reference(action)
	history.add_undo_reference(action)
	
	# Commit action
	history.commit_action()

class ActionPalette extends Node:
	var original : Palette
	var new : Palette
	func _init(o : Palette, n : Palette) -> void:
		self.original = o
		self.new = n
