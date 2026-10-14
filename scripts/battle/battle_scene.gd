extends StageScene
## Turn-based battle.
##
## Configure through GameState.battle_config before loading this scene:
##   enemies: Array[String]     ids from BattleData.ENEMIES
##   bg: String                 background texture path
##   music: String              bgm name
##   next: String               scene to load after victory
##   tutorial: bool             show the first-battle guide
##   can_flee: bool
##   intro: String              optional opening line

const ENEMY_SLOTS := [Vector2(150, 206), Vector2(104, 188), Vector2(110, 226)]
const MC_SLOT := Vector2(318, 206)

var hud: BattleHUD
var mc: Battler
var enemies: Array = []
var config: Dictionary = {}
var turn_count: int = 0
var over: bool = false
var won: bool = false
var fled: bool = false
var _snapshot_mc: Dictionary = {}
var _snapshot_inv: Dictionary = {}
var _tips: Dictionary = {}


func setup() -> void:
	allow_skip = false
	config = GameState.battle_config.duplicate(true)
	if config.is_empty():
		config = {"enemies": ["hound"], "bg": "res://assets/sprites/backgrounds/battle_forest.png",
			"music": "battle", "next": "res://scenes/ui/title.tscn", "tutorial": true, "can_flee": false}
	_snapshot_mc = GameState.mc.duplicate(true)
	_snapshot_inv = GameState.inventory.duplicate(true)
	post.apply_preset("battle")
	ambient.color = Color(0.62, 0.66, 0.86)
	cam.position = Vector2(240, 150)
	cam.zoom = Vector2(3, 3)
	add_sprite(str(config.get("bg", "res://assets/sprites/backgrounds/battle_forest.png")), Vector2.ZERO, ground,
		false, false)
	add_light(Vector2(360, 40), Color(0.75, 0.82, 1.0), 0.9, 600.0, 0.0, 120.0)
	add_light(Vector2(250, 250), Color(1.0, 0.6, 0.35), 0.5, 260.0, 0.15, 30.0)
	spawn_fx(FX.fireflies(Vector2(440, 120), 20), Vector2(240, 190))
	spawn_fx(FX.dust(Vector2(440, 200), 30, Color(0.7, 0.8, 1.0)), Vector2(240, 150))

	mc = Battler.new()
	world.add_child(mc)
	mc.setup_player(GameState.mc, GameState.player_name)
	mc.home = MC_SLOT
	mc.position = MC_SLOT + Vector2(80, 0)
	var ids: Array = config.get("enemies", ["hound"])
	for i in ids.size():
		var e := Battler.new()
		world.add_child(e)
		e.setup_enemy(str(ids[i]))
		e.home = ENEMY_SLOTS[mini(i, ENEMY_SLOTS.size() - 1)]
		e.position = e.home - Vector2(80, 0)
		enemies.append(e)

	hud = BattleHUD.new()
	hud.battle = self
	add_child(hud)


func run() -> void:
	Audio.play_music(str(config.get("music", "battle")), 0.3)
	# entrance
	post.flash(Color(1.0, 0.2, 0.25), 0.4, 0.6)
	var t := create_tween().set_parallel(true)
	t.tween_property(mc, "position", mc.home, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for e in enemies:
		var b: Battler = e
		t.tween_property(b, "position", b.home, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t.finished
	hud.bind(mc, enemies)
	await cine.banner("PERTEMPURAN!", UIKit.RED, 0.5, 110)
	if str(config.get("intro", "")) != "":
		await say("mc", str(config["intro"]), "angry")
		await close_dialogue()
	if bool(config.get("tutorial", false)):
		await hud.tutorial("PERTARUNGAN BERGILIR",
			"Pilih perintah dengan [b]ATAS/BAWAH[/b], konfirmasi dengan [b]ENTER[/b], batal dengan [b]ESC[/b].\n" +
			"Urutan giliran ditentukan oleh kecepatan (SPD) dan tampil di bagian atas layar.")
		await hud.tutorial("AMATI — MATA CENDEKIA",
			"Kelemahan musuh tersembunyi sebagai [b]?[/b]. Gunakan [b]AMATI[/b] untuk mengungkap kelemahan, HP, " +
			"dan niat musuh. Gratis — tidak menghabiskan giliran — sekali untuk setiap musuh.")
	await snap("battle_start")

	while not over:
		turn_count += 1
		var order := _compute_order()
		for i in order.size():
			var b: Battler = order[i]
			if over:
				break
			if not b.alive():
				continue
			hud.set_order(order, i)
			if b.is_player:
				await _player_turn()
			else:
				await _enemy_turn(b)
			hud.refresh()
			_check_end()
		_end_of_round()
	await _finish()


func _compute_order() -> Array:
	var all: Array = [mc]
	for e in enemies:
		if (e as Battler).alive():
			all.append(e)
	var keyed: Array = []
	for b in all:
		var bat: Battler = b
		keyed.append([float(bat.spd) + randf_range(0.0, 4.0) + (6.0 if bat.guarding else 0.0), bat])
	keyed.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) > float(y[0]))
	var out: Array = []
	for k in keyed:
		out.append(k[1])
	return out


