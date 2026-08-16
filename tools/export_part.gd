extends SceneTree
## Exports a code-built part into an editable scene (STO-TOOLS-011).
##   godot --headless --path . -s res://tools/export_part.gd
##
## This is the anti-blank-page tool. Its whole job is to make sure that
## when the operator first opens `scenes/parts/claw.tscn` in Godot, the
## claw THEY designed is already sitting in it, ready to be dragged —
## rather than an empty scene they have to build from nothing.
##
## It works by building the part with the real game code and packing
## the result, rather than by writing a .tscn by hand. That matters:
## a hand-written scene is a SECOND description of the shape, and two
## descriptions drift. Packing what the game actually built means the
## exported file is the claw, not somebody's copy of it.
##
## Run once. After STO-TOOLS-011 the game loads the file instead of
## building prongs, so re-running this simply round-trips the file —
## harmless, but it no longer captures anything new.
##
## What is deliberately NOT exported: the `Touch` collision areas. They
## are regenerated from the meshes on load, so the operator sees six
## clean nodes per prong instead of twelve, and a block they add later
## becomes solid without them adding anything.

const OUT_DIR := "res://scenes/parts/"

## The one the operator edits, and the never-edited copy used when
## theirs is broken or missing (STO-TOOLS-013).
const LIVE := "claw.tscn"
const BACKUP := "claw_default.tscn"


var _arms: Node3D


## Built on the first frame, not in `_initialize`: a node added to the
## SceneTree root before the tree is running does not get `_ready`
## until the first frame, so exporting immediately packs an empty hand
## and reports success.
func _initialize() -> void:
	var arms_script: GDScript = load("res://scripts/mechanical_arms.gd")
	_arms = arms_script.new()
	_arms.name = "MechanicalArms"
	_arms.set("claw_mode", true)

	# MechanicalArms._ready() reads its parent as the player. A bare
	# Node3D is enough — nothing in the build path needs a real one.
	var host := Node3D.new()
	host.name = "Host"
	root.add_child(host)
	host.add_child(_arms)


func _process(_delta: float) -> bool:
	var fingers: Node3D = _arms.call("fingers_root", 0)
	if fingers == null:
		push_error("[EXPORT] no Fingers node — nothing to export")
		quit(1)
		return true

	var packed := _pack(fingers)
	if packed == null:
		quit(1)
		return true

	var err_live := ResourceSaver.save(packed, OUT_DIR + LIVE)
	var err_back := ResourceSaver.save(packed, OUT_DIR + BACKUP)
	if err_live != OK or err_back != OK:
		push_error("[EXPORT] save failed: %d / %d" % [err_live, err_back])
		quit(1)
		return true

	print("[EXPORT] wrote %s and %s" % [OUT_DIR + LIVE, OUT_DIR + BACKUP])
	quit(0)
	return true


## Copy the live node tree into a standalone, saveable scene.
func _pack(fingers: Node3D) -> PackedScene:
	var copy := fingers.duplicate() as Node3D
	copy.name = "Fingers"
	# The live node is scaled/positioned by the hand that owns it. The
	# FILE should be the shape at rest, with the hand's own placement
	# left to the game.
	copy.transform = Transform3D.IDENTITY

	_strip_collision(copy)
	_straighten(copy)

	var kept := 0
	for child in copy.get_children():
		kept += 1
	if kept == 0:
		push_error("[EXPORT] the part is empty")
		return null

	# PackedScene only saves nodes that have an owner. Everything below
	# the root has to be claimed by it, or the file comes out as a
	# single empty node — which looks like it worked.
	_claim(copy, copy)

	var packed := PackedScene.new()
	if packed.pack(copy) != OK:
		push_error("[EXPORT] pack failed")
		return null

	print("[EXPORT] packed %d prongs, %d nodes total"
			% [kept, _count(copy)])
	return packed


## Drop the code-made `Touch` areas. They come back on load, generated
## from whatever meshes are in the file — including new ones.
func _strip_collision(node: Node) -> void:
	for child in node.get_children():
		if child is Area3D or child is CollisionShape3D:
			node.remove_child(child)
			child.queue_free()
		else:
			_strip_collision(child)


## Undo the resting curl before saving.
##
## A live claw is always mid-pose: the curl driver sets `rotation.x` on
## every J-joint each frame, and at rest that is about 8 degrees. Packed
## as-is, the file would show a slightly-clenched claw and — worse —
## invite the operator to model a bend on an axis the game overwrites
## before they ever see it.
##
## So x is zeroed on the joints, and only on the joints. The prong ROOTS
## keep theirs: that is the inward flare, which nothing drives and the
## operator should absolutely be able to drag.
func _straighten(node: Node) -> void:
	for child in node.get_children():
		var nm := String(child.name)
		if child is Node3D and nm.length() == 2 and nm.begins_with("J") \
				and nm[1].is_valid_int():
			(child as Node3D).rotation.x = 0.0
		_straighten(child)


func _claim(node: Node, owner_node: Node) -> void:
	for child in node.get_children():
		child.owner = owner_node
		_claim(child, owner_node)


func _count(node: Node) -> int:
	var n := 1
	for child in node.get_children():
		n += _count(child)
	return n
