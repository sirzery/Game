extends Node
## Global game state: the Scholar's name, stats, inventory, story flags,
## objectives and the save system.

signal inventory_changed
signal objectives_changed
signal stats_changed

const SAVE_PATH := "user://dosier_save.json"
const DEFAULT_NAME := "Elias"
const SAVE_VERSION := 1

var player_name: String = DEFAULT_NAME
var chapter: String = "prolog"
var checkpoint: String = ""
var play_time: float = 0.0
var flags: Dictionary = {}
var inventory: Dictionary = {}
var objectives: Array = []  # Array of Dictionaries {id, text, cur, max, done, optional}
var mc: Dictionary = {}
## Parameters for the next battle (see BattleScene).
var battle_config: Dictionary = {}
## Exploration state that must survive a battle (player position, etc.).
var scene_memory: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	new_game()


func _process(delta: float) -> void:
	play_time += delta


func new_game() -> void:
	player_name = DEFAULT_NAME
	chapter = "prolog"
	checkpoint = ""
	play_time = 0.0
	flags = {}
	inventory = {"akar_pahit": 2}
	objectives = []
	battle_config = {}
	scene_memory = {}
	mc = {
		"level": 1, "exp": 0, "next": 100,
		"hp": 120, "max_hp": 120, "sp": 30, "max_sp": 30,
		"atk": 18, "mag": 14, "def": 8, "spd": 12,
	}
	inventory_changed.emit()
	objectives_changed.emit()
	stats_changed.emit()


# ---------------------------------------------------------------------------
# Text helpers
# ---------------------------------------------------------------------------
func fmt(text: String) -> String:
	return text.replace("{name}", player_name)


