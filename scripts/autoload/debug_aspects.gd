extends Node
## Registers all known debug aspects at startup (STO-TOOLS-002).
## Add new aspects HERE as features gain debug output — this file is
## the one place to see everything inspectable in delve.


func _ready() -> void:
	var r := DebugOverlay.register

	# -- Network --
	r.call("network/peers", "Peer connect/disconnect events")
	r.call("network/spawn", "Player spawn/despawn per peer")

	# -- Player --
	r.call("player/movement", "Owner-side position/velocity (throttled)")
	r.call("player/combat", "Damage taken, death/respawn, combo changes")
	r.call("player/abilities", "Ability activations (zip, throw, pull, guard, roll, fly)")

	# -- Enemy --
	r.call("enemy/ai", "Enemy target acquisition and chase state")
	r.call("enemy/combat", "Enemy damage, death, attacks")

	# -- Performance --
	r.call("perf/fps", "Per-second FPS log line")