func _alive_enemies() -> Array:
	var out: Array = []
	for e in enemies:
		if (e as Battler).alive():
			out.append(e)
	return out


func _all_broken() -> bool:
	var alive := _alive_enemies()
	if alive.is_empty():
		return false
	for e in alive:
		if not (e as Battler).is_broken():
			return false
	return true


# ---------------------------------------------------------------------------
# Player
# ---------------------------------------------------------------------------
func _player_turn() -> void:
	mc.guarding = false
	if not mc.boosted_last:
		mc.bp = mini(mc.bp + 1, 5)
	mc.boosted_last = false
	hud.refresh()
	if bool(config.get("tutorial", false)) and mc.bp >= 2 and not _tips.has("boost"):
		_tips["boost"] = true
		await hud.tutorial("BOOST",
			"Setiap giliran kamu mendapat [b]1 BP[/b] (maks. 5). Tekan [b]KANAN/KIRI[/b] di menu untuk memakai " +
			"hingga 3 BP sekaligus: SERANG & Lempar Batu memukul lebih banyak kali, keahlian lain jadi lebih kuat.\n" +
			"Setelah BOOST, kamu tidak mendapat BP pada giliran berikutnya.")
	if _all_broken() and not _tips.has("allout") and bool(config.get("tutorial", false)):
		_tips["allout"] = true
		await hud.tutorial("HABISI!",
			"Semua musuh dalam keadaan [b]BREAK[/b]! Perintah [b]HABISI![/b] muncul di menu: serangan penghabisan " +
			"yang menghantam semua musuh dengan kekuatan dahsyat.")
	while true:
		var cmd: Dictionary = await hud.choose_command(mc, enemies, {"allout": _all_broken(),
			"can_flee": bool(config.get("can_flee", false))})
		var action := str(cmd.get("action", "guard"))
		if action == "observe":
			var target: Battler = cmd["target"]
			await _observe(target)
			hud.refresh()
			continue  # observing is free
		var boost := int(cmd.get("boost", 0)) if action == "skill" else 0
		if boost > 0:
			boost = mini(boost, mc.bp)
			mc.bp -= boost
			mc.boosted_last = true
			Audio.sfx("boost", 0.0)
			hud.popup(mc.home + Vector2(0, -50), "BOOST x%d" % boost, UIKit.GOLD, 34)
		match action:
			"skill":
				await _use_skill(mc, str(cmd["id"]), cmd["target"], boost)
			"guard":
				mc.guarding = true
				Audio.sfx("guard", -2.0)
				hud.show_banner("%s · BERTAHAN" % mc.display_name.to_upper())
				hud.popup(mc.home + Vector2(0, -50), "BERTAHAN", Color("8ab4ff"), 34)
				mc.set_state("guard")
				await wait(0.5)
				mc.set_state("idle")
				hud.hide_banner()
			"item":
				await _use_item(str(cmd["id"]))
			"allout":
				await _all_out()
			"flee":
				hud.show_banner("KABUR!")
				Audio.sfx("swoosh_big", -2.0)
				await mc.lunge(mc.home + Vector2(140, 0))
				fled = true
				over = true
		break


