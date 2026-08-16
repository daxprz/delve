extends SceneTree
## Smoke tests for STO-TOOLS-011 (parts live in files) and
## STO-TOOLS-013 (it says what is wrong, in words).
##   godot --headless -s res://tests/smoke_part_model.gd
##
## `smoke_claw` already checks the claw's SHAPE — four prongs, four
## corners, two blocks, slim, bent like `<`. It passes unchanged across
## this switch, which is the proof that moving the shape into a file
## did not move the shape.
##
## But it would pass just as happily if the file were never read at
## all: it inspects the finished claw, and a claw still built from
## constants looks identical. So this file asks the question
## `smoke_claw` structurally cannot:
##
##   **Does the game actually follow the file?**
##
## It answers it the only way that counts — by CHANGING the file and
## checking the game changed with it. Every other check here would
## pass with the loading half unimplemented.
##
## Runs offline — no port, so it works while the game is open.
##
## Safety: this test rewrites `scenes/parts/claw.tscn` and restores it
## on the way out. If it is ever killed mid-run, `claw_default.tscn`
## next to it is the pristine copy — `cp claw_default.tscn claw.tscn`.

const CHARS := preload("res://scripts/characters.gd")
const PartModel := preload("res://scripts/part_model.gd")

const CLAW_FILE := "res://scenes/parts/claw.tscn"
const BACKUP_FILE := "res://scenes/parts/claw_default.tscn"

## A length no constant in the codebase has ever produced, so finding
## it in the game can only mean the file was read.
const ODD_LENGTH := 0.7371

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _original: String
var _spawned := 0
var _big: Node3D


## Spawn a fresh Grabber and hand back its claw's prong root.
##
## A NEW one each time on purpose: the point of most of these phases is
## what happens at build time, and reusing a Grabber built before the
## file changed would test nothing.
func _spawn_grabber() -> Node3D:
	_spawned += 1
	var nm := str(_spawned)
	for i in int(CHARS.count()):
		if String(CHARS.get_def(i)["id"]) == "grabber":
			CHARS.selected_index = i
	_main.call("_spawn_player", _spawned)
	var me := _main.get_node_or_null("Players/" + nm)
	if me == null:
		return null
	var arms := me.get_node_or_null("MechanicalArms")
	if arms == null:
		return null
	return arms.call("fingers_root", 0) as Node3D


## The length of a prong's first block, as the game built it.
func _base_len(fingers: Node3D) -> float:
	if fingers == null or fingers.get_child_count() == 0:
		return -1.0
	var prong := fingers.get_child(0) as Node3D
	var seg := prong.get_node_or_null("J0/Seg") as MeshInstance3D
	if seg == null or not (seg.mesh is BoxMesh):
		return -1.0
	return (seg.mesh as BoxMesh).size.z


## Write a modified copy of the claw over the operator's file, the way
## an outside program would.
##
## `mutate` receives the instantiated root and changes it in place.
##
## The two-step save copies raw bytes over the claw with FileAccess
## rather than pointing `ResourceSaver` at it directly, because a direct
## save also updates Godot's in-memory resource cache — which is not
## what happens in play. The operator saves from the Godot EDITOR, a
## separate process that cannot touch a running game's cache, so the
## test should not either.
##
## Worth recording that this did NOT turn out to matter: sabotaging
## PartModel to use a plain cached `load()` passed under both the direct
## save and this byte copy. Nothing retains the PackedScene, so the
## cache entry is freed and the file is re-read regardless. The byte
## copy is kept because it is the honest simulation of the real
## workflow, not because it caught anything.
func _rewrite(mutate: Callable) -> bool:
	var scene: PackedScene = ResourceLoader.load(
			BACKUP_FILE, "PackedScene", ResourceLoader.CACHE_MODE_REPLACE)
	if scene == null:
		return false
	var root := scene.instantiate() as Node3D
	mutate.call(root)
	_claim(root, root)
	var packed := PackedScene.new()
	if packed.pack(root) != OK:
		return false

	var scratch := "user://part_test_scratch.tscn"
	if ResourceSaver.save(packed, scratch) != OK:
		return false
	var src := FileAccess.open(scratch, FileAccess.READ)
	if src == null:
		return false
	var text := src.get_as_text()
	src.close()
	var dst := FileAccess.open(CLAW_FILE, FileAccess.WRITE)
	if dst == null:
		return false
	dst.store_string(text)
	dst.close()
	return true


