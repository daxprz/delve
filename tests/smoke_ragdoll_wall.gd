extends SceneTree
## Regression test for STO-ENEMIES-010: a ragdoll thrown hard into a
## THIN wall must behave like it does against the floor — no tunnelling
## through, no violent ejection, no spinning freak-out.
##   godot --headless -s res://tests/smoke_ragdoll_wall.gd
## Walls in the procedural map are 0.3 m thick; ragdoll parts can move
## further than that in a single 60 Hz tick, so without continuous
## collision they pass into the wall and get flung out.

const WALL_T := 0.3
const WALL_X := 4.0          # wall plane at x = +4
const SETTLE := 40
const WATCH := 240
const SANE_SPEED := 26.0     # m/s — above the launch, below "flung"
const SANE_ANGULAR := 22.0   # rad/s

var _failures := 0
var _phase := "setup"
var _ticks := 0
var _enemy: CharacterBody3D
var _worst_speed := 0.0
var _worst_ang := 0.0
var _tunnelled := false
var _late_speed := 0.0


func _physics_process(_delta: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			_static_box(Vector3(0, -0.5, 0), Vector3(60, 1, 60))      # floor
			# A thin wall, exactly like procmap builds them.
			_static_box(Vector3(WALL_X, 3.0, 0), Vector3(WALL_T, 6, 30))
			var es: GDScript = load("res://scripts/enemy.gd")
			_enemy = es.new()
			_enemy.name = "WallTester"
			_enemy.position = Vector3(0.0, 1.0, 0.0)
			root.add_child(_enemy)
			_next("settle")
		"settle":
			if _ticks < SETTLE:
				return false
			# Ragdoll it straight at the wall, hard.
			_enemy.apply_knockback(Vector3(26.0, 3.0, 0.0))
			_check(_enemy.is_downed(), "enemy ragdolled toward the wall")
			_next("watch")
		"watch":
			var rag: Node3D = _enemy.ragdoll()
			if rag != null:
				for pname in ["Pelvis", "Torso", "Head", "ThighL", "ShinR"]:
					var part: RigidBody3D = rag.call("part", pname)
					if part == null:
						continue
					var sp := part.linear_velocity.length()
					_worst_speed = maxf(_worst_speed, sp)
					_worst_ang = maxf(_worst_ang, part.angular_velocity.length())
					if _ticks > WATCH / 2:
						_late_speed = maxf(_late_speed, sp)
					# Past the far face of the wall = tunnelled through.
					if part.global_position.x > WALL_X + WALL_T:
						_tunnelled = true
			if _ticks < WATCH:
				return false

			_check(not _tunnelled,
					"no ragdoll part tunnelled through the thin wall")
			_check(_worst_speed < SANE_SPEED,
					"no violent ejection off the wall (peak %.1f m/s)"
					% _worst_speed)
			_check(_worst_ang < SANE_ANGULAR,
					"no spin freak-out at the wall (peak %.1f rad/s)"
					% _worst_ang)
			_check(_late_speed < _worst_speed,
					"ragdoll settles after the impact (peak %.1f -> late %.1f m/s)"
					% [_worst_speed, _late_speed])
			return _finish()
	return false


func _static_box(pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	body.add_child(cs)
	body.position = pos
	root.add_child(body)


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