func _observe(target: Battler) -> void:
	hud.show_banner("%s · AMATI" % mc.display_name.to_upper(), Color("1e2a50"))
	mc.set_state("cast")
	Audio.sfx("pickup", -2.0, 0.8)
	post.flash(Color(0.6, 0.9, 1.0), 0.3, 0.25)
	await wait(0.4)
	target.observed = true
	for w in target.weak:
		target.revealed[str(w)] = true
	mc.set_state("idle")
	hud.refresh()
	var weak_names: Array = []
	for w in target.weak:
		weak_names.append(BattleData.element_name(str(w)))
	hud.hide_banner()
	await say("mc", "%s. %s" % [target.display_name, str(target.data.get("desc", ""))], "smirk")
	await say("mc", "Kelemahan: %s. HP: %d/%d. Catat." % [", ".join(weak_names), target.hp, target.max_hp], "neutral")
	await close_dialogue()
	if bool(config.get("tutorial", false)) and not _tips.has("shield"):
		_tips["shield"] = true
		await hud.tutorial("PERISAI & BREAK",
			"Angka di ikon perisai adalah [b]Perisai[/b] musuh. Setiap pukulan yang mengenai [b]kelemahan[/b] " +
			"mengurangi 1 poin. Saat perisai habis, musuh [b]BREAK[/b]: kehilangan giliran dan menerima damage 2x.")


func _use_skill(user: Battler, sid: String, target_v: Variant, boost: int) -> void:
	var sk: Dictionary = BattleData.SKILLS[sid]
	var cost := int(sk["sp"])
	user.sp = maxi(0, user.sp - cost)
	hud.refresh()
	hud.show_banner("%s · %s" % [user.display_name.to_upper(), str(sk["name"]).to_upper()])
	var kind := str(sk["type"])
	if kind == "heal":
		await user.cast()
		var amount := int(round(float(user.max_hp) * float(sk["power"]) * (1.0 + 0.5 * float(boost))))
		user.hp = mini(user.max_hp, user.hp + amount)
		Audio.sfx("heal")
		spawn_fx(FX.burst(Color(0.5, 1.0, 0.6), 24, 60.0, 0.8, -40.0), user.home + Vector2(0, -20))
		hud.popup(user.home + Vector2(0, -40), "+%d" % amount, Color("7af08a"))
		user.set_state("idle")
		hud.hide_banner()
		hud.refresh()
		return
	var target: Battler = target_v
	if not target.alive():
		var alive := _alive_enemies()
		if alive.is_empty():
			hud.hide_banner()
			return
		target = alive[0]
	var multi := bool(sk.get("multi", false))
	var hits := 1 + boost if multi else 1
	var power := float(sk["power"]) * (1.0 if multi else 1.0 + 0.5 * float(boost))
	var stat := float(user.mag) if str(sk.get("stat", "atk")) == "mag" else user.effective_atk()
	if kind == "fire" or kind == "holy":
		await user.cast()
	else:
		await user.lunge(target.home)
	for _h in hits:
		if not target.alive():
			break
		await _hit(user, target, stat, power, kind)
		await wait(0.12)
	await user.return_home()
	hud.hide_banner()


func _hit(user: Battler, target: Battler, stat: float, power: float, kind: String) -> void:
	var weak_hit := target.weak.has(kind)
	var dmg := stat * power * randf_range(0.92, 1.08) - float(target.def) * 0.6
	var crit := randf() < 0.06
	if weak_hit:
		dmg *= 1.4
	if target.is_broken():
		dmg *= 2.0
	if crit:
		dmg *= 1.5
	if target.guarding:
		dmg *= 0.4
	var amount := maxi(1, int(round(dmg)))
	target.hp = maxi(0, target.hp - amount)
	var sfx := "hit_blunt"
	if BattleData.ELEMENTS.has(kind):
		sfx = str(BattleData.ELEMENTS[kind]["sfx"])
	Audio.sfx(sfx, -2.0, randf_range(0.95, 1.08))
	var color := Color(1.0, 0.85, 0.5) if kind == "fire" else (Color(1.0, 1.0, 0.8) if kind == "holy" else Color.WHITE)
	spawn_fx(FX.burst(color, 14, 90.0, 0.4), target.home + Vector2(0, -22))
	shake(0.35 if (weak_hit or crit) else 0.18, 5.0)
	target.hurt()
	if user.is_player and not target.is_player:
		var tutorial := bool(config.get("tutorial", false))
		if weak_hit:
			target.revealed[kind] = true
			hud.popup(target.home + Vector2(0, -64), "WEAK!", UIKit.RED, 40, UIKit.BONE)
			Audio.sfx("weak", -4.0)
			if not target.is_broken() and target.shield > 0:
				target.shield -= 1
				if target.shield <= 0:
					await _break(target)
		if tutorial and weak_hit and not _tips.has("weak_hit"):
			_tips["weak_hit"] = true
	if crit:
		hud.popup(target.home + Vector2(0, -80), "KRITIS!", UIKit.GOLD, 36)
	hud.popup(target.home + Vector2(0, -40), str(amount), UIKit.BONE if not weak_hit else Color(1.0, 0.85, 0.3), 50)
	hud.refresh()
	if not target.alive():
		if target.is_player:
			target.set_state("down")
		else:
			Audio.sfx("break", -6.0, 1.3)
			await target.die()


