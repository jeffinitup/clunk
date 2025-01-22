### palette.gd
class_name Palette extends Resource

## Intended max size for color set
const SIZE = 16

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
