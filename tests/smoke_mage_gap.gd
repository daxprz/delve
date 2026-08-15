extends SceneTree
## Smoke test for STO-CHARACTER-077 — flat, he fits through gaps that
## are otherwise impossible.
##   godot --headless -s res://tests/smoke_mage_gap.gd
##
## The whole test is ONE comparison, and the story insists on it:
##
##   > The SAME gap stops him when he is not flat. This comparison is
##   > required, not optional — without it "he went through" proves
##   > nothing.
##
## So the identical journey is walked twice, at the identical wall,
## from the identical spot. Solid he must be stopped; flat he must get
## through. Either half alone is worthless: "he got through" passes for
## a gap that was never narrow, and "he was stopped" passes for a Mage
## who cannot walk.
##
## It also checks he cannot walk through a SOLID wall while flat —
## otherwise the ability is not "thin", it is "ghost".

const PLAYER_SCENE := "res://scenes/player.tscn"
const CHARS := "res://scripts/characters.gd"

## The slot is far too narrow for a 0.8 m-wide person and far wider
## than a 0.06 m hitbox, so neither result can be a near-miss.
const SLOT := 0.30
const WALL_Z := -6.0
const START_Z := -3.0

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _mage: Node
var _solid_reached := 0.0
var _flat_reached := 0.0


func _wall(nm: String, at_x: float, width: float) -> void:
	var b := StaticBody3D.new()
	b.name = nm
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(width, 4.0, 0.6)
	cs.shape = bx
	b.add_child(cs)
	_main.add_child(b)
	b.global_position = Vector3(at_x, 2.0, WALL_Z)


func _reset() -> void:
	(_mage as Node3D).global_position = Vector3(0.0, 1.0, START_Z)
	(_mage as Node3D).rotation.y = 0.0     # facing -Z, straight at the slot
	(_mage as CharacterBody3D).velocity = Vector3.ZERO


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks == 1:
				_main = load("res://scenes/main.tscn").instantiate()
				root.add_child(_main)
				# A wall with a narrow vertical slot straight ahead.
				_wall("SlabL", -3.0 - SLOT * 0.5, 6.0)
				_wall("SlabR", 3.0 + SLOT * 0.5, 6.0)
				var db = load(CHARS)
				for i in int(db.count()):
					if String(db.get_def(i)["id"]) == "mage":
						db.selected_index = i
				_mage = (load(PLAYER_SCENE) as PackedScene).instantiate()
				_mage.name = "1"
				_main.get_node("Players").add_child(_mage)
				return false
			if _ticks < 45:
				return false
			print("[GAP] slot is %.2f m wide; he is 0.80 m across solid"
					% SLOT)
			_reset()
			_next("solid")

		"solid":
			# Walk straight at the slot as a normal, round person.
			if _ticks == 1:
				Input.action_press("move_forward")
				return false
			if _ticks < 150:
				return false
			Input.action_release("move_forward")
			_solid_reached = (_mage as Node3D).global_position.z
			print("[GAP] solid: walked from z=%.2f to z=%.2f (wall at %.1f)"
					% [START_Z, _solid_reached, WALL_Z])
			_check(_solid_reached > WALL_Z,
					"solid, the wall STOPS him — he never reaches it "
					+ "(z=%.2f)" % _solid_reached)
			_next("flat")

		"flat":
			# The identical journey, flat.
			if _ticks == 1:
				_reset()
				return false
			if _ticks == 2:
				Input.action_press("mage_flatten")
				return false
			if _ticks == 3:
				Input.action_release("mage_flatten")
				return false
			if _ticks == 20:
				_check(bool(_mage.call("is_flat")), "he goes flat")
				Input.action_press("move_forward")
				return false
			if _ticks < 170:
				return false
			Input.action_release("move_forward")
			_flat_reached = (_mage as Node3D).global_position.z
			print("[GAP] flat:  walked from z=%.2f to z=%.2f (wall at %.1f)"
					% [START_Z, _flat_reached, WALL_Z])
			_check(_flat_reached < WALL_Z - 0.5,
					"flat, he goes STRAIGHT THROUGH the same gap (z=%.2f)"
					% _flat_reached)
			_check(_flat_reached < _solid_reached - 1.0,
					"the same journey, two different answers: %.2f solid "
					% _solid_reached + "vs %.2f flat" % _flat_reached)
			_next("solid_wall")

		"solid_wall":
			# Thin is not the same as a ghost. A wall with NO gap must
			# still stop him.
			if _ticks == 1:
				_wall("Solid", 0.0, 40.0)
				(_mage as Node3D).global_position = Vector3(
						0.0, 1.0, WALL_Z + 3.0)
				(_mage as Node3D).rotation.y = 0.0
				(_mage as CharacterBody3D).velocity = Vector3.ZERO
				return false
			if _ticks == 10:
				Input.action_press("move_forward")
				return false
			if _ticks < 160:
				return false
			Input.action_release("move_forward")
			var z: float = (_mage as Node3D).global_position.z
			print("[GAP] flat, at a wall with NO gap: reached z=%.2f" % z)
			_check(bool(_mage.call("is_flat")),
					"he is still flat for this")
			_check(z > WALL_Z,
					"a wall with no gap still stops him — he is thin, not "
					+ "a ghost (z=%.2f)" % z)
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
