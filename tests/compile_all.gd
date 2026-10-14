extends Node
## Developer check: loads (compiles) every GDScript and shader in the project
## and reports failures. Run:
##   godot --headless --path . res://tests/compile_all.tscn
## Combine with an override.cfg that sets
##   debug/gdscript/warnings/treat_warnings_as_errors=true
## to make every warning fail as well.


func _ready() -> void:
	var files: Array[String] = []
	_collect("res://scripts", files)
	_collect("res://shaders", files)
	_collect("res://tests", files)
	var failed := 0
	for f in files:
		var res := load(f)
		var ok := res != null
		if res is GDScript:
			ok = (res as GDScript).can_instantiate() or (res as GDScript).is_abstract()
		if not ok:
			failed += 1
			print("[compile] FAILED: ", f)
	print("[compile] checked %d files, %d failed" % [files.size(), failed])
	get_tree().quit(1 if failed > 0 else 0)


func _collect(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var n := dir.get_next()
	while n != "":
		var p := dir_path + "/" + n
		if dir.current_is_dir():
			if not n.begins_with("."):
				_collect(p, out)
		elif n.ends_with(".gd") or n.ends_with(".gdshader"):
			out.append(p)
		n = dir.get_next()
	dir.list_dir_end()
