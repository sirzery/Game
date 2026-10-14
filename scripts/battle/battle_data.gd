class_name BattleData
extends RefCounted
## Static battle data: elements, skills, items and enemies.
##
## Mechanics overview
## - Shield & BREAK: every hit that strikes a weakness removes one shield
##   point. At zero the enemy BREAKS: it loses its turns this round and the
##   next, and takes double damage.
## - BOOST (BP): the Scholar gains 1 BP per turn (max 5) and may spend up to
##   3 at once. Multi-hit skills hit more times, others hit harder.
## - AMATI (Observe): free once per enemy. Reveals weaknesses, HP and intent.
## - HABISI! (finisher): when every enemy is broken, a devastating combined
##   assault becomes available.

const ELEMENTS := {
	"blunt": {"name": "TUMPUL", "icon": "res://assets/sprites/ui/icon_blunt.png", "sfx": "hit_blunt"},
	"pierce": {"name": "TUSUK", "icon": "res://assets/sprites/ui/icon_pierce.png", "sfx": "hit_pierce"},
	"fire": {"name": "API", "icon": "res://assets/sprites/ui/icon_fire.png", "sfx": "hit_fire"},
	"holy": {"name": "SUCI", "icon": "res://assets/sprites/ui/icon_holy.png", "sfx": "hit_holy"},
	"dark": {"name": "GELAP", "icon": "res://assets/sprites/ui/icon_dark.png", "sfx": "hit_blunt"},
}

const SKILLS := {
	"chain_lash": {
		"name": "Cambuk Rantai", "type": "blunt", "power": 1.0, "sp": 0, "stat": "atk", "multi": true,
		"desc": "Ayunkan rantai yang putus dari pergelanganmu. BOOST: tambah jumlah pukulan.",
	},
	"stone_throw": {
		"name": "Lempar Batu Runcing", "type": "pierce", "power": 0.95, "sp": 3, "stat": "atk", "multi": true,
		"desc": "Batu pipih diasah di tanah, dilempar tepat sasaran. BOOST: tambah lemparan.",
	},
	"torch": {
		"name": "Obor Darurat", "type": "fire", "power": 1.7, "sp": 6, "stat": "mag", "multi": false,
		"desc": "Kain, lemak, dan percikan batu api. Kimia dasar, hasil luar biasa. BOOST: +50% daya/BP.",
	},
	"breath": {
		"name": "Napas Penyintas", "type": "heal", "power": 0.35, "sp": 5, "stat": "mag", "multi": false,
		"desc": "Teknik bernapas dari 114 hari di bawah batu. Pulihkan HP. BOOST: +50% pemulihan/BP.",
	},
}

const MC_SKILLS := ["stone_throw", "torch", "breath"]

const ITEMS := {
	"akar_pahit": {"name": "Akar Pahit", "hp": 45, "sp": 0,
		"desc": "Pulihkan 45 HP. Rasanya seperti penyesalan yang direbus."},
	"lumut_embun": {"name": "Lumut Embun", "hp": 0, "sp": 12,
		"desc": "Pulihkan 12 SP. Dikumpulkan dari batu sungai saat fajar."},
	"roti_maren": {"name": "Roti Maren", "hp": 40, "sp": 8,
		"desc": "Pulihkan 40 HP dan 8 SP. Masih hangat. Sedikit bekas gigitan kambing."},
}

const ENEMIES := {
	"hound": {
		"name": "Anjing Pemburu Sinode", "short": "ANJING", "sheet": "hound", "frame_size": Vector2i(48, 32),
		"frames": {"idle": [0, 1], "attack": 2, "hurt": 3, "charge": 4}, "scale": 1.7,
		"hp": 240, "atk": 16, "def": 6, "mag": 10, "spd": 14, "shield": 4,
		"weak": ["pierce", "fire"], "exp": 70,
		"desc": "Anjing suci bertopeng emas. Dilatih mencium bau 'dosa'—dan, rupanya, bau orang yang 114 hari tidak mandi.",
		"moves": [
			{"id": "bite", "name": "Gigit", "type": "pierce", "power": 1.0, "hits": 1, "weight": 4},
			{"id": "claws", "name": "Cakar Ganda", "type": "blunt", "power": 0.6, "hits": 2, "weight": 3},
			{"id": "howl", "name": "Lolongan Suci", "buff": 0.3, "weight": 2},
			{"id": "pounce", "name": "Terjang Suci", "type": "holy", "power": 2.2, "hits": 1, "weight": 2,
				"telegraph": "Anjing Pemburu merendah... cahaya berkumpul di topengnya!"},
		],
	},
	"boar": {
		"name": "Babi Hutan Berlumut", "short": "BABI HUTAN", "sheet": "boar", "frame_size": Vector2i(48, 32),
		"frames": {"idle": [0, 1], "attack": 2, "hurt": 3, "charge": 0}, "scale": 1.6,
		"hp": 190, "atk": 15, "def": 8, "mag": 6, "spd": 9, "shield": 3,
		"weak": ["blunt", "fire"], "exp": 45, "drop": "lumut_embun",
		"desc": "Babi hutan tua yang punggungnya ditumbuhi lumut dan jamur. Pemarah, tapi jujur.",
		"moves": [
			{"id": "tusk", "name": "Seruduk Taring", "type": "pierce", "power": 1.1, "hits": 1, "weight": 4},
			{"id": "stomp", "name": "Hentak Lumpur", "type": "blunt", "power": 0.8, "hits": 1, "weight": 3},
			{"id": "charge", "name": "Terjangan Membabi Buta", "type": "blunt", "power": 2.0, "hits": 1, "weight": 2,
				"telegraph": "Babi Hutan menggaruk tanah dengan kakinya... ia akan menerjang!"},
		],
	},
}


static func element_name(t: String) -> String:
	if ELEMENTS.has(t):
		return str(ELEMENTS[t]["name"])
	return ""


static func element_icon(t: String) -> String:
	if ELEMENTS.has(t):
		return str(ELEMENTS[t]["icon"])
	return "res://assets/sprites/ui/icon_unknown.png"
