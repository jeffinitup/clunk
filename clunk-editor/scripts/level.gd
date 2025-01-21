### level.gd
class_name Level extends Resource

## Level extension
const EXT := ".mlf"
## Level format specification
const SPEC := 0

## User defined save path
var path := ""
## Level name
var level_name := ""
## Collection of polygons
var polygons : Array[Editor.Polygon]

func _init(path : String = "") -> void:
	if path != "":
		self.deserialize(path)

## Writes data to binary JSON file
func serialize() -> void:
	var data : Dictionary = {}
	
	data.specification = SPEC
	data.level_name = level_name
	data.polygons = {}
	
	for id in range(polygons.size()):
		var poly := polygons[id] as Editor.Polygon
		data.polygons[poly.rid] = {}
		data.polygons[poly.rid]["points"] = poly.points
		data.polygons[poly.rid]["colors"] = poly.colors
	
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
	
	# Load metadata
	level_name = data.level_name
	
	# Load polygons
	var keys = data.polygons.keys()
	for key in keys:
		var polygon := Editor.Polygon.new(key)
		polygon.points = data.polygons[key]["points"]
		polygon.colors = data.polygons[key]["colors"]
		polygons.append(polygon)
	print("Done.")
