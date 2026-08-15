extends SceneTree
## Headless smoke test for STO-CHARACTER-012 (humanoid body).
## Run with:  godot --headless -s res://tests/smoke_body.gd
##
## Verifies the player builds a jointed humanoid body with every named
## joint (head, neck, torso, pelvis, upper/lower arms, hands, thighs,
## shins, feet) parented as a real hierarchy.

const JOINTS := [
	"Pelvis", "Torso", "Neck", "Head",
	"ShoulderL", "UpperArmL", "ForearmL", "HandL",
	"ShoulderR", "UpperArmR", "ForearmR", "HandR",
	"HipL", "ThighL", "ShinL", "FootL",
	"HipR", "ThighR", "ShinR", "FootR",
]

var _failures := 0
var _done := false


func _physics_process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	_run()
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


const CharacterDB := preload("res://scripts/characters.gd")


func _run() -> void:
	# Test the Runner, which has the full set of human arms + legs.
	CharacterDB.selected_index = 1
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.host_game()
	main.start_game()   # the lobby no longer starts the game for you
	var player := main.get_node_or_null("Players/1")
	if player == null:
		_fail("no player")
		return
	# Asked of the player, not found by path: the body hangs off a
	# squash node now so the Mage can be flattened (STO-CHARACTER-079).
	var body: Node = player.call("body_node") \
			if player.has_method("body_node") \
			else player.get_node_or_null("Body")
	if body == null:
		_fail("player has no Body")
		return
	_pass("player built a Body (%d joints)" % body.joint_count())

	var missing := []
	for jname in JOINTS:
		if body.find_child(jname, true, false) == null:
			missing.append(jname)
	if missing.is_empty():
		_pass("all %d named joints exist (head, neck, arms, legs, ...)" % JOINTS.size())
	else:
		_fail("missing joints: %s" % str(missing))

	# The forearm should be a descendant of the upper arm (real hierarchy).
	var upper: Node = body.find_child("UpperArmL", true, false)
	if upper != null and upper.find_child("ForearmL", true, false) != null:
		_pass("joints are a real hierarchy (forearm under upper arm)")
	else:
		_fail("joints are not parented hierarchically")


func _pass(msg: String) -> void:
	print("PASS: %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
