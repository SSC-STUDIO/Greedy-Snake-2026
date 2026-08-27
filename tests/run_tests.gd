extends Node
## Test runner root for res://tests/run_tests.tscn.
## Run headless:
##   godot --headless --path "<project>" res://tests/run_tests.tscn
## Exit code 0 = all green, 1 = failures. Autoloads (GameEvents) are live
## because we launch a scene through normal project startup.

const CASES_DIR := "res://tests"


func _ready() -> void:
	await get_tree().process_frame
	var total := 0
	var failed := 0
	for path in _case_paths():
		var script: GDScript = load(path)
		if script == null:
			continue
		var methods: Array[String] = _test_methods(script)
		for method in methods:
			total += 1
			var case: TestCase = script.new()
			case.name = "%s.%s" % [path.get_file().get_basename(), method]
			add_child(case)
			case.setup()
			await case.call(method)
			case.teardown()
			var f := case.failure_count()
			failed += 1 if f > 0 else 0
			print("[%s] %s (%d asserts)" % ["PASS" if f == 0 else "FAIL", case.name, case._case_passed])
			for msg in case.failures():
				print("     - ", msg)
			case.queue_free()
			await get_tree().process_frame
	print("=".repeat(48))
	print("%s — %d/%d passed" % ["OK" if failed == 0 else "FAILED", total - failed, total])
	get_tree().quit(0 if failed == 0 else 1)


func _case_paths() -> PackedStringArray:
	var paths: PackedStringArray = []
	var dir := DirAccess.open(CASES_DIR)
	if dir == null:
		return paths
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with("_test.gd"):
			paths.append(CASES_DIR + "/" + fname)
		fname = dir.get_next()
	dir.list_dir_end()
	paths.sort()
	return paths


func _test_methods(script: GDScript) -> Array[String]:
	var probe: TestCase = script.new()
	var names: Array[String] = []
	for info in probe.get_method_list():
		if String(info["name"]).begins_with("test_") and int(info["args"].size()) == 0:
			names.append(info["name"])
	probe.free()
	names.sort()
	return names
