### palette.gd
class_name Palette extends Resource

## Intended max size for color set
const SIZE = 16
## File extension
const EXT = ".mpal"
## File identifier (header)
const HEADER = [112, 97, 108, 101, 116, 116, 101, 0]

var color : PackedColorArray = PackedColorArray() :
	set(value) :
		if value.size() > SIZE:
			# Make sure size matches
			value.resize(SIZE)
		if value.size() < SIZE:
			# Add padding
			var pad := PackedColorArray()
			pad.resize(SIZE - value.size())
			pad.fill(Color.MAGENTA)
			value += pad
		# Set value
		color = value

func _init(override : Variant) -> void:
	if override is PackedColorArray:
		self.color = override
	
	if override is String:
		self.deserialize(override)
	
	if override is Palette:
		self.color = override.color

func serialize(path : String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	
	# Store header
	var buf := PackedByteArray(HEADER)
	file.store_buffer(buf)
	
	# Store color
	for col in color:
		file.store_32(col.to_rgba32())
	
	# End serialization
	file.close()

func deserialize(path : String) -> void:
	# Check extension
	if path.right(5) != EXT:
		push_error("Not a valid palette file. - Invalid extension")
		return
	
	# Open file
	var file := FileAccess.open(path, FileAccess.READ)
	var header := file.get_buffer(HEADER.size())
	
	# Fail if header doesnt match
	if header.get_string_from_ascii() != "palette":
		push_error("Not a valid palette file. - Header mismatch")
		file.close()
		return
	
	var new_color := PackedColorArray()
	while file.get_position() < file.get_length():
		var int_col := file.get_32()
		new_color.append(Color.hex(int_col))
	self.color = new_color
	file.close()