func sanitize_name(raw: String) -> String:
	var out := ""
	for ch in raw.strip_edges():
		var c := ch.unicode_at(0)
		var ok := (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or (c >= 48 and c <= 57) \
			or ch == " " or ch == "-" or ch == "'" or c >= 192
		if ok:
			out += ch
	out = out.strip_edges()
	while out.contains("  "):
		out = out.replace("  ", " ")
	return out.substr(0, 12)


# ---------------------------------------------------------------------------
# Flags
# ---------------------------------------------------------------------------
func set_flag(key: String, value: Variant = true) -> void:
	flags[key] = value


func get_flag(key: String, fallback: Variant = false) -> Variant:
	return flags.get(key, fallback)


func has_flag(key: String) -> bool:
	return bool(flags.get(key, false))


# ---------------------------------------------------------------------------
# Inventory
# ---------------------------------------------------------------------------
func add_item(id: String, count: int = 1) -> void:
	inventory[id] = int(inventory.get(id, 0)) + count
	inventory_changed.emit()


func remove_item(id: String, count: int = 1) -> bool:
	var have := int(inventory.get(id, 0))
	if have < count:
		return false
	have -= count
	if have <= 0:
		inventory.erase(id)
	else:
		inventory[id] = have
	inventory_changed.emit()
	return true


func item_count(id: String) -> int:
	return int(inventory.get(id, 0))


# ---------------------------------------------------------------------------
# Objectives
# ---------------------------------------------------------------------------
func add_objective(id: String, text: String, max_count: int = 1, optional: bool = false) -> void:
	for o in objectives:
		if o["id"] == id:
			return
	objectives.append({"id": id, "text": text, "cur": 0, "max": max_count, "done": false, "optional": optional})
	objectives_changed.emit()


func progress_objective(id: String, amount: int = 1) -> bool:
	## Returns true when this call completed the objective.
	for o in objectives:
		if o["id"] == id and not o["done"]:
			o["cur"] = mini(int(o["cur"]) + amount, int(o["max"]))
			if int(o["cur"]) >= int(o["max"]):
				o["done"] = true
				objectives_changed.emit()
				return true
			objectives_changed.emit()
			return false
	return false


func objective_done(id: String) -> bool:
	for o in objectives:
		if o["id"] == id:
			return bool(o["done"])
	return false


func required_objectives_done(ids: Array) -> bool:
	for id in ids:
		if not objective_done(str(id)):
			return false
	return true


func clear_objectives() -> void:
	objectives.clear()
	objectives_changed.emit()


# ---------------------------------------------------------------------------
# Progression
# ---------------------------------------------------------------------------
func gain_exp(amount: int) -> Array:
	## Returns a list of level-up messages.
	var msgs: Array = []
	mc["exp"] = int(mc["exp"]) + amount
	while int(mc["exp"]) >= int(mc["next"]):
		mc["exp"] = int(mc["exp"]) - int(mc["next"])
		mc["level"] = int(mc["level"]) + 1
		mc["next"] = int(round(float(mc["next"]) * 1.5))
		mc["max_hp"] = int(mc["max_hp"]) + 14
		mc["max_sp"] = int(mc["max_sp"]) + 4
		mc["atk"] = int(mc["atk"]) + 2
		mc["mag"] = int(mc["mag"]) + 2
		mc["def"] = int(mc["def"]) + 1
		mc["spd"] = int(mc["spd"]) + 1
		mc["hp"] = int(mc["max_hp"])
		mc["sp"] = int(mc["max_sp"])
		msgs.append("Level naik! Lv %d" % int(mc["level"]))
	stats_changed.emit()
	return msgs


func heal_full() -> void:
	mc["hp"] = int(mc["max_hp"])
	mc["sp"] = int(mc["max_sp"])
	stats_changed.emit()


# ---------------------------------------------------------------------------
# Save / load
# ---------------------------------------------------------------------------
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game(scene_path: String = "") -> bool:
	if scene_path != "":
		checkpoint = scene_path
	var data := {
		"version": SAVE_VERSION,
		"player_name": player_name,
		"chapter": chapter,
		"checkpoint": checkpoint,
		"play_time": play_time,
		"flags": flags,
		"inventory": inventory,
		"objectives": objectives,
		"mc": mc,
		"scene_memory": _memory_to_json(scene_memory),
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Tidak bisa menyimpan permainan: %s" % error_string(FileAccess.get_open_error()))
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	return true


func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Berkas simpanan rusak.")
		return false
	var d: Dictionary = parsed
	new_game()
	player_name = str(d.get("player_name", DEFAULT_NAME))
	chapter = str(d.get("chapter", "prolog"))
	checkpoint = str(d.get("checkpoint", ""))
	play_time = float(d.get("play_time", 0.0))
	flags = _as_dict(d.get("flags", {}))
	var inv := _as_dict(d.get("inventory", {}))
	inventory = {}
	for k in inv.keys():
		inventory[str(k)] = int(inv[k])
	var objs: Variant = d.get("objectives", [])
	objectives = []
	if typeof(objs) == TYPE_ARRAY:
		for o in objs:
			if typeof(o) == TYPE_DICTIONARY:
				var od: Dictionary = o
				objectives.append({
					"id": str(od.get("id", "")), "text": str(od.get("text", "")),
					"cur": int(od.get("cur", 0)), "max": int(od.get("max", 1)),
					"done": bool(od.get("done", false)), "optional": bool(od.get("optional", false)),
				})
	var m := _as_dict(d.get("mc", {}))
	for k in mc.keys():
		if m.has(k):
			mc[k] = int(m[k])
	scene_memory = _memory_from_json(_as_dict(d.get("scene_memory", {})))
	inventory_changed.emit()
	objectives_changed.emit()
	stats_changed.emit()
	return checkpoint != ""


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


static func _as_dict(v: Variant) -> Dictionary:
	if typeof(v) == TYPE_DICTIONARY:
		return v
	return {}


static func _memory_to_json(mem: Dictionary) -> Dictionary:
	var out := {}
	for k in mem.keys():
		var v: Variant = mem[k]
		if typeof(v) == TYPE_VECTOR2:
			var vv: Vector2 = v
			out[k] = {"__v2": [vv.x, vv.y]}
		else:
			out[k] = v
	return out


static func _memory_from_json(mem: Dictionary) -> Dictionary:
	var out := {}
	for k in mem.keys():
		var v: Variant = mem[k]
		if typeof(v) == TYPE_DICTIONARY and (v as Dictionary).has("__v2"):
			var arr: Array = (v as Dictionary)["__v2"]
			out[k] = Vector2(float(arr[0]), float(arr[1]))
		else:
			out[k] = v
	return out
