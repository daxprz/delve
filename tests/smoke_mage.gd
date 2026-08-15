extends SceneTree
## Smoke test for STO-CHARACTER-074 and 075 — the Mage, and his four arms.
##   godot --headless -s res://tests/smoke_mage.gd
##
## The trap this file is built to avoid: "four arm nodes exist" is not
## the check. Four arms all built at the same place would satisfy it and
## would look like two arms. So the load-bearing measurement is that the
## four HANDS are in four DIFFERENT places, and that the lower pair sits
## BELOW the upper pair — which is what "four arms" actually means.
##
## Loaded at runtime, not with a const preload — see smoke_bleeding.gd.

const PLAYER_SCENE := "res://scenes/player.tscn"
const CHARS := "res://scripts/characters.gd"

var _failures := 0
var _ticks := 0
var _phase := "roster"
var _mage: Node
var _runner: Node
var _mage_index := -1
var _low_min := INF
var _low_max := -INF
var _gap := 0.0
var _main: Node


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"roster":
			var db = load(CHARS)
			for i in int(db.count()):
				if String(db.get_def(i)["id"]) == "mage":
					_mage_index = i
			print("[MAGE] roster has %d characters, mage at index %d"
					% [int(db.count()), _mage_index])
			_check(_mage_index >= 0,
					"the Mage is in the character registry")
			if _mage_index < 0:
				return _finish()
			var def: Dictionary = db.get_def(_mage_index)
			_check(String(def["name"]) == "Mage",
					"he is called the Mage (%s)" % String(def["name"]))
			for key in ["speed", "jump", "health", "color"]:
				_check(def.has(key),
						"he has his own %s, like every character" % key)
			_check(bool(def.get("four_arms", false)),
					"and he is marked as having four arms")
			# Added as DATA. If a new character ever needs the player
			# controller edited, this registry has stopped doing its job.
			_check(not bool(def.get("arms", false)),
					"he does NOT get the Grabber's mechanical arms")
			_next("spawn")

		"spawn":
			if _ticks == 1:
				# In the REAL scene, with a floor. The first version
				# added the players straight to the root and teleported
				# them about; the body animates off actual movement on
				# actual ground, so every swing measured exactly 0.0000
				# and the arms looked welded solid when they were not.
				_main = load("res://scenes/main.tscn").instantiate()
				root.add_child(_main)
				var db = load(CHARS)
				db.selected_index = _mage_index
				_mage = (load(PLAYER_SCENE) as PackedScene).instantiate()
				_mage.name = "1"
				_main.get_node("Players").add_child(_mage)
				# A Runner too, as the control: whatever is true of the
				# Mage's arms has to be FALSE for somebody else, or we
				# have just given everybody four arms.
				for i in int(db.count()):
					if String(db.get_def(i)["id"]) == "runner":
						db.selected_index = i
				_runner = (load(PLAYER_SCENE) as PackedScene).instantiate()
				_runner.name = "2"
				_main.get_node("Players").add_child(_runner)
				return false
			# Long enough to land on the floor before anything is
			# measured.
			if _ticks < 45:
				return false
			_check(_mage.has_method("character_id"),
					"the Mage spawns as a real player")
			_check(String(_mage.call("character_id")) == "mage",
					"and he is the Mage (%s)"
					% String(_mage.call("character_id")))
			_next("arms")

		"arms":
			var hands := _hands(_mage)
			var runner_hands := _hands(_runner)
			print("[MAGE] mage hands: %d, runner hands: %d"
					% [hands.size(), runner_hands.size()])
			_check(hands.size() == 4, "the Mage has FOUR hands (%d)"
					% hands.size())
			_check(runner_hands.size() == 2,
					"and nobody else grew extra ones (Runner has %d)"
					% runner_hands.size())
			if hands.size() < 4:
				return _finish()

			# Four DIFFERENT places. Four arms built on top of each other
			# would pass a count and look like two.
			var closest := INF
			for i in hands.size():
				for j in range(i + 1, hands.size()):
					closest = minf(closest,
							(hands[i] as Node3D).global_position.distance_to(
							(hands[j] as Node3D).global_position))
			print("[MAGE] closest two hands are %.3f m apart" % closest)
			_check(closest > 0.08,
					"all four are in DIFFERENT places — closest pair %.3f m "
					% closest + "apart, so you can count them")

			# And the lower pair really is lower.
			var upper_y := 0.0
			var lower_y := 0.0
			var n_up := 0
			var n_low := 0
			for h in hands:
				var nm := String((h as Node).name)
				if nm.begins_with("Lower"):
					lower_y += (h as Node3D).global_position.y
					n_low += 1
				else:
					upper_y += (h as Node3D).global_position.y
					n_up += 1
			_check(n_up == 2 and n_low == 2,
					"two up, two down (%d / %d)" % [n_up, n_low])
			if n_up == 2 and n_low == 2:
				upper_y /= 2.0
				lower_y /= 2.0
				print("[MAGE] upper hands at y=%.3f, lower at y=%.3f"
						% [upper_y, lower_y])
				_check(lower_y < upper_y,
						"the second pair really is LOWER (%.3f vs %.3f)"
						% [lower_y, upper_y])
			_next("moves")

		"moves":
			# He has to actually WALK. The first version of this phase
			# measured a man standing still, recorded 0.0000 m and
			# reported it as fine — which would have passed just as
			# happily with all four arms welded solid.
			if _ticks == 1:
				Input.action_press("move_forward")
				return false
			var lower_now := _swing("Lower")
			var upper_now := _swing("")
			_low_min = minf(_low_min, lower_now)
			_low_max = maxf(_low_max, lower_now)
			_gap = maxf(_gap, absf(lower_now - upper_now))
			if _ticks < 120:
				return false
			Input.action_release("move_forward")
			var swing := _low_max - _low_min
			print("[MAGE] while walking, the LOWER arms swung %.3f rad"
					% swing)
			_check(swing > 0.02,
					"the second pair really swings when he walks (%.3f rad)"
					% swing)
			print("[MAGE] widest gap between upper and lower swing: %.3f rad"
					% _gap)
			_check(_gap > 0.01,
					"and out of step with the top pair, so the four do not "
					+ "move as one block (%.3f rad)" % _gap)
			return _finish()
	return false


