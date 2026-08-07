extends SceneTree
## Headless smoke test for STO-CHARACTER-001 (procedural mechanical
## arms, 3-part anatomy with fists). Run with:
##   godot --headless -s res://tests/smoke_arms.gd
##
## Hosts a game to spawn the player, then verifies the game BUILT two
## arms from code:
##   - the player has a MechanicalArms node with 2 arms
##   - each arm has UpperArm + Forearm + Hand parts
##   - every part carries a mechanical Joint
##   - the hand is a fist (Fist block + knuckles, not claws)
##   - no arm nodes were hand-placed in player.tscn
## Prints one PASS/FAIL line per check; exits non-zero on any FAIL.

var _failures := 0


func _setup() -> bool:
	var packed: PackedScene = load("res://scenes/main.tscn")
	if packed == null:
		_fail("main.tscn failed to load")
		return false
	var main := packed.instantiate()
	root.add_child(main)
	main.host_game()
	main.start_game()   # the lobby no longer starts the game for you

	var player := main.get_node_or_null("Players/1")
	if player == null:
		_fail("no player node at Players/1 after host_game()")
		return false

	# Arms must be built by code, not hand-placed in player.tscn.
	var scene_only: Node = load("res://scenes/player.tscn").instantiate()
	if scene_only.get_node_or_null("MechanicalArms") != null:
		_fail("player.tscn has a hand-placed MechanicalArms node")
	scene_only.free()

	var arms := player.get_node_or_null("MechanicalArms")
	if arms == null:
		_fail("player has no MechanicalArms node after spawn")
		return false
	if arms.arm_count() == 2:
		_pass("game built 2 arms")
	else:
		_fail("expected 2 arms, got %d" % arms.arm_count())

	for arm_name in ["ArmLeft", "ArmRight"]:
		var arm := arms.get_node_or_null(arm_name)
		if arm == null:
			_fail("%s missing" % arm_name)
			continue
		var ok := true
		for part_name in ["UpperArm", "Forearm", "Hand"]:
			var part := arm.get_node_or_null(part_name)
			if part == null or part.get_node_or_null("Joint") == null:
				ok = false
		if ok:
			_pass("%s has UpperArm+Forearm+Hand, each with a Joint" % arm_name)
		else:
			_fail("%s missing a part or Joint" % arm_name)

		# Hand must be a fist: a Fist block + knuckle ridges (no Digits).
		var hand := arm.get_node_or_null("Hand")
		if hand != null:
			var knuckles := 0
			for c in hand.get_children():
				if String(c.name).begins_with("Knuckle"):
					knuckles += 1
			var has_fist := hand.get_node_or_null("Fist") != null
			var no_claws := true
			for c in hand.get_children():
				if String(c.name).begins_with("Digit"):
					no_claws = false
			if has_fist and knuckles >= 3 and no_claws:
				_pass("%s hand is a fist (Fist block + %d knuckles, no claws)"
						% [arm_name, knuckles])
			else:
				_fail("%s hand not a proper fist (fist=%s knuckles=%d claws_gone=%s)"
						% [arm_name, has_fist, knuckles, no_claws])
	return true


func _physics_process(_delta: float) -> bool:
	_setup()
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _pass(msg: String) -> void:
	print("PASS: %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
