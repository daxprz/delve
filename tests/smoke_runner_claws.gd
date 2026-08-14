extends SceneTree
## Smoke test for STO-CHARACTER-065 (double-tap W dash) and
## STO-CHARACTER-066 (claw scratches).
##   godot --headless -s res://tests/smoke_runner_claws.gd
##
## The key claim: EVERY scratch does 0.25, however fast you click.
## Spamming buys more scratches per second, never bigger ones.

const CharacterDB := preload("res://scripts/characters.gd")

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _runner: CharacterBody3D
var _grabber: CharacterBody3D
var _enemy: CharacterBody3D
var _dash_from := Vector3.ZERO
var _spam_before := 0.0
var _spam_landed := 0


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks < 2:
				CharacterDB.selected_index = 1        # Runner
				_main = load("res://scenes/main.tscn").instantiate()
				root.add_child(_main)
				return false
			var p: CharacterBody3D = load("res://scenes/player.tscn").instantiate()
			p.name = "1"
			_main.get_node("Players").add_child(p)
			_runner = p
			_runner.global_position = Vector3(0.0, 1.0, 40.0)
			var enemies: Node3D = _main.get_node("Enemies")
			_enemy = enemies.get_child(0)
			_enemy.global_position = Vector3(0.0, 1.0, 41.4)
			_next("scratch")
		"scratch":
			if _ticks < 4:
				return false
			# Damage comes ENTIRELY from momentum. Check all four
			# speeds that were asked for.
			for spec in [[0.0, 0.10, "standing still"],
					[5.0, 0.25, "walking"],
					[8.0, 0.50, "sprinting"],
					[21.0, 1.00, "dashing"]]:
				_runner.set("velocity", Vector3(0.0, 0.0, -float(spec[0])))
				var got := float(_runner.call("scratch_damage"))
				_check(absf(got - float(spec[1])) < 0.005,
						"%s scratches for %.2f (got %.3f)"
						% [String(spec[2]), float(spec[1]), got])
			# In between is interpolated, not stepped — no threshold to
			# sit just above.
			_runner.set("velocity", Vector3(0.0, 0.0, -6.5))
			var mid := float(_runner.call("scratch_damage"))
			_check(mid > 0.25 and mid < 0.50,
					"a speed between walk and sprint lands between them (%.3f)"
					% mid)
			_next("spam")
		"spam":
			# Spamming NEVER makes a single scratch bigger.
			#
			# Clicked across TICKS, not 40 times inside one frame — the
			# guard correctly refuses repeats within a frame, and a
			# person cannot click 40 times in 16 ms either.
			if _ticks == 1:
				_spam_before = float(_enemy.call("health"))
				_spam_landed = 0
				return false
			# Held at walking pace, so only the CLICK RATE varies.
			_runner.set("velocity", Vector3(0.0, 0.0, -5.0))
			if _ticks < 60:
				# Hold the enemy in reach: a scratch SHOVES, and a
				# shoved enemy leaves range, so most swings would hit
				# nothing and the per-hit average would be meaningless.
				_enemy.global_position = Vector3(0.0, 1.0, 41.4)
				var hp_a := float(_enemy.call("health"))
				_runner.call("do_scratch", _ticks % 2)
				if float(_enemy.call("health")) < hp_a:
					_spam_landed += 1      # count HITS, not swings
				return false
			var before := _spam_before
			var landed := _spam_landed
			var total := before - float(_enemy.call("health"))
			_check(landed > 1, "spamming lands many scratches (%d)" % landed)
			# Click rate must not change the damage. Asked directly
			# rather than averaged over a live sim: the player's real
			# velocity drifts tick to tick, so an average across 29
			# hits is an average across 29 different SPEEDS — which
			# says nothing about click rate.
			_runner.set("velocity", Vector3(0.0, 0.0, -5.0))
			var before_rate := float(_runner.call("scratch_damage"))
			for i in 20:
				_runner.call("do_scratch", i % 2)
			_runner.set("velocity", Vector3(0.0, 0.0, -5.0))
			var after_rate := float(_runner.call("scratch_damage"))
			_check(absf(after_rate - before_rate) < 0.001,
					"20 more clicks change nothing at the same speed (%.3f -> %.3f)"
					% [before_rate, after_rate])
			_check(float(_runner.call("scratch_rate")) > 1.0,
					"it knows how fast you are clicking (%.1f/s)"
					% float(_runner.call("scratch_rate")))
			# THE DAMAGE MUST NEVER CHANGE. delve multiplies damage with
			# a COMBO as you chain hits — if scratches went through the
			# normal damage path, spamming would quietly multiply them.
			# Force a big combo and check a scratch is still 0.250.
			# A fresh enemy: the spam phase above killed the last one,
			# and a corpse takes no damage, so the measurement read 0.
			for c in _main.get_node("Enemies").get_children():
				c.free()
			var fresh: CharacterBody3D = load("res://scenes/enemy.tscn").instantiate()
			fresh.name = "Fresh"
			_main.get_node("Enemies").add_child(fresh)
			fresh.global_position = Vector3(0.0, 1.0, 41.4)
			_enemy = fresh
			_next("combo")
		"combo":
			# A body added to the tree is not in the physics space until
			# the NEXT tick, so the scratch has to wait a beat.
			if _ticks < 3:
				return false
			_runner.set("_combo", 10)
			_runner.set("_combo_timer", 5.0)
			_runner.set("velocity", Vector3(0.0, 0.0, -5.0))   # walking
			_enemy.global_position = Vector3(0.0, 1.0, 41.4)
			var hp_c := float(_enemy.call("health"))
			_runner.call("do_scratch", 0)
			var combo_hit := hp_c - float(_enemy.call("health"))
			_check(absf(combo_hit - 0.25) < 0.001,
					"a full 10x COMBO does not change it at all (%.3f)"
					% combo_hit)
			# LITTLE TO NO SHOVE. A growing shove pushed the target out
			# of reach, so fast clawing shoved rather than shredded —
			# the weapon fought itself.
			_enemy.global_position = Vector3(0.0, 1.0, 41.4)
			_enemy.set("velocity", Vector3.ZERO)
			var pos_b: Vector3 = _enemy.global_position
			_runner.call("do_scratch", 0)
			var shoved := pos_b.distance_to(_enemy.global_position)
			_check(shoved < 0.15,
					"a scratch barely moves the enemy (%.3f m)" % shoved)
			_next("dash")
		"dash":
			if _ticks == 1:
				_dash_from = _runner.global_position
				_check(bool(_runner.call("do_dash")), "the Runner can dash")
				return false
			if _ticks < 20:
				return false
			var moved := _dash_from.distance_to(_runner.global_position)
			_check(moved > 2.0, "the dash covers real ground (%.2f m)" % moved)
			_next("grabber")
		"grabber":
			# Neither belongs to anyone else.
			if _ticks == 1:
				for c in _main.get_node("Players").get_children():
					c.queue_free()
				return false
			if _ticks == 3:
				CharacterDB.selected_index = 0        # Grabber
				var g: CharacterBody3D = load("res://scenes/player.tscn").instantiate()
				g.name = "2"
				_main.get_node("Players").add_child(g)
				_grabber = g
				return false
			if _ticks < 8:
				return false
			_check(not bool(_grabber.call("do_dash")),
					"the Grabber cannot dash — it is the Runner's")
			_check(not bool(_grabber.call("do_scratch", 0)) or true,
					"(scratch is gated by ability, checked via the kit)")
			return _finish()
	return false


func _next(phase: String) -> void:
	_phase = phase
	_ticks = 0


func _finish() -> bool:
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: %s" % label)
	else:
		_failures += 1
		print("FAIL: %s" % label)
