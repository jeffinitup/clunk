### logger.gd
extends Node

## Fired when a new message is logged
signal message_logged(msg : String)

enum {
	DEFAULT,
	WARNING,
	ERROR,
	HISTORY
}

func log_string(message : String, type : int) -> void:
	var prefix := get_prefix(type)
	message = prefix + message
	message_logged.emit(message)

func log_default(message : String) -> void:
	log_string(message, DEFAULT)

func log_warning(message : String) -> void:
	log_string(message, WARNING)
	
func log_error(message : String) -> void:
	log_string(message, ERROR)

func log_history(message : String) -> void:
	log_string(message, HISTORY)

func get_prefix(type : int) -> String:
	match type:
		HISTORY:
			return "[color=darkgray][i][HISTORY] - "
		_:
			return "[color=gray][INFO] - "
