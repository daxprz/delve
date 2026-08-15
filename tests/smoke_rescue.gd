extends SceneTree
## Smoke test for STO-ENEMIES-035 — your friends pull you free.
##   godot --headless -s res://tests/smoke_rescue.gd
##
## The NEGATIVE case is the important one and it is checked first: a
## rescuer standing far away, holding the key for far longer than it
## takes, must free nobody. Without that, a rescue that fires for
## everyone everywhere passes every other check in this file — and a
## spike you can be lifted off from across the map is not a threat.
##
## It presses the REAL key rather than calling hold_rescue() directly.
## The first version called the function, and every call was undone the
## same frame by the player's own input handling seeing the key was not
## held and cancelling the pull. Driving the function is not driving the
## feature.
##
## Pressing the key is also global, which makes the far-away phase do
## double duty: the impaled victim is holding it too, so if anyone could
## ever free themselves, that phase would catch it.
##
## Loaded at runtime, not with a const preload — see smoke_bleeding.gd.

const PLAYER_SCENE := "res://scenes/player.tscn"
const SPIKE_SCRIPT := "res://scripts/spike.gd"
const STEP := 1.0 / 60.0

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _spike: Node3D
var _victim: Node
var _hero: Node


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks == 1:
				_spike = (load(SPIKE_SCRIPT) as GDScript).new()
				_spike.name = "TestSpike"
				root.add_child(_spike)
				_spike.global_position = Vector3.ZERO
				for who in ["Victim", "Hero"]:
					var p: CharacterBody3D = (load(PLAYER_SCENE)
							as PackedScene).instantiate()
					p.name = who
					p.add_to_group("players")
					root.add_child(p)
					if who == "Victim":
						_victim = p
					else:
						_hero = p
				return false
			if _ticks < 5:
				return false
			_check(_hero.has_method("hold_rescue"),
					"a player can try to rescue somebody")
			_check(InputMap.has_action("rescue"),
					"there is a key bound to rescuing")
			_victim.call("impaled_on", _spike)
			_check(bool(_victim.call("is_impaled")),
					"the victim is on the spike")
			_next("too_far")

		"too_far":
			# Standing well outside reach, holding it far longer than
			# the pull takes.
			(_hero as Node3D).global_position = Vector3(40.0, 0.0, 0.0)
			Input.action_press("rescue")
			if _ticks < 300:      # 5 s — over three times PULL_TIME
				return false
			print("[RESCUE] held from 40 m for 5 s, pull progress %.2f"
					% float(_hero.call("pull_progress")))
			_check(bool(_victim.call("is_impaled")),
					"holding the key from far away frees NOBODY")
			_check(float(_hero.call("pull_progress")) < 0.01,
					"and makes no progress at all")
			# The key is held globally, so the victim has been mashing it
			# for those same five seconds.
			_check(bool(_victim.call("is_impaled")),
					"and an impaled player cannot free themselves either")
			_next("close")

		"close":
			# Re-placed every tick, not once: there is no floor in this
			# test, so a hero left alone simply falls out of range and
			# the rescue silently never fires.
			(_hero as Node3D).global_position = \
					_spike.global_position + Vector3(1.5, 1.5, 0.0)
			if bool(_victim.call("is_impaled")):
				if _ticks < 200:
					return false
				_check(false, "holding the key up close pulls them off "
						+ "(never did in 200 ticks)")
				return _finish()
			var took := float(_ticks) * STEP
			print("[RESCUE] pulled off the spike after %.2f s" % took)
			_check(took > 1.0 and took < 2.5,
					"it takes about a second and a half (%.2f s)" % took)
			_check(float(_victim.call("bleed_rate")) == 0.0,
					"the bleeding stops at once")
			_check(bool(_victim.call("is_being_rescued")),
					"they are not free yet — the hero has hold of them")
			_check(bool(_victim.call("is_limp")),
					"and they come off LIMP, to be dragged back")
			_next("drag_back")

		"drag_back":
			# Now haul them away from the spike.
			(_hero as Node3D).global_position = Vector3(
					1.5 + float(_ticks) * 0.05, 1.5, 0.0)
			if _ticks < 120:
				return false
			var moved: float = (_victim as Node3D).global_position \
					.distance_to(_spike.global_position)
			print("[RESCUE] dragged %.1f m from the spike" % moved)
			_check(moved > 2.0,
					"the hero drags them back away from the spike (%.1f m)"
					% moved)
			_next("let_go")

		"let_go":
			if _ticks == 1:
				Input.action_release("rescue")
				return false
			if _ticks < 30:
				return false
			_check(not bool(_victim.call("is_being_rescued")),
					"letting go sets them down")
			_check(not bool(_victim.call("is_limp")),
					"they get their body back")
			_check(not bool(_victim.call("is_taken")),
					"and they are free — moving again, nothing holding them")
			_check(float(_victim.call("bleed_rate")) == 0.0,
					"and not bleeding")
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