func _count(prefix: String) -> int:
	var body := _mage.get_node_or_null("Squash/Body")
	if body == null:
		body = _mage.get_node_or_null("Body")
	if body == null: return -1
	var f: Array = []
	_collect_named(body, prefix, f)
	return f.size()


## The swing angle of ONE upper-arm joint. `which` is "Lower" for the
## second pair, "" for the top pair.
##
## One arm, not the average of the pair. Left arms swing OPPOSITE right
## arms — that is the whole point of a walk — so averaging a left and a
## right cancels them to exactly 0.0000 every frame. The first version
## of this test did that and reported four welded arms on a body whose
## arms were swinging 0.6 radians.
func _swing(which: String) -> float:
	var body := _mage.get_node_or_null("Squash/Body")
	if body == null:
		body = _mage.get_node_or_null("Body")
	if body == null:
		return 0.0
	var found: Array = []
	_collect_named(body, which + "UpperArmL", found)
	if found.is_empty():
		return 0.0
	return (found[0] as Node3D).rotation.x


func _collect_named(n: Node, prefix: String, into: Array) -> void:
	var nm := String(n.name)
	# "UpperArmL" must not match when we asked for "LowerUpperArm", and
	# vice versa — so an exact prefix test, both ways.
	if nm.begins_with(prefix) and (prefix != "" or not nm.begins_with("Lower")):
		into.append(n)
	for c in n.get_children():
		_collect_named(c, prefix, into)


## Every hand on a body, upper pair and lower pair alike.
func _hands(who: Node) -> Array:
	var found: Array = []
	# Under Squash now, for the Mage's flattening (STO-CHARACTER-079).
	# Both paths are tried so this keeps working whichever way the body
	# is hung.
	var body := who.get_node_or_null("Squash/Body")
	if body == null:
		body = who.get_node_or_null("Body")
	if body == null:
		return found
	_collect(body, found)
	return found


func _collect(n: Node, into: Array) -> void:
	var nm := String(n.name)
	if nm.begins_with("Hand") or nm.begins_with("LowerHand"):
		into.append(n)
	for c in n.get_children():
		_collect(c, into)


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