func _break(target: Battler) -> void:
	target.broken_turns = 2
	target.charging = {}
	Audio.sfx("break", 0.0)
	post.flash(Color.WHITE, 0.3, 0.6)
	shake(0.7, 8.0)
	spawn_fx(FX.burst(Color(0.6, 0.8, 1.0), 40, 160.0, 0.8), target.home + Vector2(0, -24))
	hud.refresh()
	await cine.banner("BREAK!", UIKit.RED, 0.4, 120)
	if bool(config.get("tutorial", false)) and not _tips.has("break"):
		_tips["break"] = true
		await hud.tutorial("BREAK!",
			"Musuh terguncang: ia [b]kehilangan giliran[/b] ronde ini dan ronde berikutnya, dan menerima " +
			"[b]damage 2x[/b]. Saatnya BOOST dan hantam sekuatnya!")


func _use_item(iid: String) -> void:
	var it: Dictionary = BattleData.ITEMS[iid]
	if not GameState.remove_item(iid):
		return
	hud.show_banner("%s · %s" % [mc.display_name.to_upper(), str(it["name"]).to_upper()])
	await mc.cast()
	var hp_gain := int(it.get("hp", 0))
	var sp_gain := int(it.get("sp", 0))
	mc.hp = mini(mc.max_hp, mc.hp + hp_gain)
	mc.sp = mini(mc.max_sp, mc.sp + sp_gain)
	Audio.sfx("heal")
	spawn_fx(FX.burst(Color(0.5, 1.0, 0.6), 20, 60.0, 0.8, -40.0), mc.home + Vector2(0, -20))
	if hp_gain > 0:
		hud.popup(mc.home + Vector2(0, -40), "+%d HP" % hp_gain, Color("7af08a"), 38)
	if sp_gain > 0:
		hud.popup(mc.home + Vector2(0, -70), "+%d SP" % sp_gain, Color("6ab8ff"), 32)
	mc.set_state("idle")
	hud.hide_banner()
	hud.refresh()


func _all_out() -> void:
	hud.hide_banner()
	await hud.all_out(UIKit.tex("res://assets/sprites/portraits/mc_angry.png"))
	for e in _alive_enemies():
		var b: Battler = e
		var dmg := int(round(float(b.max_hp) * 0.3 + mc.effective_atk() * 2.2))
		b.hp = maxi(0, b.hp - dmg)
		spawn_fx(FX.burst(Color(1.0, 0.4, 0.4), 50, 180.0, 0.9), b.home + Vector2(0, -24))
		hud.popup(b.home + Vector2(0, -40), str(dmg), UIKit.RED, 70, UIKit.BONE)
		shake(1.0, 10.0)
		b.hurt()
		if not b.alive():
			Audio.sfx("break", -4.0, 1.2)
			await b.die()
	await wait(0.6)
	hud.refresh()


