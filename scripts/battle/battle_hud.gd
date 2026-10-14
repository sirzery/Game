class_name BattleHUD
extends CanvasLayer
## Persona-inspired battle interface.

const ROOT_COMMANDS := {
	"allout": ["HABISI!", "Semua musuh terguncang. Lancarkan serangan penghabisan!"],
	"attack": ["SERANG", "Cambuk Rantai — serangan TUMPUL. BOOST menambah jumlah pukulan."],
	"skill": ["KEAHLIAN", "Gunakan keahlian bertahan hidup sang cendekia (memakai SP)."],
	"observe": ["AMATI", "Mata cendekia: ungkap kelemahan, HP, dan niat musuh. GRATIS, sekali per musuh."],
	"guard": ["BERTAHAN", "Kurangi damage yang diterima sebesar 60% hingga giliranmu berikutnya."],
	"item": ["BARANG", "Gunakan barang dari kantongmu."],
	"flee": ["KABUR", "Lari dari pertarungan ini."],
}

var battle: Node2D
var root: Control
var status: StatusCard
var order_bar: OrderBar
var desc_panel: DescPanel
var banner: ActionBanner
var plates: Dictionary = {}  # Battler -> EnemyPlate
var cursor: TargetCursor
var _menu_snapped: bool = false


func _init() -> void:
	layer = 60


func _ready() -> void:
	root = UIKit.full_rect(Control.new())
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	order_bar = OrderBar.new()
	order_bar.position = Vector2(360, 18)
	root.add_child(order_bar)
	status = StatusCard.new()
	status.position = Vector2(860, 560)
	root.add_child(status)
	desc_panel = DescPanel.new()
	desc_panel.position = Vector2(40, 640)
	desc_panel.visible = false
	root.add_child(desc_panel)
	banner = ActionBanner.new()
	banner.position = Vector2(0, 92)
	root.add_child(banner)
	cursor = TargetCursor.new()
	cursor.visible = false
	root.add_child(cursor)


func to_screen(world_pos: Vector2) -> Vector2:
	return battle.get_viewport().get_canvas_transform() * world_pos


# ---------------------------------------------------------------------------
# Status / plates
# ---------------------------------------------------------------------------
func bind(mc: Battler, enemies: Array) -> void:
	status.bind(mc)
	for e in enemies:
		var b: Battler = e
		var p := EnemyPlate.new()
		p.bind(b)
		root.add_child(p)
		plates[b] = p
	refresh()


func refresh() -> void:
	status.queue_redraw()
	status.refresh()
	for b in plates.keys():
		var bat: Battler = b
		var p: EnemyPlate = plates[b]
		p.visible = bat.alive()
		p.position = to_screen(bat.home + Vector2(-34, -78))
		p.refresh()


func set_order(order: Array, current: int) -> void:
	order_bar.set_order(order, current)


# ---------------------------------------------------------------------------
# Feedback
# ---------------------------------------------------------------------------
func show_banner(text: String, color: Color = UIKit.BLACK) -> void:
	banner.show_text(text, color)


func hide_banner() -> void:
	banner.hide_text()


func popup(world_pos: Vector2, text: String, color: Color = UIKit.BONE, size_px: int = 44,
		outline_color: Color = UIKit.BLACK) -> void:
	var l := UIKit.label(text, size_px, color, UIKit.head_font(), HORIZONTAL_ALIGNMENT_CENTER)
	UIKit.outline(l, 10, outline_color)
	l.size = Vector2(300, size_px * 1.3)
	l.pivot_offset = l.size * 0.5
	l.position = to_screen(world_pos) - l.size * 0.5 + Vector2(randf_range(-14.0, 14.0), 0)
	l.rotation = deg_to_rad(randf_range(-8.0, 4.0))
	l.scale = Vector2(1.6, 1.6)
	root.add_child(l)
	var t := l.create_tween()
	t.tween_property(l, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "position:y", l.position.y - 46.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.35).set_delay(0.5)
	t.tween_callback(l.queue_free)


