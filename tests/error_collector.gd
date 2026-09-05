extends Logger
## Engine and script errors must fail tests even when an interrupted method
## never reaches an assertion. Warnings remain visible but are not failures.

var _errors: PackedStringArray = []
var _mutex := Mutex.new()


func _log_error(function: String, file: String, line: int, code: String,
		rationale: String, _editor_notify: bool, error_type: int,
		_script_backtraces: Array[ScriptBacktrace]) -> void:
	if error_type == Logger.ERROR_TYPE_WARNING:
		return
	_mutex.lock()
	_errors.append("%s:%d %s: %s %s" % [file, line, function, code, rationale])
	_mutex.unlock()


func errors() -> PackedStringArray:
	_mutex.lock()
	var result := _errors.duplicate()
	_mutex.unlock()
	return result
