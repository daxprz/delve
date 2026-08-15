extends SceneTree
## Smoke test for STO-ENEMIES-033 — sharp things in the world.
##   godot --headless -s res://tests/smoke_spikes.gd
##
## The load-bearing check is `Spike.nearest()` answering CORRECTLY from
## two different positions. "A spike exists" would pass with the lookup
## hard-wired to return the first one in the list, and the spider would
## then drag every victim to the same place forever — a bug that looks
## exactly like working code from anywhere except the far side of the
## map.

const SpikeScript := preload("res://scripts/spike.gd")

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _spikes: Array = []


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks < 5:
				if _ticks == 1:
					_main = load("res://scenes/main.tscn").instantiate()
					root.add_child(_main)
				return false
			_spikes = get_nodes_in_group(SpikeScript.GROUP)
			_check(_spikes.size() >= 1,
					"at least one sharp thing stands in the world (%d)"
					% _spikes.size())
			if _spikes.is_empty():
				return _finish()
			for s in _spikes:
				print("[SPIKE] %s at %.1f, %.1f, %.1f" % [(s as Node).name,
						(s as Node3D).global_position.x,
						(s as Node3D).global_position.y,
						(s as Node3D).global_position.z])
			_check(_spikes[0] is StaticBody3D,
					"it is solid — a real body, not a marker")
			_check((_spikes[0] as Node).has_method("impale_point"),
					"it knows where a victim ends up on it")
			_next("point")

		"point":
			var s := _spikes[0] as Node3D
			var p: Vector3 = s.call("impale_point")
			var up := p.y - s.global_position.y
			print("[SPIKE] impale point sits %.2f m up the shaft" % up)
			_check(up > 0.5,
					"the impale point is UP the spike, not at its base "
					+ "(%.2f m)" % up)
			_check(up < SpikeScript.HEIGHT,
					"and not floating above the tip (%.2f m of %.2f)"
					% [up, SpikeScript.HEIGHT])
			_next("nearest")

		"nearest":
			# The real check. Ask from right beside each spike in turn: a
			# lookup that ignores its argument gets one of these right by
			# luck and the other wrong, so both must be asserted.
			if _spikes.size() < 2:
				print("[SPIKE] only one spike in the world — the nearest-of-"
						+ "many check cannot run and is NOT verified")
				_check(false, "two or more spikes exist so 'nearest' is a "
						+ "real choice")
				return _finish()
			var ok := true
			for i in _spikes.size():
				var here := (_spikes[i] as Node3D).global_position
				var probe := here + Vector3(0.4, 0.0, 0.4)
				var got: Node3D = SpikeScript.nearest(_main, probe)
				var right: bool = got == _spikes[i]
				ok = ok and right
				print("[SPIKE] standing by %s -> nearest is %s"
						% [(_spikes[i] as Node).name,
						got.name if got != null else "(none)"])
			_check(ok, "the nearest spike to a point is the one actually "
					+ "nearest it, for every spike")

			# And from a point far outside them all.
			var far := Vector3(0.0, 0.0, 60.0)
			var best: Node3D = null
			var best_d := INF
			for s in _spikes:
				var d: float = (s as Node3D).global_position.distance_to(far)
				if d < best_d:
					best_d = d
					best = s
			_check(SpikeScript.nearest(_main, far) == best,
					"and from far outside them all")
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
