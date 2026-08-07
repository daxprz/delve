extends SceneTree
## Headless smoke test for STO-TOOLS-002 (DebugOverlay).
##   godot --headless -s res://tests/smoke_debug_overlay.gd
## Verifies: registration, observer union semantics, log gating,
## transient-observer clearing, and that DebugAspects registered the
## initial tree. Exits 0 on PASS, 1 on FAIL.

var _failures := 0


func _physics_process(_delta: float) -> bool:
	# Setup on first tick, not _initialize (godot-headless-testing).
	var dbg := root.get_node("/root/DebugOverlay")

	# 1. DebugAspects registered the initial tree.
	_check(dbg.has_aspect("network/peers"), "DebugAspects registered network/peers")
	_check(dbg.has_aspect("enemy/ai"), "DebugAspects registered enemy/ai")
	_check(dbg.has_aspect("perf/fps"), "DebugAspects registered perf/fps")

	# 2. Log gating: off by default, on with an observer, off again.
	_check(not _would_log(dbg, "enemy/ai"), "enemy/ai silent by default")
	dbg.set_observer("enemy/ai", "test:smoke", false, dbg.TextMode.LOG)
	_check(_would_log(dbg, "enemy/ai"), "test observer enables enemy/ai log")

	# 3. Union semantics: removing ONE of two observers keeps it on.
	dbg.set_observer("enemy/ai", "human", false, dbg.TextMode.LOG)
	dbg.set_observer("enemy/ai", "test:smoke", false, dbg.TextMode.NONE)
	_check(_would_log(dbg, "enemy/ai"), "human observer keeps enemy/ai on")

	# 4. clear_transient_observers removes tests but not the human.
	dbg.set_observer("enemy/ai", "test:smoke2", false, dbg.TextMode.LOG)
	dbg.clear_transient_observers()
	_check(_would_log(dbg, "enemy/ai"), "clear keeps human observer")
	dbg.set_observer("enemy/ai", "human", false, dbg.TextMode.NONE)
	_check(not _would_log(dbg, "enemy/ai"), "removing last observer silences")

	# 5. should_draw needs BOTH global_enabled and a visual observer.
	dbg.set_observer("network/peers", "test:smoke", true, dbg.TextMode.NONE)
	_check(not dbg.should_draw("network/peers"), "visual gated by global_enabled")
	dbg.global_enabled = true
	_check(dbg.should_draw("network/peers"), "visual on with global + observer")
	dbg.global_enabled = false
	dbg.clear_transient_observers()

	# 6. Unknown aspects auto-register via set_observer.
	dbg.set_observer("adhoc/thing", "test:smoke", false, dbg.TextMode.LOG)
	_check(dbg.has_aspect("adhoc/thing"), "set_observer auto-registers")

	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


## True if a log() call for this aspect would print.
func _would_log(dbg: Node, path: String) -> bool:
	var info = dbg._aspects.get(path)
	return info != null and info.actual_textual != dbg.TextMode.NONE


func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: %s" % label)
	else:
		_failures += 1
		print("FAIL: %s" % label)
