extends SceneTree
## Smoke test for STO-ENEMIES-049 — the screen tells you what is
## happening to you.
##   godot --headless -s res://tests/smoke_screen_taken.gd
##
## Three stages, three different screens: nothing, then DIM while you
## are dragged, then RED on the spike. The two rules that matter are
## asserted directly, because both are easy to break by tuning a number
## and neither would ever show up as a crash:
##
##   1. It never goes opaque. "You can look around" and "you can still
##      kinda see" were both stated outright, and a screen you cannot
##      see through is the same as not being in the game.
##   2. It CLEARS. A red screen left over on a fresh life would be a bug
##      you could not do anything about.
##
## Loaded at runtime, not with a const preload — see smoke_bleeding.gd
## for why that distinction matters here.

const PLAYER_SCENE := "res://scenes/player.tscn"
const SPIKE_SCRIPT := "res://scripts/spike.gd"

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _p: Node
var _spike: Node3D
var _dim := Color()
var _before := 0.0


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks == 1:
				_spike = (load(SPIKE_SCRIPT) as GDScript).new()
				_spike.name = "TestSpike"
				root.add_child(_spike)
				_p = (load(PLAYER_SCENE) as PackedScene).instantiate()
				_p.name = "Victim"
				root.add_child(_p)
				return false
			if _ticks < 5:
				return false
			_check(_p.has_method("screen_tint"),
					"the player has a screen effect at all")
			_check(_tint().a < 0.01,
					"free, the screen is completely clear (alpha %.2f)"
					% _tint().a)
			_next("dragged")

		"dragged":
			if _ticks == 1:
				# A real captor node, not null: grabbed_by stores what it
				# is given, so passing null sets "grabbed by nobody" and
				# the player never enters the dragged state at all.
				var captor := Node3D.new()
				captor.name = "PretendSpider"
				root.add_child(captor)
				_p.call("grabbed_by", captor)
				return false
			if _ticks < 40:
				return false
			_dim = _tint()
			print("[SCREEN] dragged: rgba %.2f %.2f %.2f a=%.2f"
					% [_dim.r, _dim.g, _dim.b, _dim.a])
			_check(_dim.a > 0.2, "dragged, the screen goes dim (alpha %.2f)"
					% _dim.a)
			_check(_dim.a < 0.85, "but never dark enough to blind you "
					+ "(alpha %.2f)" % _dim.a)
			_check(_dim.r < 0.2, "and it is a DIM, not a red (r %.2f)" % _dim.r)
			_next("impaled")

		"impaled":
			if _ticks == 1:
				_p.call("impaled_on", _spike)
				return false
			if _ticks < 40:
				return false
			var red := _tint()
			print("[SCREEN] impaled: rgba %.2f %.2f %.2f a=%.2f"
					% [red.r, red.g, red.b, red.a])
			_check(red.r > 0.4, "on the spike, the screen turns RED (r %.2f)"
					% red.r)
			_check(red.r > red.g * 3.0 and red.r > red.b * 3.0,
					"properly red, not a muddy grey")
			_check(red.a < 0.85, "and you can still kinda see (alpha %.2f)"
					% red.a)
			_next("gauge")

		"gauge":
			# The redness follows the bleed rate, so the colour is the
			# gauge. Thrashing should visibly close the room in.
			if _ticks == 1:
				_before = _tint().a
				# ONCE, not every tick. Repeating it each frame drove the
				# bleed rate past 1000 hp/s and killed the player before
				# the screen had time to catch up — which read as "the
				# colour is not the gauge" when the real fault was the
				# test hitting it far harder than any player could.
				for i in 12:
					_p.call("thrash_once", false)
				return false
			var before := _before
			if _ticks < 45:
				return false
			var after := _tint().a
			print("[SCREEN] alpha %.2f -> %.2f after thrashing (rate %.1f hp/s)"
					% [before, after, float(_p.call("bleed_rate"))])
			_check(after > before,
					"bleeding harder makes the screen redder — the colour "
					+ "is the gauge (%.2f -> %.2f)" % [before, after])
			_check(after < 0.9, "and even at its worst you can see out "
					+ "(alpha %.2f)" % after)
			_next("freed")

		"freed":
			if _ticks == 1:
				_p.call("released")
				return false
			if _ticks < 90:
				return false
			print("[SCREEN] freed: alpha back to %.3f" % _tint().a)
			_check(_tint().a < 0.02,
					"being freed clears the screen completely (alpha %.3f)"
					% _tint().a)
			return _finish()
	return false


func _tint() -> Color:
	return _p.call("screen_tint") as Color


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
