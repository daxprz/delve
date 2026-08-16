extends SceneTree
## Smoke tests for STO-CHARACTER-084 (Q left claw, E right claw) and
## STO-CHARACTER-085 (a shut claw holds what it closed on).
##   godot --headless -s res://tests/smoke_claw.gd
##
## Two checks carry this file, and both are comparisons:
##
## 1. Working ONE claw must not move the other. Two independent claws
##    is the whole point of two keys — "the claw closed" would pass for
##    a single claw worked by either key.
##
## 2. Caught partway, a claw must be PARTWAY. A claw machine's claw
##    travels; testing only open and shut would pass for one that
##    snaps, and the slow travel is the character of the thing.
##
## Runs offline — no port, so it works while the game is open.

const CHARS := preload("res://scripts/characters.gd")

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _me: Node
var _arms: Node
var _mid_left := -1.0
var _box: RigidBody3D


func _open(i: int) -> float:
	return float(_arms.call("claw_openness", i))


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks == 1:
				_main = load("res://scenes/main.tscn").instantiate()
				root.add_child(_main)
				return false
			if _ticks < 10:
				return false
			for i in int(CHARS.count()):
				if String(CHARS.get_def(i)["id"]) == "grabber":
					CHARS.selected_index = i
			_main.call("_begin_game")
			_main.call("_spawn_player", 1)
			return false if _ticks < 40 else _next("found")

		"found":
			_me = _main.get_node_or_null("Players/1")
			_check(_me != null, "a Grabber is in the world")
			if _me == null:
				return _finish()
			_arms = _me.get_node_or_null("MechanicalArms")
			_check(_arms != null and _arms.has_method("claw_openness"),
					"its hands are a claw")
			if _arms == null:
				return _finish()
			_check(bool(_arms.get("claw_mode")),
					"claw mode is on for the Grabber")
			print("[CLAW] starting: left %.2f, right %.2f"
					% [_open(0), _open(1)])
			_check(not bool(_arms.call("claw_shut", 0)),
					"the left claw starts open")
			_check(not bool(_arms.call("claw_shut", 1)),
					"and so does the right")
			_next("looks_like_a_claw")

		"looks_like_a_claw":
			# STO-CHARACTER-087. Counting is not enough — three fingers
			# in a row would count as three. They have to be spread
			# AROUND a hub.
			var root: Node3D = _arms.call("fingers_root", 0)
			_check(root != null, "the claw has digits at all")
			if root == null:
				return _finish()
			var digits: Array = root.get_children()
			var names: Array = []
			for d in digits:
				names.append(String(d.name))
			print("[CLAW] digits on the left hand: %s" % str(names))
			_check(digits.size() == 4,
					"it has FOUR prongs, one per corner (%d)"
					% digits.size())
			if digits.size() == 4:
				var lo := Vector2(999, 999)
				var hi := Vector2(-999, -999)
				var corners := {}
				for d in digits:
					var pos: Vector3 = (d as Node3D).position
					lo = Vector2(minf(lo.x, pos.x), minf(lo.y, pos.y))
					hi = Vector2(maxf(hi.x, pos.x), maxf(hi.y, pos.y))
					corners["%.0f,%.0f" % [signf(pos.x), signf(pos.y)]] = true
				var spread_x := hi.x - lo.x
				var spread_y := hi.y - lo.y
				print("[CLAW] prongs spread %.3f across, %.3f up; %d corners"
						% [spread_x, spread_y, corners.size()])
				_check(spread_x > 0.01 and spread_y > 0.01,
						"spread AROUND a hub, not in a row (%.3f x %.3f)"
						% [spread_x, spread_y])
				_check(corners.size() == 4,
						"one prong at each of the FOUR corners (%d)"
						% corners.size())
				# Shaped like `<`: the elbow sits OFF the straight line
				# from base to tip. A straight spike has its elbow
				# exactly ON that line, so this cannot pass for one.
				var worst_bend := 0.0
				for d in digits:
					var j0 := (d as Node3D).get_node_or_null("J0") as Node3D
					if j0 == null:
						continue
					var elbow := j0.get_node_or_null("End") as Node3D
					if elbow == null:
						continue
					var j1 := elbow.get_node_or_null("J1") as Node3D
					if j1 == null:
						continue
					var tip := j1.get_node_or_null("End") as Node3D
					if tip == null:
						continue
					var a := (d as Node3D).global_position
					var dir := tip.global_position - a
					if dir.length() < 0.001:
						continue
					dir = dir.normalized()
					var rel := elbow.global_position - a
					worst_bend = maxf(worst_bend,
							(rel - dir * rel.dot(dir)).length())
				print("[CLAW] elbow sits %.4f m off the straight line"
						% worst_bend)
				# STO-CHARACTER-088: two blocks each, short base and long
				# top, same section, and every piece carrying collision.
				var d0 := digits[0] as Node3D
				var blocks := 0
				var n: Node3D = d0
				var lens: Array = []
				var sects: Array = []
				while true:
					var j := n.get_node_or_null("J%d" % blocks) as Node3D
					if j == null:
						break
					var mesh := j.get_node_or_null("Seg") as MeshInstance3D
					if mesh != null:
						var sz: Vector3 = (mesh.mesh as BoxMesh).size
						lens.append(sz.z)
						sects.append(Vector2(sz.x, sz.y))
					blocks += 1
					n = j.get_node_or_null("End") as Node3D
					if n == null:
						break
				print("[CLAW] blocks per prong: %d, lengths %s, sections %s"
						% [blocks, str(lens), str(sects)])
				_check(blocks == 2,
						"each prong is TWO blocks (%d)" % blocks)
				if lens.size() == 2:
					_check(float(lens[0]) < float(lens[1]),
							"the base is SHORTER than the top (%.3f vs %.3f)"
							% [float(lens[0]), float(lens[1])])
					_check((sects[0] as Vector2).is_equal_approx(
							sects[1] as Vector2),
							"both the same width and height — no taper")
					_check((sects[0] as Vector2).x < 0.07,
							"and slim (%.3f m across)"
							% (sects[0] as Vector2).x)
				_check(int(_arms.call("prong_piece_count")) == 16,
						"every piece has collision — 4 prongs x 2 blocks x "
						+ "2 hands = %d" % int(_arms.call("prong_piece_count")))
				_check(worst_bend > 0.005,
						"each prong is BENT like < — elbow %.4f m off the "
						% worst_bend + "base-to-tip line, not a spike")
			_next("close_left")

		"close_left":
			# Q shuts the LEFT claw. The right must not move.
			if _ticks == 1:
				Input.action_press("ability_zip")     # Q
				return false
			if _ticks == 2:
				Input.action_release("ability_zip")
				return false
			# Caught halfway: a claw that snaps is never here.
			if _ticks == 18:
				_mid_left = _open(0)
				return false
			if _ticks < 90:
				return false
			print("[CLAW] after Q: left %.2f (halfway it was %.2f), "
					% [_open(0), _mid_left] + "right %.2f" % _open(1))
			_check(bool(_arms.call("claw_shut", 0)),
					"Q shuts the LEFT claw")
			# THE comparison. Two keys, two claws.
			_check(not bool(_arms.call("claw_shut", 1)),
					"and leaves the right one alone — they are two "
					+ "separate claws, not one")
			_check(_mid_left > 0.1 and _mid_left < 0.85,
					"it TRAVELS: caught halfway it was %.2f, not open or "
					% _mid_left + "shut")
			_next("close_right")

		"close_right":
			if _ticks == 1:
				Input.action_press("toggle_arm_mode")   # E
				return false
			if _ticks == 2:
				Input.action_release("toggle_arm_mode")
				return false
			if _ticks < 90:
				return false
			print("[CLAW] after E: left %.2f, right %.2f"
					% [_open(0), _open(1)])
			_check(bool(_arms.call("claw_shut", 1)), "E shuts the RIGHT claw")
			_check(bool(_arms.call("claw_shut", 0)),
					"and the left one stays shut — each claw keeps its "
					+ "own state")
			_next("open_again")

		"open_again":
			# Pressing again opens it. A toggle, not a hold.
			if _ticks == 1:
				Input.action_press("ability_zip")
				return false
			if _ticks == 2:
				Input.action_release("ability_zip")
				return false
			if _ticks < 90:
				return false
			print("[CLAW] Q again: left %.2f" % _open(0))
			_check(not bool(_arms.call("claw_shut", 0)),
					"pressing Q again OPENS the left claw — it toggles")
			_check(bool(_arms.call("claw_shut", 1)),
					"and the right is still shut")
			_next("grab_setup")

		"grab_setup":
			# STO-CHARACTER-085: shut it on something.
			if _ticks == 1:
				var hand: Node3D = _arms.call("_claw_hand", 0)
				_check(hand != null, "the left claw has a hand")
				if hand == null:
					return _finish()
				_box = RigidBody3D.new()
				_box.name = "Prize"
				_box.add_to_group("grabbable")
				var cs := CollisionShape3D.new()
				var bx := BoxShape3D.new()
				bx.size = Vector3.ONE * 0.4
				cs.shape = bx
				_box.add_child(cs)
				_main.add_child(_box)
				_box.global_position = hand.global_position
				_box.freeze = true          # hold it still to be caught
				return false
			if _ticks < 20:
				return false
			_check(_arms.call("grabbed_body", 0) == null,
					"nothing is held before the claw shuts")
			_next("bite")

		"bite":
			if _ticks == 1:
				Input.action_press("ability_zip")
				return false
			if _ticks == 2:
				Input.action_release("ability_zip")
				return false
			if _ticks < 100:
				return false
			var held = _arms.call("grabbed_body", 0)
			print("[CLAW] after shutting on it: holding %s"
					% (held.name if held != null else "nothing"))
			_check(held == _box,
					"shutting the claw on something CATCHES it")
			_next("let_go")

		"let_go":
			if _ticks == 1:
				Input.action_press("ability_zip")
				return false
			if _ticks == 2:
				Input.action_release("ability_zip")
				return false
			if _ticks < 40:
				return false
			var held = _arms.call("grabbed_body", 0)
			print("[CLAW] after opening: holding %s"
					% (held.name if held != null else "nothing"))
			_check(held == null, "opening it drops what it held")
			_check(is_instance_valid(_box),
					"and the thing still exists afterwards")
			return _finish()
	return false


func _next(phase: String) -> bool:
	_phase = phase
	_ticks = 0
	return false


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
