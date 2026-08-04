extends SceneTree
## Headless smoke test for EPI-CHARACTER-CHARACTER-SELECT
## (STO-CHARACTER-004/005/006). Run with:
##   godot --headless -s res://tests/smoke_characters.gd
##
## Verifies:
##   - the character registry has >= 2 characters with valid defs
##   - a player spawned as "grabber" HAS arms; as "runner" has NO arms
##     and moves faster (a distinct new character)
##   - the main scene builds a character-select screen (one button each)
## Prints PASS/FAIL lines; exits non-zero on any FAIL.

const CharacterDB := preload("res://scripts/characters.gd")

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


func _run() -> void:
	# --- Registry ---
	if CharacterDB.count() >= 2:
		_pass("registry has %d characters" % CharacterDB.count())
	else:
		_fail("registry has < 2 characters")
	var d0: Dictionary = CharacterDB.get_def(0)
	var ok := true
	for k in ["id", "name", "color", "speed", "jump", "arms", "double_jump"]:
		if not d0.has(k):
			ok = false
			_fail("character def missing key '%s'" % k)
	if ok:
		_pass("character defs have all expected fields")

	# --- Grabber (index 0): has arms ---
	CharacterDB.selected_index = 0
	var g: Node = load("res://scenes/player.tscn").instantiate()
	root.add_child(g)
	var g_speed: float = g.move_speed()
	if g.character_id() == "grabber" and g.get_node_or_null("MechanicalArms") != null:
		_pass("Grabber spawns with mechanical arms (speed %.1f)" % g_speed)
	else:
		_fail("Grabber wrong (id=%s arms=%s)"
				% [g.character_id(), g.get_node_or_null("MechanicalArms") != null])
	g.free()

	# --- Runner (index 1): no arms, walks like the Grabber, sprints faster,
	# wall-jumps instead of double-jumps ---
	CharacterDB.selected_index = 1
	var r: Node = load("res://scenes/player.tscn").instantiate()
	root.add_child(r)
	var r_speed: float = r.move_speed()
	var r_sprint: float = r.sprint_speed()
	if r.character_id() == "runner" and r.get_node_or_null("MechanicalArms") == null:
		_pass("Runner spawns with NO arms (a distinct new character)")
	else:
		_fail("Runner wrong (id=%s arms=%s)"
				% [r.character_id(), r.get_node_or_null("MechanicalArms") != null])
	if is_equal_approx(r_speed, g_speed):
		_pass("Runner walks the same as the Grabber (%.1f)" % r_speed)
	else:
		_fail("Runner walk speed differs (%.1f vs %.1f)" % [r_speed, g_speed])
	if r_sprint > r_speed:
		_pass("Runner sprints faster with Shift (%.1f -> %.1f)" % [r_speed, r_sprint])
	else:
		_fail("Runner sprint not faster (%.1f)" % r_sprint)
	if r.has_wall_jump() and not r.has_double_jump():
		_pass("Runner wall-jumps instead of double-jumping")
	else:
		_fail("Runner jump abilities wrong (wall=%s double=%s)"
				% [r.has_wall_jump(), r.has_double_jump()])
	r.free()

	# --- Select screen ---
	CharacterDB.selected_index = 0
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var b0 := main.find_child("Char0", true, false)
	var b1 := main.find_child("Char1", true, false)
	if b0 != null and b1 != null:
		_pass("character-select screen has a button per character")
	else:
		_fail("select screen missing character buttons (Char0=%s Char1=%s)"
				% [b0 != null, b1 != null])
	main.free()


func _pass(msg: String) -> void:
	print("PASS: %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
