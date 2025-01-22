### palette.gd
class_name Palette extends Resource

## Intended max size for color set
const SIZE = 16
## File extension
const EXT = ".mpal"
## File identifier (header)
const HEADER = [112, 97, 108, 101, 116, 116, 101]

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

func _init(c_a : PackedColorArray) -> void:
	self.color = c_a
	

func serialize(path : String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	
	# Store header
	var buf := PackedByteArray(HEADER)
	file.store_buffer(buf)
	
	# Store color
	buf = color.to_byte_array()
	file.store_buffer(buf)
	
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
	
	file.get_buffer(file.get_length() - HEADER.size())
	
	