func tutorial(title: String, body: String) -> void:
	var card := TutorialCard.new(title, body)
	UIKit.full_rect(card)
	root.add_child(card)
	await card.run()
	card.queue_free()


# ---------------------------------------------------------------------------
# Command selection
# ---------------------------------------------------------------------------
func choose_command(mc: Battler, enemies: Array, ctx: Dictionary) -> Dictionary:
	if Settings.autotest:
		if not _menu_snapped and Settings.autotest_shots_dir != "":
			# show the real menu once so the play-test captures it
			_menu_snapped = true
			var preview := CommandMenu.new(["SERANG", "KEAHLIAN", "AMATI", "BERTAHAN", "BARANG"])
			preview.bp = mc.bp
			preview.boost_max = mini(3, mc.bp)
			root.add_child(preview)
			desc_panel.visible = true
			desc_panel.set_text(str(ROOT_COMMANDS["attack"][1]))
			await get_tree().create_timer(0.3, false).timeout
			await Router.snap("battle_menu")
			preview.queue_free()
			desc_panel.visible = false
		await get_tree().create_timer(0.25, false).timeout
		return _auto_command(mc, enemies, ctx)
	var keys: Array = []
	if bool(ctx.get("allout", false)):
		keys.append("allout")
	keys.append_array(["attack", "skill", "observe", "guard", "item"])
	if bool(ctx.get("can_flee", false)):
		keys.append("flee")
	var labels: Array = []
	for k in keys:
		labels.append(ROOT_COMMANDS[k][0])
	var menu := CommandMenu.new(labels)
	menu.boost_max = mini(3, mc.bp)
	menu.bp = mc.bp
	root.add_child(menu)
	desc_panel.visible = true
	var result := {}
	while result.is_empty():
		desc_panel.set_text(str(ROOT_COMMANDS[keys[menu.index]][1]))
		var picked: int = await menu.run(func(i: int) -> void:
			desc_panel.set_text(str(ROOT_COMMANDS[keys[i]][1])))
		var key: String = keys[picked]
		var boost := menu.boost
		match key:
			"allout":
				result = {"action": "allout", "boost": 0}
			"attack":
				var tgt := await _pick_target(enemies, false)
				if tgt != null:
					result = {"action": "skill", "id": "chain_lash", "boost": boost, "target": tgt}
			"skill":
				menu.visible = false
				var sid := await _pick_from_list(_skill_entries(mc), "KEAHLIAN")
				menu.visible = true
				if sid != "":
					var sk: Dictionary = BattleData.SKILLS[sid]
					if str(sk["type"]) == "heal":
						result = {"action": "skill", "id": sid, "boost": boost, "target": mc}
					else:
						var tgt2 := await _pick_target(enemies, false)
						if tgt2 != null:
							result = {"action": "skill", "id": sid, "boost": boost, "target": tgt2}
			"observe":
				var tgt3 := await _pick_target(enemies, true)
				if tgt3 != null:
					result = {"action": "observe", "boost": 0, "target": tgt3}
			"guard":
				result = {"action": "guard", "boost": 0}
			"item":
				menu.visible = false
				var iid := await _pick_from_list(_item_entries(), "BARANG")
				menu.visible = true
				if iid != "":
					result = {"action": "item", "id": iid, "boost": 0, "target": mc}
			"flee":
				result = {"action": "flee", "boost": 0}
	menu.queue_free()
	desc_panel.visible = false
	return result


func _skill_entries(mc: Battler) -> Array:
	var out: Array = []
	for sid in BattleData.MC_SKILLS:
		var sk: Dictionary = BattleData.SKILLS[sid]
		var cost := int(sk["sp"])
		out.append({"id": sid, "name": str(sk["name"]), "right": "%d SP" % cost, "icon": BattleData.element_icon(
			str(sk["type"])) if str(sk["type"]) != "heal" else "res://assets/sprites/ui/icon_herb.png",
			"desc": str(sk["desc"]), "enabled": mc.sp >= cost})
	return out


