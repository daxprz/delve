extends SceneTree
## Smoke test for STO-ENEMIES-034 — the spider takes you.
##   godot --headless -s res://tests/smoke_taken.gd
##
## Watches the whole sequence happen by itself, with nothing driven by
## hand: reach -> catch -> SMASH into the ground -> drag along the floor
## -> put on a spike -> walk away.
##
## The check that matters most is the one the operator ruled on twice:
## you are DRAGGED ALONG THE GROUND, never lifted. So the test records
## how high the victim ever gets above the floor during the drag, and
## fails if it is carried. Every other check here would pass just as
## happily with the victim dangling in the air, which is exactly the
## design that was rejected.

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _spider: Node3D
var _victim: Node3D
var _seen: Array = []          # every take_state we passed through
var _peak_lift := -INF         # highest the victim got while dragged
var _drag_samples := 0
var _drag_dist := 0.0
var _grab_pos := Vector3.ZERO


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks < 5:
				if _ticks == 1:
					_main = load("res://scenes/main.tscn").instantiate()
					root.add_child(_main)
				return false
			# Find the one creature with pincer arms.
			for e in _main.get_node("Enemies").get_children():
				if e.has_method("take_state") and _has_arms(e):
					_spider = e
					break
			_check(_spider != null, "the giant spider is in the world")
			if _spider == null:
				return _finish()

			# One victim only, standing right where the spider is, so the
			# test is about the taking and not about pathfinding.
			var dummies := get_nodes_in_group("dummies")
			_check(dummies.size() > 0, "there is a dummy to be taken")
			if dummies.is_empty():
				return _finish()
			_victim = dummies[0]
			# Everything else out of the way: another player in the group
			# would let the spider pick a different target halfway and
			# quietly turn this into a test of nothing.
			for p in get_nodes_in_group("players"):
				if p != _victim and p is Node3D:
					(p as Node3D).global_position = Vector3(0.0, 0.0, 500.0)
			for e in _main.get_node("Enemies").get_children():
				if e != _spider and e is Node3D:
					(e as Node3D).global_position = Vector3(0.0, 0.0, -500.0)
			_victim.set_deferred("global_position",
					_spider.global_position + Vector3(1.5, -1.0, 0.0))
			_check(str(_spider.call("take_state")) == "none",
					"it is not taking anyone to begin with")
			_next("reach")

		"reach":
			_note_state()
			if _seen.has("reach") or _seen.has("smash"):
				_check(true, "it reaches for the victim when it gets close")
				_next("grab")
				return false
			if _ticks > 400:
				_check(false, "it reaches for the victim when it gets close "
						+ "(never did in 400 ticks)")
				return _finish()

		"grab":
			_note_state()
			if bool(_victim.call("is_taken")):
				_grab_pos = _victim.global_position
				print("[TAKEN] seized at %.1f, %.1f, %.1f"
						% [_grab_pos.x, _grab_pos.y, _grab_pos.z])
				_check(int(_spider.call("takes")) >= 1,
						"it takes hold of the victim")
				_next("drag")
				return false
			if _ticks > 400:
				_check(false, "it takes hold of the victim (never did)")
				return _finish()

		"drag":
			_note_state()
			# Sample the whole drag, not just the end of it.
			if str(_spider.call("take_state")) == "drag":
				_drag_samples += 1
				_peak_lift = maxf(_peak_lift, _lift())
			if bool(_victim.call("is_impaled")):
				_drag_dist = _victim.global_position.distance_to(_grab_pos)
				_next("impaled")
				return false
			if _ticks > 900:
				print("[TAKEN] states seen: %s" % str(_seen))
				_check(false, "it carries the victim to a spike "
						+ "(still %s after 900 ticks)"
						% str(_spider.call("take_state")))
				return _finish()

		"impaled":
			_check(true, "it puts the victim on a spike")
			print("[TAKEN] states seen, in order: %s" % str(_seen))
			_check(_seen.has("smash"),
					"the sequence goes through the SMASH into the ground")
			_check(_seen.has("drag"), "and through a drag")
			_check(_drag_samples > 5,
					"the drag lasts long enough to see (%d ticks)"
					% _drag_samples)

			# THE check. Dragged along the ground, never lifted.
			print("[TAKEN] highest the victim got while dragged: %.2f m "
					% _peak_lift + "above the floor")
			_check(_peak_lift < 1.2,
					"the victim is DRAGGED ALONG THE GROUND, not lifted "
					+ "(peak %.2f m up)" % _peak_lift)

			print("[TAKEN] dragged %.1f m from where it was grabbed"
					% _drag_dist)
			_check(_drag_dist > 1.0,
					"they end up somewhere else entirely (%.1f m)"
					% _drag_dist)

			# On the spike, not beside it.
			var spike := _nearest_spike(_victim.global_position)
			_check(spike != null, "there is a spike where they ended up")
			if spike != null:
				var flat := Vector2(
						_victim.global_position.x - spike.global_position.x,
						_victim.global_position.z - spike.global_position.z
						).length()
				var up := _victim.global_position.y - spike.global_position.y
				print("[TAKEN] left %.2f m from the spike's centre, %.2f m up"
						% [flat, up])
				_check(flat < 0.5, "left ON the spike, not beside it "
						+ "(%.2f m off)" % flat)
				_check(up > 1.0, "and up it, not at its foot (%.2f m)" % up)
			_next("leaves")

		"leaves":
			# It walks away and leaves you there. That pause is the whole
			# point of the story — a spider that immediately turns round
			# for someone else never lets the moment land.
			if _ticks < 60:
				return false
			var away := _spider.global_position.distance_to(
					_victim.global_position)
			print("[TAKEN] spider is %.1f m away one second later, state %s"
					% [away, str(_spider.call("take_state"))])
			_check(away > 2.0, "it walks away and leaves them there "
					+ "(%.1f m)" % away)
			_check(bool(_victim.call("is_impaled")),
					"and they are still stuck on it, alive")
			return _finish()
	return false


## How far above the floor directly under them the victim is.
func _lift() -> float:
	var from_p: Vector3 = _victim.global_position + Vector3.UP * 0.2
	var q := PhysicsRayQueryParameters3D.create(from_p,
			from_p + Vector3.DOWN * 12.0)
	q.exclude = [(_victim as CollisionObject3D).get_rid(),
			(_spider as CollisionObject3D).get_rid()]
	var hit := _victim.get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return 0.0
	return _victim.global_position.y - float(hit["position"].y)


func _nearest_spike(point: Vector3) -> Node3D:
	var best: Node3D = null
	var best_d := INF
	for s in get_nodes_in_group("spikes"):
		var d: float = (s as Node3D).global_position.distance_to(point)
		if d < best_d:
			best_d = d
			best = s
	return best


func _has_arms(e: Node) -> bool:
	var body := e.get_node_or_null("Body")
	return body != null and body.has_method("pincers") \
			and body.call("pincers") != null


func _note_state() -> void:
	var s := str(_spider.call("take_state"))
	if _seen.is_empty() or _seen[_seen.size() - 1] != s:
		_seen.append(s)


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
