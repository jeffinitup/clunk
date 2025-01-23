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

func action_move_poly(poly : Editor.Polygon, action : Tool.Select.SelectAction) -> void:
	history.create_action("Polygon moved")
	
	history.add_do_property(poly, &"points", poly.points)
	history.add_do_method(func() -> void:
		Logger.log_history("Polygon %d moved to new position" % action.rid)
	)

	history.add_undo_property(poly, &"points", action.original)
	history.add_undo_method(func() -> void:
		Logger.log_history("Polygon %d moved to old position" % action.rid)
	)
	history.add_undo_reference(action)
	
	history.commit_action()

func action_make_poly(poly : Editor.Polygon) -> void:
	history.create_action("Add polygon to scene")
		
	# Add a data reference to stack
	data_ref.push_back(poly)
	
	# Redo/Undo
	history.add_do_method(func() -> void:
		var hist_poly := data_ref.pop_back() as Editor.Polygon
		owner.level.polygons.append(hist_poly)
		Logger.log_history("Polygon %d added to scene" % hist_poly.rid)
		owner.polys_updated.emit(owner.level.polygons)
	)
	history.add_undo_method(func() -> void:
		var hist_poly := owner.level.polygons.pop_back() as Editor.Polygon
		data_ref.push_back(hist_poly)
		Logger.log_history("Polygon %d removed from scene" % hist_poly.rid)
		owner.polys_updated.emit(owner.level.polygons)
	)
	
	# Commit
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
