extends SceneTree
## Smoke test for STO-ENEMIES-039 — floppiness you can actually SEE.
##   godot --headless -s res://tests/smoke_walk_flop.gd
##
## There is exactly one rule in this file: the spider is provoked ONLY
## by letting it walk. No shove appears anywhere.
##
## That rule exists because STO-ENEMIES-037 shipped a mechanism its own
## tests called working while the operator looked at it and said it
## "isn\'t flopy in any way". Both were right. Those tests provoked the
## creature at 14 m/s — nine times its walking speed of 1.6, and
## something the game never does. Measured while merely walking, the
## floppiness was 1.4 degrees decaying to zero.
##
## A test that hits something nine times harder than the game ever will
## is not testing the game.

const EnemyKinds := preload("res://scripts/enemy_kinds.gd")

var _ticks := 0
var _main: Node
var _spider: CharacterBody3D
var _body: Node3D
var _peak := 0.0
var _peak_walk := 0.0
var _phase_done := false
var _settle_ticks := 0
var _failures := 0


func _physics_process(_d: float) -> bool:
	_ticks += 1
	if _ticks == 1:
		_main = load("res://scenes/main.tscn").instantiate()
		root.add_child(_main)
		return false
	if _ticks == 3:
		var e: CharacterBody3D = load("res://scenes/enemy.tscn").instantiate()
		e.name = "S1"
		e.set("kind", EnemyKinds.index_of("crawler"))
		_main.get_node("Enemies").add_child(e)
		e.global_position = Vector3(0.0, 1.0, 30.0)
		_spider = e
		# A player well away, so the spider walks a long steady line
		# toward it exactly as it would in play.
		var pl: CharacterBody3D = load("res://scenes/player.tscn").instantiate()
		pl.name = "1"
		_main.get_node("Players").add_child(pl)
		pl.global_position = Vector3(0.0, 1.0, 10.0)
		return false
	if _ticks < 10:
		return false

	_body = _spider.get_node_or_null("Body")
	if _body == null:
		quit(1)
		return true

	var f: float = float(_body.call("gait_lag"))
	var spd: float = _spider.velocity.length()
	_peak = maxf(_peak, f)
	if spd > 1.0:
		_peak_walk = maxf(_peak_walk, f)
	if _ticks % 40 == 0:
		print("  t=%d speed=%.2f gait_lag=%.4f rad (%.1f deg)"
				% [_ticks, spd, f, rad_to_deg(f)])
	if _phase_done:
		# Standing still now: the springs have to come to rest.
		#
		# The trail is wiped EVERY tick, not once. queue_free() is
		# deferred, so a player freed this frame is still a body the
		# spider's radar can feel on the next one — and one sweep is
		# enough to restore the memory and send it walking again, which
		# read here as "the idle never settles".
		var m = _spider.call("mind")
		if m != null:
			m.call("trail_cold")
		_settle_ticks += 1
		if _settle_ticks < 150:
			return false
		var rest: float = float(_body.call("gait_lag"))
		print("[WALK] standing still, lag settles to %.4f rad (%.1f deg)"
				% [rest, rad_to_deg(rest)])
		_check(rad_to_deg(rest) < 5.0,
				"a standing spider settles (%.1f deg)" % rad_to_deg(rest))
		print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
		quit(1 if _failures > 0 else 0)
		return true
	if _ticks < 420:
		return false

	print("")
	print("[WALK] peak lag while walking: %.4f rad (%.1f deg) at %.2f m/s"
			% [_peak_walk, rad_to_deg(_peak_walk), _spider.velocity.length()])
	# The number that matters. 1.4 degrees was the old behaviour and was
	# invisible; the floor here is set well above it so a regression to
	# body-driven floppiness cannot pass.
	_check(rad_to_deg(_peak_walk) > 10.0,
			"a spider that merely WALKS visibly flops (%.1f deg)"
			% rad_to_deg(_peak_walk))
	# And it must still be a walk, not a slide.
	_check(_spider.velocity.length() > 1.0,
			"and it is still walking (%.2f m/s)" % _spider.velocity.length())
	# Standing still, the springs must settle -- floppiness must not
	# become a permanent idle wobble.
	_spider.velocity = Vector3.ZERO
	for p in get_nodes_in_group("players"):
		(p as Node).queue_free()
	# Removing everyone no longer stops it. The spider has a MEMORY
	# (STO-ENEMIES-038): lose it and it walks to the last place it knew
	# of rather than freezing, which is the point of that story. Wipe
	# the trail too, or this measures a creature correctly still hunting
	# and calls its gait an idle wobble.
	var mind = _spider.call("mind")
	if mind != null:
		mind.call("trail_cold")
	_phase_done = true
	return false


func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: %s" % label)
	else:
		_failures += 1
		print("FAIL: %s" % label)
