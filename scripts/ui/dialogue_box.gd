class_name DialogueBox
extends CanvasLayer
## Persona-inspired dialogue window.
##
## await dialogue.say("mc", "Teks...", "angry")
## await dialogue.think("Pikiran sang cendekia...")
## await dialogue.narrate("Narasi.")
## var i: int = await dialogue.choose(["Ya", "Tidak"])
## await dialogue.close()

const PORTRAIT_DIR := "res://assets/sprites/portraits/"

## id -> [display name, portrait id ("" = none), side ("left"/"right")]
const SPEAKERS := {
	"mc": ["{name}", "mc", "left"],
	"arbiter": ["Arbiter Agung Malachar", "arbiter", "right"],
	"council1": ["Lidah Pertama", "council", "right"],
	"council2": ["Lidah Kedua", "council", "right"],
	"council3": ["Lidah Ketiga", "council", "right"],
	"council4": ["Lidah Keempat", "council", "right"],
	"council5": ["Lidah Kelima", "council", "right"],
	"saint": ["Santa Ilvaine", "saint", "right"],
	"exiled": ["Yang Terbuang", "exiled", "right"],
	"maren": ["Maren", "maren", "right"],
	"girl": ["Gadis Berlentera", "maren", "right"],
	"guard": ["Penjaga Sinode", "guard", "right"],
	"hunter": ["Corvin", "hunter", "right"],
	"crow": ["Gagak", "", "right"],
	"goat": ["Pangeran", "", "right"],
	"narrator": ["", "", "left"],
}

var root: Control
var box: DialogueFrame
var text: RichTextLabel
var name_tag: NameTag
var portrait: TextureRect
var backdrop: PortraitBackdrop
var indicator: Control
var choice_root: Control

var is_open: bool = false
var _speaker: String = ""
var _side: String = "left"
var _clicked: bool = false
var _indicator_t: float = 0.0


func _init() -> void:
	layer = 80


func _ready() -> void:
	root = UIKit.full_rect(Control.new())
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	backdrop = PortraitBackdrop.new()
	backdrop.position = Vector2(0, 150)
	backdrop.size = Vector2(460, 420)
	root.add_child(backdrop)

	portrait = TextureRect.new()
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size = Vector2(340, 340)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(portrait)

	box = DialogueFrame.new()
	box.position = Vector2(0, 0)
	box.size = Vector2(1280, 720)
	root.add_child(box)

	name_tag = NameTag.new()
	name_tag.position = Vector2(96, 452)
	root.add_child(name_tag)

	text = RichTextLabel.new()
	text.bbcode_enabled = true
	text.scroll_active = false
	text.fit_content = false
	text.position = Vector2(120, 538)
	text.size = Vector2(1040, 140)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_theme_font_override("normal_font", UIKit.body_font(500))
	text.add_theme_font_override("italics_font", UIKit.body_font(400))
	text.add_theme_font_override("bold_font", UIKit.body_font(800))
	text.add_theme_font_size_override("normal_font_size", 27)
	text.add_theme_font_size_override("italics_font_size", 27)
	text.add_theme_font_size_override("bold_font_size", 27)
	text.add_theme_color_override("default_color", UIKit.BONE)
	text.add_theme_constant_override("line_separation", 6)
	root.add_child(text)

	indicator = DialogueIndicator.new()
	indicator.position = Vector2(1168, 652)
	root.add_child(indicator)

	choice_root = Control.new()
	choice_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(choice_root)
	root.add_child(choice_root)

	root.visible = false


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_clicked = true


func _process(delta: float) -> void:
	_indicator_t += delta
	if indicator.visible:
		indicator.position.y = 652.0 + sin(_indicator_t * 6.0) * 5.0


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------
func say(speaker: String, line: String, expr: String = "neutral", opts: Dictionary = {}) -> void:
	var info: Array = SPEAKERS.get(speaker, [speaker, "", "right"])
	var display_name := GameState.fmt(str(opts.get("name", info[0])))
	var pid := str(info[1])
	var side := str(opts.get("side", info[2]))
	var body := GameState.fmt(line)
	if speaker == "exiled":
		body = "[color=#7af0ff][shake rate=18 level=6]%s[/shake][/color]" % body
	elif bool(opts.get("shout", false)):
		body = "[b][shake rate=24 level=8]%s[/shake][/b]" % body
	await _show_line(speaker, display_name, pid, expr, side, body, false)


func think(line: String, expr: String = "neutral") -> void:
	## The Scholar's inner voice.
	var body := "[i][color=#a8b8d8](%s)[/color][/i]" % GameState.fmt(line)
	await _show_line("mc", GameState.player_name, "mc", expr, "left", body, true)


func narrate(line: String) -> void:
	var body := "[center][i][color=#d8cfc0]%s[/color][/i][/center]" % GameState.fmt(line)
	await _show_line("narrator", "", "", "", "left", body, false)


