### level.gd
class_name Level extends Resource

## Level extension
const EXT := ".mlf"
## Level format specification
const SPEC := 1
## Default level palette
const PAL_DEFAULT := [
	Color.WHITE,
	Color.LIGHT_GRAY,
	Color.GRAY,
	Color.DARK_GRAY,
	Color.DIM_GRAY,
	Color.BLACK
]

## User defined save path
var path := ""
## Level name
var level_name := ""
## Level author
var level_author := ""
## Collection of polygons
var polygons : Array[Polygon]
## Collection of actors
var actors : Array[ActorBase]
## Color palette (LUT)
var palette : Palette = Palette.new(PackedColorArray(PAL_DEFAULT))

func _init(path : String = "") -> void:
	if path != "":
		self.deserialize(path)

## Writes data to binary JSON file
func serialize() -> void:
	var data : Dictionary = {}
	
	data.specification = SPEC
	data.level_name = level_name
	data.level_author = level_author
	data.palette = palette.color
	data.polygons = {}
	
	for id in range(polygons.size()):
		var poly := polygons[id] as Polygon
		data.polygons[poly.rid] = {}
		data.polygons[poly.rid]["points"] = poly.points
		data.polygons[poly.rid]["color"] = poly.color
	
	var t_actors := {}
	for actor in actors:
		t_actors.merge(actor._serialize())
	data.actors = t_actors
		
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_var(data)
	file.close()

## Loads data from binary JSON file
func deserialize(target_path : String) -> void:
	if target_path.right(4) != EXT:
		push_error("Level format invalid")
		return
	
	path = target_path
	var file := FileAccess.open(target_path, FileAccess.READ)
	
	if !file:
		push_error("File does not exist")
		return
	
	# Load dictionary
	var data : Dictionary = file.get_var()
	file.close()
	
	if data.specification > SPEC:
		push_error("Specification too new")
		return
	
	print(JSON.stringify(data, " "))
	
	# Load metadata
	level_name = data.get("level_name", "NULL")
	level_author = data.get("level_author", "NULL")
	palette = Palette.new(data.palette) if data.has("palette") else Palette.new(PackedColorArray(PAL_DEFAULT))
	
	# Load polygons
	var keys : Array = data.polygons.keys()
	for key in keys:
		var polygon := Polygon.new(key)
		polygon.points = data.polygons[key]["points"]
		polygon.color = data.polygons[key]["color"]
		polygons.append(polygon)
	
	# Load actors
	keys = data.actors.keys()
	for key in keys:
		var clazz : String = data.actors[key].get("class", null)
		actors.append(deserialize_actor(clazz, data.actors[key]))

## Deserializes an actor based on data
func deserialize_actor(clazz : String, data : Dictionary) -> ActorBase:
	var actor = actor_class_from_name(clazz)
	actor._deserialize(data)
	return actor

func actor_class_from_name(clazz : String) -> ActorBase:
	var dicts = ProjectSettings.get_global_class_list() as Array[Dictionary]
	for dict in dicts:
		if dict["class"] == clazz:
			return load(dict["path"]).new()
	return null

## Updates color LUT
func update_color_lut(lut : PackedColorArray) -> void:
	self.color_lut = lut
