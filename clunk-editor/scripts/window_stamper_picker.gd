### window_stamper_picker.gd
class_name WindowStamperPicker extends Window

## Fired when item picked
signal stamp_picked(stamp : Variant)

enum {
	ACTOR,
	GEOMETRY,
	OBJECT,
}

## Reference to actor list
@onready var list_actor := get_node("margin/sort/TabContainer/Actors") as ItemList
## Reference to geometry list
@onready var list_geometry := get_node("margin/sort/TabContainer/Geometry") as ItemList
## Reference to object list
@onready var list_object := get_node("margin/sort/TabContainer/Object") as ItemList

func _ready() -> void:
	# Set signals
	list_actor.item_activated.connect(item_selected.bind(ACTOR))
	list_geometry.item_activated.connect(item_selected.bind(GEOMETRY))
	list_object.item_activated.connect(item_selected.bind(OBJECT))
	
	# Populate actor list
	var alist := ActorList.actors
	for entry in alist:
		list_actor.add_item(entry._ANAME)

func item_selected(id : int, type : int) -> void:
	var stamp : Variant = null
	match type:
		ACTOR:
			stamp = ActorList.actors[id]
		GEOMETRY:
			pass
		OBJECT:
			pass
	
	stamp_picked.emit(stamp)
	close_menu()
	
func close_menu() -> void:
	queue_free()
