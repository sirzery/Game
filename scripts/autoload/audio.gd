extends Node
## Music (cross-faded), ambience loops and pooled sound effects.

const BGM_DIR := "res://assets/audio/bgm/"
const AMB_DIR := "res://assets/audio/ambience/"
const SFX_DIR := "res://assets/audio/sfx/"
const SFX_VOICES := 14

var current_music: String = ""
var current_ambience: String = ""

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_active: AudioStreamPlayer
var _amb: AudioStreamPlayer
var _amb2: AudioStreamPlayer
var _sfx: Array[AudioStreamPlayer] = []
var _sfx_next: int = 0
var _cache: Dictionary = {}
var _music_tween: Tween
var _amb_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_ensure_bus("Ambience")
	_music_a = _make_player("Music")
	_music_b = _make_player("Music")
	_music_active = _music_a
	_amb = _make_player("Ambience")
	_amb2 = _make_player("Ambience")
	for i in SFX_VOICES:
		_sfx.append(_make_player("SFX"))
	Settings.changed.connect(apply_volumes)
	apply_volumes()


func _exit_tree() -> void:
	# Release every stream before the engine shuts down so no playback leaks.
	if _music_tween:
		_music_tween.kill()
	if _amb_tween:
		_amb_tween.kill()
	var players: Array[AudioStreamPlayer] = [_music_a, _music_b, _amb, _amb2]
	players.append_array(_sfx)
	for p in players:
		if p:
			p.stop()
			p.stream = null
	_cache.clear()


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")


func _make_player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


func apply_volumes() -> void:
	AudioServer.set_bus_volume_db(0, _db(Settings.master_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), _db(Settings.music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), _db(Settings.sfx_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Ambience"), _db(Settings.sfx_volume * 0.9))


static func _db(v: float) -> float:
	return linear_to_db(maxf(v, 0.0001))


# ---------------------------------------------------------------------------
# Loading
# ---------------------------------------------------------------------------
func _load(dir: String, stream_name: String, looped: bool) -> AudioStream:
	var key := dir + stream_name
	if _cache.has(key):
		return _cache[key]
	var stream: AudioStream = null
	for ext in [".ogg", ".wav"]:
		var path: String = dir + stream_name + ext
		if ResourceLoader.exists(path):
			stream = load(path) as AudioStream
			break
	if stream == null:
		push_warning("Audio tidak ditemukan: %s%s" % [dir, stream_name])
		return null
	if looped:
		if stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		elif stream is AudioStreamWAV:
			var w := stream as AudioStreamWAV
			w.loop_mode = AudioStreamWAV.LOOP_FORWARD
			w.loop_begin = 0
			w.loop_end = int(w.get_length() * w.mix_rate)
	_cache[key] = stream
	return stream


# ---------------------------------------------------------------------------
# Music
# ---------------------------------------------------------------------------
func play_music(track: String, fade: float = 1.2, volume_db: float = 0.0) -> void:
	if track == current_music and _music_active.playing:
		return
	var stream := _load(BGM_DIR, track, true)
	if stream == null:
		return
	current_music = track
	var old := _music_active
	var new_p := _music_b if _music_active == _music_a else _music_a
	_music_active = new_p
	new_p.stream = stream
	new_p.volume_db = -40.0 if fade > 0.0 else volume_db
	new_p.play()
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween().set_parallel(true)
	_music_tween.tween_property(new_p, "volume_db", volume_db, maxf(fade, 0.01))
	if old.playing:
		_music_tween.tween_property(old, "volume_db", -60.0, maxf(fade, 0.05))
		_music_tween.chain().tween_callback(old.stop)


func play_jingle(track: String) -> void:
	stop_music(0.3)
	var stream := _load(BGM_DIR, track, false)
	if stream == null:
		return
	var p := _sfx[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx.size()
	p.bus = "Music"
	p.stream = stream
	p.volume_db = 0.0
	p.pitch_scale = 1.0
	p.play()
	p.finished.connect(func() -> void: p.bus = "SFX", CONNECT_ONE_SHOT)


func stop_music(fade: float = 1.0) -> void:
	current_music = ""
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween().set_parallel(true)
	for p in [_music_a, _music_b]:
		var pl: AudioStreamPlayer = p
		if pl.playing:
			_music_tween.tween_property(pl, "volume_db", -60.0, maxf(fade, 0.05))
	_music_tween.chain().tween_callback(func() -> void:
		_music_a.stop()
		_music_b.stop())


func duck_music(amount_db: float = -10.0, dur: float = 0.4) -> void:
	var t := create_tween()
	t.tween_property(_music_active, "volume_db", amount_db, dur)


func unduck_music(dur: float = 0.6) -> void:
	var t := create_tween()
	t.tween_property(_music_active, "volume_db", 0.0, dur)


# ---------------------------------------------------------------------------
# Ambience (up to two layers, e.g. rain + wind)
# ---------------------------------------------------------------------------
func play_ambience(name_a: String, name_b: String = "", fade: float = 1.5) -> void:
	var key := name_a + "|" + name_b
	if key == current_ambience:
		return
	current_ambience = key
	if _amb_tween:
		_amb_tween.kill()
	_amb_tween = create_tween().set_parallel(true)
	# a callback keeps the tween valid even if no layer needs fading
	_amb_tween.tween_callback(func() -> void: pass)
	for pair in [[_amb, name_a], [_amb2, name_b]]:
		var p: AudioStreamPlayer = pair[0]
		var n: String = pair[1]
		if n == "":
			if p.playing:
				_amb_tween.tween_property(p, "volume_db", -60.0, fade)
				_amb_tween.chain().tween_callback(p.stop)
			continue
		var stream := _load(AMB_DIR, n, true)
		if stream == null:
			continue
		if p.stream != stream or not p.playing:
			p.stream = stream
			p.volume_db = -40.0
			p.play()
		_amb_tween.tween_property(p, "volume_db", -2.0, fade)


func stop_ambience(fade: float = 1.5) -> void:
	current_ambience = ""
	if _amb_tween:
		_amb_tween.kill()
	_amb_tween = create_tween().set_parallel(true)
	for p in [_amb, _amb2]:
		var pl: AudioStreamPlayer = p
		if pl.playing:
			_amb_tween.tween_property(pl, "volume_db", -60.0, fade)
	_amb_tween.chain().tween_callback(func() -> void:
		_amb.stop()
		_amb2.stop())


# ---------------------------------------------------------------------------
# Sound effects
# ---------------------------------------------------------------------------
func sfx(sfx_name: String, volume_db: float = 0.0, pitch: float = 1.0, pitch_jitter: float = 0.0) -> void:
	var stream := _load(SFX_DIR, sfx_name, false)
	if stream == null:
		return
	var p := _sfx[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx.size()
	if p.bus != "SFX":
		p.bus = "SFX"
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = maxf(0.05, pitch + randf_range(-pitch_jitter, pitch_jitter))
	p.play()
