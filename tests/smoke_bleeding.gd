extends SceneTree
## Smoke test for STO-ENEMIES-050 — bleeding out, and the timing game.
##   godot --headless -s res://tests/smoke_bleeding.gd
##
## The story asks for one thing specifically: a perfect player lasts
## NOTICEABLY longer than one doing nothing, and a thrashing player dies
## NOTICEABLY sooner. So the test runs all three and prints the three
## survival times, rather than asserting a rate somewhere and hoping it
## adds up.
##
## Survival time is the honest measure here. A check on bleed_rate()
## alone would pass even if the rate were never actually subtracted from
## anybody's health — which is the shape of bug this project has been
## bitten by twice (a function working is not the thing working).
##
## Runs on the bare player script rather than the whole game: this is a
## test of a RULE, and a rule that needs a spider standing next to it to
## be true is not a rule.

## Loaded at RUNTIME, not as a `const preload`. A const preload is
## resolved while this test script is being parsed — which is BEFORE the
## autoloads exist, so player.gd fails to compile on DebugOverlay and the
## scene comes back with no script attached at all. Every has_method()
## check then fails against a bare CharacterBody3D, which looks exactly
## like the feature not being built.
const PLAYER_SCENE := "res://scenes/player.tscn"
const SPIKE_SCRIPT := "res://scripts/spike.gd"

## Health each victim starts the run on. See the note in "pin".
const TEST_HEALTH := 12.0

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _spike: Node3D
var _who: Array = []           # the three players
var _dead_at := {}             # name -> seconds survived
var _did := {}           # name -> how many times the TEST made it struggle


func _physics_process(delta: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks == 1:
				_spike = (load(SPIKE_SCRIPT) as GDScript).new()
				_spike.name = "TestSpike"
				root.add_child(_spike)
				_spike.global_position = Vector3.ZERO
				for who in ["Calm", "Still", "Thrasher"]:
					var p: CharacterBody3D = (load(PLAYER_SCENE) as PackedScene).instantiate()
					p.name = who
					root.add_child(p)
					_who.append(p)
				return false
			if _ticks < 5:
				return false
			for p in _who:
				_check(p.has_method("impaled_on"),
						"%s can be put on a spike" % p.name)
				_check(float(p.call("bleed_rate")) == 0.0,
						"%s is not bleeding before anything happens" % p.name)
			_next("pin")

		"pin":
			for p in _who:
				# Started on a sliver of health deliberately. Headless
				# Godot runs its physics in REAL TIME, so a full-health
				# player playing the timing game well survives about 95
				# seconds — a correct test nobody would ever wait for.
				# The three survival times stay in exactly the same
				# proportion, which is the thing being measured.
				p.call("set_health", TEST_HEALTH)
				p.call("impaled_on", _spike)
			for p in _who:
				_check(bool(p.call("is_impaled")), "%s is impaled" % p.name)
				_check(float(p.call("bleed_rate")) > 0.0,
						"%s starts bleeding at once (%.2f hp/s)"
						% [p.name, float(p.call("bleed_rate"))])
			# On the spike, not standing next to it.
			var up: float = (_who[0] as Node3D).global_position.y \
					- _spike.global_position.y
			_check(up > 1.0, "impaled UP the spike (%.2f m)" % up)
			_next("bleed")

		"bleed":
			# Each one plays differently, every tick, for as long as they
			# last. Nobody is helped or hindered by anything else.
			for p in _who:
				if _dead_at.has(p.name):
					continue
				match p.name:
					"Calm":
						# Plays the timing game properly: presses only
						# when the marker is actually in the good bit.
						if bool(p.call("timing_is_good")):
							p.call("press_timing")
					"Thrasher":
						# Fights and struggles constantly, which is the
						# worst thing you can do.
						p.call("thrash_once", true)
						_did[String(p.name)] = int(
								_did.get(String(p.name), 0)) + 1
					_:
						pass                        # "Still" does nothing
				# Death is counted, not read off health: bleeding out and
				# respawning happen in the SAME frame, so health is never
				# observably zero from out here.
				if int(p.call("bled_out")) > 0:
					_dead_at[p.name] = float(_ticks) * delta
					# Counted by the TEST, not read back off the player:
					# bleeding out releases you, and release clears the
					# thrash — so asking the player afterwards reports
					# 0.00 for whoever thrashed hardest, the exact
					# opposite of the truth.
					print("[BLEED] %s lasted %.1f s (%d good presses, "
							% [p.name, _dead_at[p.name],
							int(p.call("timing_hits"))]
							+ "%d struggles)" % int(_did.get(String(p.name), 0)))

			if _dead_at.size() < 3 and _ticks < 1800:
				return false

			for p in _who:
				if not _dead_at.has(p.name):
					_check(false, "%s bled out within the time limit" % p.name)
			if _dead_at.size() < 3:
				return _finish()

			var calm: float = _dead_at["Calm"]
			var still: float = _dead_at["Still"]
			var thrash: float = _dead_at["Thrasher"]
			print("[BLEED] calm %.1f s | doing nothing %.1f s | thrashing %.1f s"
					% [calm, still, thrash])

			_check(calm > still * 1.3,
					"playing the timing game well lasts NOTICEABLY longer "
					+ "than doing nothing (%.1f s vs %.1f s)" % [calm, still])
			_check(thrash < still * 0.8,
					"fighting and struggling dies NOTICEABLY sooner "
					+ "(%.1f s vs %.1f s)" % [thrash, still])
			_check(calm > thrash,
					"and staying calm beats fighting, which is the whole "
					+ "rule (%.1f s vs %.1f s)" % [calm, thrash])
			_next("rules")

		"rules":
			# Two rules that must hold no matter how well you play.
			var p: Node = _who[0]
			p.call("released")
			p.call("impaled_on", _spike)
			var before := float(p.call("health"))
			for i in 200:
				p.call("press_timing")
			_check(float(p.call("health")) <= before,
					"the timing game can never HEAL you, however hard you "
					+ "hammer it (%.1f -> %.1f)"
					% [before, float(p.call("health"))])
			_check(float(p.call("bleed_rate")) > 0.0,
					"and it can never stop the bleeding, only slow it "
					+ "(%.2f hp/s)" % float(p.call("bleed_rate")))

			# Struggling costs you your own life. Settled by the operator.
			var q: Node = _who[1]
			q.call("released")
			q.call("impaled_on", _spike)
			var hp_before := float(q.call("health"))
			var rate_before := float(q.call("bleed_rate"))
			q.call("thrash_once", true)
			print("[BLEED] one struggle: %.3f -> %.3f hp, rate %.2f -> %.2f"
					% [hp_before, float(q.call("health")), rate_before,
					float(q.call("bleed_rate"))])
			_check(float(q.call("health")) < hp_before,
					"mashing Space takes health off YOUR OWN LIFE")
			_check(float(q.call("bleed_rate")) > rate_before,
					"and it makes you bleed faster too")
			_next("free")

		"free":
			# Rescue must stop it dead. Otherwise being pulled off the
			# spike would leave you bleeding out in the open.
			var p: Node = _who[2]
			p.call("released")
			_check(float(p.call("bleed_rate")) == 0.0,
					"being freed stops the bleeding at once")
			_check(not bool(p.call("is_impaled")), "and you are off the spike")
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