func _item_entries() -> Array:
	var out: Array = []
	for iid in BattleData.ITEMS.keys():
		var n := GameState.item_count(str(iid))
		if n <= 0:
			continue
		var it: Dictionary = BattleData.ITEMS[iid]
		out.append({"id": str(iid), "name": str(it["name"]), "right": "x%d" % n,
			"icon": "res://assets/sprites/ui/icon_herb.png", "desc": str(it["desc"]), "enabled": true})
	return out


func _pick_from_list(entries: Array, title: String) -> String:
	if entries.is_empty():
		Audio.sfx("ui_cancel")
		desc_panel.set_text("Kantongmu kosong. Bahkan remah roti pun tidak ada.")
		await get_tree().create_timer(0.6, false).timeout
		return ""
	var list := SubList.new(entries, title)
	root.add_child(list)
	var idx: int = await list.run(func(i: int) -> void:
		desc_panel.set_text(str(entries[i]["desc"])))
	list.queue_free()
	if idx < 0:
		return ""
	return str(entries[idx]["id"])


func _pick_target(enemies: Array, only_unobserved: bool) -> Battler:
	var pool: Array = []
	for e in enemies:
		var b: Battler = e
		if b.alive() and (not only_unobserved or not b.observed):
			pool.append(b)
	if pool.is_empty():
		Audio.sfx("ui_cancel")
		desc_panel.set_text("Kau sudah mengamati semuanya. Catatanmu lengkap—untuk saat ini.")
		await get_tree().create_timer(0.6, false).timeout
		return null
	if pool.size() == 1:
		return pool[0]
	var i := 0
	cursor.visible = true
	var waited := 0.0
	while true:
		var cur: Battler = pool[i]
		cursor.position = to_screen(cur.home + Vector2(0, -70))
		await get_tree().process_frame
		waited += get_process_delta_time()
		if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_up"):
			i = (i - 1 + pool.size()) % pool.size()
			Audio.sfx("ui_move", -8.0)
		elif Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("move_down"):
			i = (i + 1) % pool.size()
			Audio.sfx("ui_move", -8.0)
		elif Input.is_action_just_pressed("accept") and waited > 0.12:
			Audio.sfx("ui_confirm")
			cursor.visible = false
			return cur
		elif Input.is_action_just_pressed("cancel"):
			Audio.sfx("ui_cancel")
			cursor.visible = false
			return null
	return null


func _auto_command(mc: Battler, enemies: Array, ctx: Dictionary) -> Dictionary:
	## Simple decision policy used by the automated play-test.
	var target: Battler = null
	for e in enemies:
		var b: Battler = e
		if b.alive():
			target = b
			break
	if target == null:
		return {"action": "guard", "boost": 0}
	if bool(ctx.get("allout", false)):
		return {"action": "allout", "boost": 0}
	if not target.observed:
		return {"action": "observe", "boost": 0, "target": target}
	if mc.hp < mc.max_hp * 0.35 and GameState.item_count("akar_pahit") > 0:
		return {"action": "item", "id": "akar_pahit", "boost": 0, "target": mc}
	if not target.charging.is_empty():
		return {"action": "guard", "boost": 0}
	var boost := mini(mc.bp, 3) if mc.bp >= 3 else 0
	if target.weak.has("pierce") and mc.sp >= 3 and not target.is_broken():
		return {"action": "skill", "id": "stone_throw", "boost": boost, "target": target}
	if target.weak.has("fire") and mc.sp >= 6:
		return {"action": "skill", "id": "torch", "boost": boost, "target": target}
	return {"action": "skill", "id": "chain_lash", "boost": boost, "target": target}


# ---------------------------------------------------------------------------
# End screens
# ---------------------------------------------------------------------------
func victory(lines: Array) -> void:
	var v := VictoryScreen.new(lines)
	UIKit.full_rect(v)
	root.add_child(v)
	await v.run()


func defeat() -> int:
	var d := DefeatScreen.new()
	UIKit.full_rect(d)
	root.add_child(d)
	var pick: int = await d.run()
	d.queue_free()
	return pick


func all_out(portrait: Texture2D) -> void:
	var a := AllOutOverlay.new(portrait)
	UIKit.full_rect(a)
	root.add_child(a)
	await a.run()
	a.queue_free()
