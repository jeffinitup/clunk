### level.gd
class_name Level extends Resource

## Level extension
const EXT := ".mlf"
## Level format specification
const SPEC := 1

## User defined save path
var path := ""
## Level name
var level_name := ""
## Level author
var level_author := ""
## Collection of polygons
var polygons : Array[Editor.Polygon]
## Color palette (LUT)
var palette : Palette = Palette.new(PackedColorArray([
	Color.WHITE,
	Color.LIGHT_GRAY,
	Color.GRAY,
	Color.DARK_GRAY,
	Color.DIM_GRAY,
	Color.BLACK
]))

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
		var poly := polygons[id] as Editor.Polygon
		data.polygons[poly.rid] = {}
		data.polygons[poly.rid]["points"] = poly.points
		data.polygons[poly.rid]["color"] = poly.color
	
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
	level_name = data.level_name
	level_author = data.level_author
	palette = Palette.new(data.palette)
	
	# Load polygons
	var keys = data.polygons.keys()
	for key in keys:
		var polygon := Editor.Polygon.new(key)
		polygon.points = data.polygons[key]["points"]
		polygon.color = data.polygons[key]["color"]
		polygons.append(polygon)

## Updates color LUT
func update_color_lut(lut : PackedColorArray) -> void:
	self.color_lut = lut