# ---------------------------------------------------------------------------
# Enemies
# ---------------------------------------------------------------------------
func _enemy_turn(e: Battler) -> void:
	if e.is_broken():
		hud.popup(e.home + Vector2(0, -60), "TERGUNCANG", Color("8ab4ff"), 30)
		await wait(0.5)
		return
	var move: Dictionary
	if not e.charging.is_empty():
		move = e.charging
		e.charging = {}
	else:
		move = _pick_move(e)
		if move.has("telegraph"):
			e.charging = move
			e.set_state("charge")
			hud.show_banner(str(move["telegraph"]), UIKit.RED_DARK)
			Audio.sfx("growl", -2.0)
			spawn_fx(FX.burst(Color(1.0, 0.85, 0.4), 20, 40.0, 0.8, -60.0), e.home + Vector2(0, -20))
			hud.refresh()
			await wait(1.2)
			hud.hide_banner()
			if bool(config.get("tutorial", false)) and not _tips.has("telegraph"):
				_tips["telegraph"] = true
				await hud.tutorial("SERANGAN BERBAHAYA",
					"Musuh sedang bersiap melancarkan serangan kuat pada giliran berikutnya. [b]BERTAHAN[/b] " +
					"mengurangi damage 60% — atau buat ia [b]BREAK[/b] agar serangannya batal!")
			e.set_state("idle")
			return
	hud.show_banner("%s · %s" % [e.display_name.to_upper(), str(move["name"]).to_upper()], UIKit.RED_DARK)
	if move.has("buff"):
		e.atk_buff = float(move["buff"])
		e.buff_turns = 3
		e.set_state("charge")
		Audio.sfx("growl", 0.0, 1.2)
		hud.popup(e.home + Vector2(0, -60), "SERANGAN NAIK", UIKit.GOLD, 32)
		await wait(0.8)
		e.set_state("idle")
		hud.hide_banner()
		return
	await e.lunge(mc.home)
	var hits := int(move.get("hits", 1))
	for _h in hits:
		if not mc.alive():
			break
		await _hit(e, mc, e.effective_atk(), float(move.get("power", 1.0)), str(move.get("type", "blunt")))
		await wait(0.12)
	await e.return_home()
	hud.hide_banner()


func _pick_move(e: Battler) -> Dictionary:
	var moves: Array = e.data["moves"]
	var total := 0
	for m in moves:
		var md: Dictionary = m
		if md.has("buff") and e.buff_turns > 0:
			continue
		total += int(md.get("weight", 1))
	var roll := randi_range(1, maxi(total, 1))
	for m in moves:
		var md: Dictionary = m
		if md.has("buff") and e.buff_turns > 0:
			continue
		roll -= int(md.get("weight", 1))
		if roll <= 0:
			return md
	return moves[0]


func _end_of_round() -> void:
	for e in enemies:
		var b: Battler = e
		if b.buff_turns > 0:
			b.buff_turns -= 1
			if b.buff_turns == 0:
				b.atk_buff = 0.0
		if b.broken_turns > 0:
			b.broken_turns -= 1
			if b.broken_turns == 0 and b.alive():
				b.shield = b.max_shield
				hud.popup(b.home + Vector2(0, -60), "PULIH", Color("8ab4ff"), 30)
	hud.refresh()


func _check_end() -> void:
	if not mc.alive():
		over = true
		won = false
	elif _alive_enemies().is_empty():
		over = true
		won = true


func _finish() -> void:
	hud.hide_banner()
	GameState.mc["hp"] = maxi(1, mc.hp)
	GameState.mc["sp"] = mc.sp
	if fled:
		await wait(0.4)
		_return_to(str(config.get("flee_to", config.get("next", "res://scenes/ui/title.tscn"))))
		return
	if won:
		Audio.play_jingle("victory")
		var exp_total := 0
		var drops: Array = []
		for e in enemies:
			var b: Battler = e
			exp_total += int(b.data.get("exp", 0))
			if b.data.has("drop"):
				drops.append(str(b.data["drop"]))
		var lines: Array = ["EXP  +%d" % exp_total]
		for msg in GameState.gain_exp(exp_total):
			lines.append(str(msg).to_upper())
			Audio.sfx("heal", -2.0)
		for d in drops:
			GameState.add_item(d)
			lines.append("DIDAPAT: %s" % str(BattleData.ITEMS[d]["name"]).to_upper())
		if config.has("win_flag"):
			GameState.set_flag(str(config["win_flag"]))
		await snap("battle_victory")
		await hud.victory(lines)
		_return_to(str(config.get("next", "res://scenes/ui/title.tscn")))
	else:
		Audio.play_jingle("gameover")
		mc.set_state("down")
		await wait(1.0)
		var pick := await hud.defeat()
		if pick == 0:
			GameState.mc = _snapshot_mc.duplicate(true)
			GameState.inventory = _snapshot_inv.duplicate(true)
			GameState.battle_config = config
			Router.goto("res://scenes/battle/battle.tscn")
		else:
			Router.goto("res://scenes/ui/title.tscn")


func _return_to(path: String) -> void:
	GameState.battle_config = {}
	Router.goto(path)