func _claim(node: Node, owner_node: Node) -> void:
	for child in node.get_children():
		child.owner = owner_node
		_claim(child, owner_node)


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks == 1:
				# Keep the operator's file verbatim so it goes back
				# byte-for-byte, not regenerated-and-hopefully-the-same.
				var f := FileAccess.open(CLAW_FILE, FileAccess.READ)
				_check(f != null, "the modelled claw file exists")
				if f == null:
					return _finish()
				_original = f.get_as_text()
				f.close()
				_main = load("res://scenes/main.tscn").instantiate()
				root.add_child(_main)
				return false
			if _ticks < 10:
				return false
			_main.call("_begin_game")
			return false if _ticks < 30 else _next("matches_the_file")

		"matches_the_file":
			# The claw in the game is the claw in the file.
			var fingers := _spawn_grabber()
			_check(fingers != null, "a Grabber with a claw")
			if fingers == null:
				return _finish()

			var from_file := (ResourceLoader.load(CLAW_FILE) as PackedScene) \
					.instantiate() as Node3D
			_check(fingers.get_child_count() == from_file.get_child_count(),
					"the game has as many prongs as the file does (%d vs %d)"
					% [fingers.get_child_count(), from_file.get_child_count()])

			# Compare where every prong sits, not just how many. A count
			# would match between two completely different claws.
			var worst := 0.0
			for i in mini(fingers.get_child_count(),
					from_file.get_child_count()):
				var a := fingers.get_child(i) as Node3D
				var b := from_file.get_child(i) as Node3D
				worst = maxf(worst, a.position.distance_to(b.position))
			print("[MODEL] furthest a prong sits from where the file puts "
					+ "it: %.6f m" % worst)
			_check(worst < 0.0005,
					"every prong is exactly where the file puts it (%.6f m "
					% worst + "out)")
			from_file.queue_free()
			_next("follows_an_edit")

		"follows_an_edit":
			# THE check. Change the file; the game must change too.
			if _ticks == 1:
				var before := _base_len(_spawn_grabber())
				_check(before > 0.0, "the claw's base block has a length")
				_check(not is_equal_approx(before, ODD_LENGTH),
						"and it is not already the odd length we are about "
						+ "to set (%.4f)" % before)
				var ok := _rewrite(func(r: Node3D) -> void:
					for prong in r.get_children():
						var seg := prong.get_node_or_null("J0/Seg") \
								as MeshInstance3D
						if seg != null and seg.mesh is BoxMesh:
							var m := (seg.mesh as BoxMesh).duplicate()
							m.size.z = ODD_LENGTH
							seg.mesh = m)
				_check(ok, "the claw file can be rewritten")
				print("[MODEL] base block was %.4f m; file now says %.4f m"
						% [before, ODD_LENGTH])
				return false
			if _ticks < 5:
				return false
			var after := _base_len(_spawn_grabber())
			print("[MODEL] a Grabber built after the edit has %.4f m" % after)
			# If this fails, the game is still building the claw in code
			# and the file is decoration.
			_check(is_equal_approx(after, ODD_LENGTH),
					"the game FOLLOWS THE FILE — changing it changed the "
					+ "claw (%.4f m)" % after)
			_next("broken_model")

		"broken_model":
			# STO-TOOLS-013. Rename J0, the single most likely mistake:
			# "J0" is a programmer's name and "Base" is what a person
			# would call it.
			if _ticks == 1:
				PartModel.clear_messages()
				var ok := _rewrite(func(r: Node3D) -> void:
					var first := r.get_child(0) as Node3D
					first.get_node("J0").name = "Base")
				_check(ok, "a deliberately broken claw file can be written")
				return false
			if _ticks < 5:
				return false
			var fingers := _spawn_grabber()
			var msg := String(PartModel.last_message())
			print("[MODEL] it said:\n%s" % msg)

			# 1. It survived.
			_check(fingers != null and fingers.get_child_count() == 4,
					"a broken model does NOT leave the Grabber without a "
					+ "claw — it still has %d prongs"
					% (fingers.get_child_count() if fingers != null else 0))
			# 2. It said something.
			_check(msg != "", "and it does not fail silently")
			# 3. It said something USEFUL. Each of these is a separate
			#    question the operator would otherwise have to ask.
			_check(msg.contains("claw.tscn"),
					"the message names the file to open")
			_check(msg.contains("J0"),
					"and names what it could not find")
			_check(msg.contains("ProngTL"),
					"and where it was looking")
			_check(msg.contains("claw_default"),
					"and says what it used instead, so the operator knows "
					+ "the game is not broken")
			_check(msg.to_lower().contains("untouched")
					or msg.to_lower().contains("your file"),
					"and that their own file was not overwritten")
			_next("missing_model")

		"missing_model":
			# Deleting the file outright must also be survivable.
			if _ticks == 1:
				PartModel.clear_messages()
				DirAccess.remove_absolute(
						ProjectSettings.globalize_path(CLAW_FILE))
				return false
			if _ticks < 5:
				return false
			var fingers := _spawn_grabber()
			print("[MODEL] with the file deleted: %s"
					% String(PartModel.last_message()))
			_check(fingers != null and fingers.get_child_count() == 4,
					"deleting the claw file entirely still leaves a working "
					+ "claw")
			_next("quiet_when_fine")

		"quiet_when_fine":
			# A warning that always appears is a warning nobody reads.
			if _ticks == 1:
				_restore()
				PartModel.clear_messages()
				return false
			if _ticks < 5:
				return false
			var fingers := _spawn_grabber()
			var msg := String(PartModel.last_message())
			_check(fingers != null and fingers.get_child_count() == 4,
					"the restored claw loads")
			_check(msg == "",
					"and a model that is FINE says nothing at all (said: "
					+ "%s)" % msg)
			_next("scales_up")

		"scales_up":
			# A modelled part is ONE fixed size, but the Grabber's arms
			# scale. The eight deleted constants each got multiplied by
			# `arm_scale`; that is now a single scale on the loaded root.
			#
			# Worth testing precisely because nothing in delve currently
			# sets arm_scale to anything but 1.0 — so this line would
			# never be exercised in play, and would rot silently until
			# the day someone built a bigger Grabber.
			if _ticks == 1:
				_big = load("res://scripts/mechanical_arms.gd").new()
				_big.name = "BigArms"
				_big.set("claw_mode", true)
				_big.set("arm_scale", 2.0)
				var host := Node3D.new()
				host.name = "BigHost"
				_main.add_child(host)
				host.add_child(_big)
				return false
			if _ticks < 10:
				return false
			var big: Node3D = _big.call("fingers_root", 0)
			_check(big != null, "a double-size Grabber has a claw too")
			if big == null:
				return _finish()
			var normal := _spawn_grabber()
			var a := _reach(normal)
			var b := _reach(big)
			print("[MODEL] prong reach at scale 1.0: %.4f m, at scale 2.0: "
					% a + "%.4f m (ratio %.3f)" % [b, b / a if a > 0.0 else 0.0])
			_check(a > 0.0 and is_equal_approx(b / a, 2.0),
					"a claw at scale 2.0 is exactly twice the size — one "
					+ "scale replaced eight multiplications (ratio %.3f)"
					% (b / a if a > 0.0 else 0.0))
			return _finish()
	return false


