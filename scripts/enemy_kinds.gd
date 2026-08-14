class_name EnemyKinds
extends RefCounted
## The list of enemy KINDS (STO-ENEMIES-017) — the same idea as
## CharacterDB is for players.
##
## enemy.gd used to hard-code one creature: 60 health, speed 3, a
## humanoid body. A second kind would have meant `if` statements
## threaded through the AI and a third would have made that
## unreadable. A list makes each new enemy an ENTRY rather than an
## edit.
##
## `body` says which shape to build, not how to think — every kind
## shares the same brain, ragdolls the same way, loses limbs the same
## way and leaves a body the same way.

const LIST: Array = [
	{
		"id": "walker",
		"name": "Walker",
		"body": "humanoid",
		"health": 60.0,
		"speed": 3.0,
		"damage": 12.0,
		"colour": Color(0.8, 0.2, 0.2),
	},
	{
		"id": "crawler",
		"name": "Crawler",
		"body": "quadruped",      # four legs, a block for a body
		"health": 45.0,
		"speed": 4.2,             # scuttles - quicker than the Walker
		"damage": 9.0,
		"colour": Color(0.35, 0.55, 0.30),
	},
]


static func count() -> int:
	return LIST.size()


static func get_def(index: int) -> Dictionary:
	return LIST[clampi(index, 0, LIST.size() - 1)]


## Look a kind up by its id; -1 if there is no such kind.
static func index_of(id: String) -> int:
	for i in LIST.size():
		if String(LIST[i]["id"]) == id:
			return i
	return -1
