### cam.gd
class_name EditorCamera extends Camera2D

## Determines if middle mouse button is held
var held : bool = false
## Factor to zoom with
var zoom_fac : float = 1.0 :
	set(value) : 
		zoom_fac = value
		zoom = Vector2.ONE * zoom_fac

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			held = event.is_pressed()
		
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_fac = max(zoom_fac - 0.1, 0.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_fac = min(zoom_fac + 0.1, 3.0)
	
	if event is InputEventMouseMotion:
		if held:
			translate(-event.relative / zoom_fac)