## How far the first prong is planted from the claw's own centre, in
## real metres — local position times the scale applied to the root.
##
## Measured at the PRONG ROOT, not at its tip. The tip is below `J0`,
## whose `rotation.x` the curl driver owns, so a tip measurement is
## partly a measurement of how clenched the claw happens to be — two
## claws built a few frames apart are at different curls. That is what
## the first version of this check did, and it reported a ratio of
## 2.118 for a claw that is exactly twice the size.
##
## The prong root sits above the curl joint and is placed purely by the
## file, so it is a size and nothing else.
func _reach(fingers: Node3D) -> float:
	if fingers == null or fingers.get_child_count() == 0:
		return -1.0
	var prong := fingers.get_child(0) as Node3D
	return prong.position.length() * fingers.scale.x


## Put the operator's file back exactly as it was.
func _restore() -> void:
	if _original == "":
		return
	var f := FileAccess.open(CLAW_FILE, FileAccess.WRITE)
	if f == null:
		push_error("[MODEL] COULD NOT RESTORE %s — copy %s over it"
				% [CLAW_FILE, BACKUP_FILE])
		return
	f.store_string(_original)
	f.close()


func _next(phase: String) -> bool:
	_phase = phase
	_ticks = 0
	return false


func _finish() -> bool:
	# Always, on every exit path — a test that leaves the operator's
	# claw mangled is worse than no test.
	_restore()
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: %s" % label)
	else:
		_failures += 1
		print("FAIL: %s" % label)
