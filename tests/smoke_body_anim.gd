extends SceneTree
## Headless smoke test for STO-CHARACTER-016 (procedural body animation)
## and the Grabber-arms change. Run with:
##   godot --headless -s res://tests/smoke_body_anim.gd
##
## Verifies:
##   - walking makes the body's legs swing (procedural animation)
##   - the Grabber has NO human arms (mechanical arms instead), but keeps
##     shoulder joints; the Runner DOES have human arms

const CharacterDB := preload("res://scripts/characters.gd")
const WALK := 40

var _failures := 0
var _phase := "setup"
var _frames := 0
var _main: Node
var _player: CharacterBody3D
var _body
var _max_lift := 0.0
var _max_drag := 0.0


func _setup() -> bool:
	# --- Grabber: no human arms, mechanical arms instead (built directly,
	# no hosting so we don't take the multiplayer port twice) ---
	CharacterDB.selected_index = 0
	var gp: Node = load("res://scenes/player.tscn").instantiate()
	root.add_child(gp)
	var gbody := gp.get_node_or_null("Body")
	var no_human := gbody.find_child("UpperArmL", true, false) == null
	var has_shoulder := gbody.find_child("ShoulderL", true, false) != null
	var has_mech := gp.get_node_or_null("MechanicalArms") != null
	if no_human and has_shoulder and has_mech:
		_pass("Grabber has no human arms but has shoulders + mechanical arms")
	else:
		_fail("Grabber arms wrong (human_gone=%s shoulder=%s mech=%s)"
				% [no_human, has_shoulder, has_mech])
	gp.free()

	# --- Runner: has human arms, and we'll watch it walk ---
	CharacterDB.selected_index = 1
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	_main.host_game()
	_player = _main.get_node_or_null("Players/1") as CharacterBody3D
	if _player == null:
		_fail("no runner")
		return false
	_body = _player.get_node_or_null("Body")
	if _body == null:
		_fail("no body")
		return false
	if _body.find_child("UpperArmL", true, false) != null:
		_pass("Runner has human arms")
	else:
		_fail("Runner is missing human arms")
	return true


func _physics_process(_delta: float) -> bool:
	match _phase:
		"setup":
			if not _setup():
				return _done()
			_frames = 0
			_phase = "settle"
		"settle":
			_frames += 1
			if _frames >= 40:  # let the runner land before walking
				Input.action_press("move_forward")
				_frames = 0
				_phase = "walk"
		"walk":
			_frames += 1
			# A procedural gait lifts the feet off the ground as it steps.
			var gy: float = _player.global_position.y
			var l0: Vector3 = _body.foot_world(0)
			var l1: Vector3 = _body.foot_world(1)
			_max_lift = maxf(_max_lift, maxf(l0.y - gy, l1.y - gy))
			# How far each foot strays from its hip horizontally (drag).
			for k in 2:
				var fp: Vector3 = _body.foot_world(k)
				var hp: Vector3 = _body.hip_world(k)
				_max_drag = maxf(_max_drag, Vector2(fp.x - hp.x, fp.z - hp.z).length())
			if _frames >= WALK:
				Input.action_release("move_forward")
				if _max_lift > 0.05:
					_pass("procedural gait steps: a foot lifts off the ground (%.2f m)"
							% _max_lift)
				else:
					_fail("feet did not step/lift while walking (max %.2f m)" % _max_lift)
				if _max_drag < 0.9:
					_pass("legs stay under the player, not dragging (max %.2f m)"
							% _max_drag)
				else:
					_fail("legs drag behind the player (max %.2f m)" % _max_drag)
				_frames = 0
				_phase = "idle"
		"idle":
			_frames += 1
			if _frames >= 60:  # let the feet settle after stopping
				var gy: float = _player.global_position.y
				var f0: Vector3 = _body.foot_world(0)
				var f1: Vector3 = _body.foot_world(1)
				var hi := maxf(absf(f0.y - gy), absf(f1.y - gy))
				if hi < 0.12:
					_pass("feet rest on the ground when standing (%.2f m off)" % hi)
				else:
					_fail("feet float when standing still (%.2f m off ground)" % hi)
				return _done()
	return false


func _done() -> bool:
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _pass(msg: String) -> void:
	print("PASS: %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