func choose(options: Array, prompt: String = "") -> int:
	if not is_open:
		await _open()
	if prompt != "":
		text.text = GameState.fmt(prompt)
		text.visible_characters = -1
	var menu := ChoiceList.new(options)
	choice_root.add_child(menu)
	var idx: int = await menu.run()
	menu.queue_free()
	return idx


func close() -> void:
	if not is_open:
		return
	is_open = false
	var t := create_tween().set_parallel(true)
	t.tween_property(root, "modulate:a", 0.0, 0.18)
	t.tween_property(portrait, "position:x", portrait.position.x + (-120.0 if _side == "left" else 120.0), 0.18)
	await t.finished
	root.visible = false
	_speaker = ""


# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------
func _open() -> void:
	is_open = true
	root.visible = true
	root.modulate.a = 0.0
	box.pop = 0.0
	var t := create_tween().set_parallel(true)
	t.tween_property(root, "modulate:a", 1.0, 0.15)
	t.tween_property(box, "pop", 1.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t.finished


func _show_line(speaker: String, display_name: String, pid: String, expr: String, side: String,
		body: String, inner: bool) -> void:
	if not is_open:
		await _open()
	_set_speaker(speaker, display_name, pid, expr, side, inner)
	text.text = body
	text.visible_characters = 0
	indicator.visible = false
	var plain := text.get_parsed_text()
	var total := text.get_total_character_count()
	var shown := 0.0
	var pause := 0.0
	var last_blip := -1
	_clicked = false
	while shown < float(total):
		await get_tree().process_frame
		var dt := get_process_delta_time()
		if _advance_pressed() or Input.is_action_pressed("skip") or Settings.autotest:
			shown = float(total)
			break
		if pause > 0.0:
			pause -= dt
			continue
		shown += Settings.text_speed * dt
		var idx := mini(int(shown), total)
		text.visible_characters = idx
		if idx > 0 and idx <= plain.length():
			var ch := plain[idx - 1]
			if ch in ".!?":
				pause = 0.22
			elif ch in ",;:":
				pause = 0.08
		if idx != last_blip and idx % 3 == 0 and speaker != "narrator":
			last_blip = idx
			Audio.sfx("text_blip", -14.0, 1.0 if speaker != "exiled" else 0.6, 0.05)
	text.visible_characters = -1
	indicator.visible = true
	var waited := 0.0
	while true:
		await get_tree().process_frame
		waited += get_process_delta_time()
		if _advance_pressed():
			break
		if Input.is_action_pressed("skip") and waited > 0.06:
			break
		if Settings.autotest and waited > 0.12:
			break
	indicator.visible = false


func _advance_pressed() -> bool:
	if _clicked:
		_clicked = false
		return true
	return Input.is_action_just_pressed("accept")


func _set_speaker(speaker: String, display_name: String, pid: String, expr: String, side: String,
		inner: bool) -> void:
	var color: Color = UIKit.SPEAKER_COLORS.get(pid if pid != "" else speaker, UIKit.SPEAKER_COLORS["narrator"])
	box.inner = inner
	box.narration = speaker == "narrator"
	box.queue_redraw()
	name_tag.visible = display_name != ""
	name_tag.set_text(display_name, color)
	name_tag.position = Vector2(96, 452) if side == "left" else Vector2(820, 452)
	if pid == "":
		portrait.visible = false
		backdrop.visible = false
		_speaker = speaker
		_side = side
		return
	var tex := _portrait_texture(pid, expr)
	var same := speaker == _speaker and side == _side and portrait.visible
	portrait.texture = tex
	portrait.visible = tex != null
	backdrop.visible = tex != null
	backdrop.set_color(color)
	backdrop.flip = side == "right"
	var px := 60.0 if side == "left" else 880.0
	backdrop.position = Vector2(0.0 if side == "left" else 820.0, 150.0)
	portrait.flip_h = side == "right"
	if inner:
		portrait.modulate = Color(0.75, 0.8, 0.95, 0.9)
	else:
		portrait.modulate = Color.WHITE
	if same:
		portrait.position = Vector2(px, 188)
		var t := create_tween()
		portrait.scale = Vector2(1.03, 1.03)
		t.tween_property(portrait, "scale", Vector2.ONE, 0.12)
	else:
		portrait.scale = Vector2.ONE
		portrait.position = Vector2(px + (-160.0 if side == "left" else 160.0), 188)
		var t2 := create_tween()
		t2.tween_property(portrait, "position:x", px, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		backdrop.pop()
	_speaker = speaker
	_side = side


func _portrait_texture(pid: String, expr: String) -> Texture2D:
	var path := "%s%s_%s.png" % [PORTRAIT_DIR, pid, expr]
	if not ResourceLoader.exists(path):
		path = "%s%s_neutral.png" % [PORTRAIT_DIR, pid]
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
