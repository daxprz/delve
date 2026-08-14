extends RefCounted
## Character registry (STO-CHARACTER-004). The list of playable
## characters as data, so we can add more without touching the player
## controller. Preload this script and call the static helpers, e.g.
##   const CharacterDB := preload("res://scripts/characters.gd")
##   var def := CharacterDB.get_def(CharacterDB.selected_index)
##
## Each def is a Dictionary:
##   id          : String  — stable id
##   name        : String  — shown on the select screen
##   color       : Color   — the character's accent colour
##   speed       : float   — walk speed (m/s)
##   jump        : float   — jump velocity
##   arms        : bool    — has the mechanical grabber arms
##   double_jump : bool    — can jump a second time in the air

## The character the local player will spawn as. The select screen sets
## this; the player reads it in _ready (for its own authoritative body).
static var selected_index := 0

static var LIST := [
	{
		"id": "grabber", "name": "Grabber",
		"color": Color(0.85, 0.55, 0.3),
		"speed": 5.0, "sprint": 5.0, "jump": 4.5, "health": 140.0,
		"arms": true, "double_jump": false, "wall_jump": false,
		"wall_climb": false, "tail": false, "humanoid": true,
		"abilities": ["zip", "throw", "piston", "block"],
	},
	{
		"id": "runner", "name": "Runner",
		"color": Color(0.3, 0.6, 0.9),
		"speed": 5.0, "sprint": 8.0, "jump": 5.5, "health": 80.0,
		"arms": false, "double_jump": false, "wall_jump": true,
		"wall_climb": false, "tail": true, "humanoid": true,
		"pounce": true,
		"abilities": ["dodge", "dash", "scratch"],
	},
	{
		"id": "flyer", "name": "Flyer",
		"color": Color(0.6, 0.42, 0.72),
		"speed": 5.0, "sprint": 5.0, "jump": 5.0, "health": 80.0,
		"arms": false, "double_jump": false, "wall_jump": false,
		"wall_climb": false, "tail": false, "humanoid": true,
		"fly": true, "wings": true, "carry": true,
	},
	# --- Roster addition (EPI-CHARACTER-NEW-CHARACTERS). The Guardian
	# and Builder were removed on 2026-08-07 at the operator's request;
	# only the Sniper remains.
	{
		"id": "sniper", "name": "Sniper",
		"color": Color(0.8, 0.8, 0.35),
		"speed": 5.0, "sprint": 6.5, "jump": 4.8, "health": 65.0,
		"arms": false, "double_jump": false, "wall_jump": false,
		"wall_climb": false, "tail": false, "humanoid": true,
		"ears": true,          # STO-CHARACTER-038
		"blind": true,         # STO-CHARACTER-040: sees by echo only
		"gun": true,           # STO-CHARACTER-047: the rifle
		"abilities": [],
	},
]


static func count() -> int:
	return LIST.size()


static func get_def(i: int) -> Dictionary:
	return LIST[clampi(i, 0, LIST.size() - 1)]
