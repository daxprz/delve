class_name PracticeDummy
extends CharacterBody3D
## A practice dummy (STO-ENEMIES-029): a body that stands in the world
## and counts as a PLAYER for everything that matters, but never moves
## and never fights back.
##
## It exists so that teamwork can be tested by one person. Every story
## in EPI-ENEMIES-SPIDER-TAKES-YOU ends with "...and then someone
## rescues you", and alone there is nobody to be rescued and nobody to
## do the rescuing.
##
## The one decision worth defending: it joins the SAME group as real
## players rather than being its own kind of thing. Enemy targeting,
## damage routing, grabbing and every rescue mechanic still to be
## written then work on it for free. The alternative — teaching each
## system about a second kind of victim — means writing every one of
## those stories twice, and the two copies would drift until the dummy
## stopped being a fair test of the real thing.
##
## It does not move. Not "does not move much": it has no AI at all
## (the operator asked for a thing that just stands there), and the
## only force acting on it is gravity, so it settles onto the floor and
## stays where it was put.

const BodyScript := preload("res://scripts/body.gd")

const MAX_HEALTH := 100.0
## Beaten to nothing, it stands straight back up. It is a practice
## dummy — running out of dummy halfway through practising would be a
## strange way for it to work.
const REVIVE_DELAY := 1.5
## How fast a dummy bleeds while impaled (STO-ENEMIES-050). It cannot
## play the timing game and cannot thrash, so it gets the plain base
## rate — the number a real player would suffer doing nothing at all.
const BLEED_ON_SPIKE := 3.0

var _health := MAX_HEALTH
var _revive := 0.0
var _home := Vector3.ZERO
var _home_set := false
var _body: Node3D


func _ready() -> void:
	# The whole point: to everything else in delve, this IS a player.
	add_to_group("players")
	add_to_group("dummies")

	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.6
	col.shape = cap
	col.position = Vector3(0.0, 0.8, 0.0)
	add_child(col)

	# A person, not a box. Canonical proportions (variation_seed 0),
	# because it stands in for a PLAYER — a randomly-built body would
	# make it a worse stand-in, not a better one.
	_body = BodyScript.new()
	_body.name = "Body"
	_body.set("use_fade", false)
	_body.set("variation_seed", 0)
	_body.set("base_color", Color(0.45, 0.55, 0.75))
	add_child(_body)

	# NOT _home = global_position here. _ready() runs the moment the
	# node enters the tree, which is BEFORE whoever spawned it has
	# applied the spawn point — so the answer here is always the world
	# origin, and reviving would teleport the dummy 5 m across the map
	# to a spot it never stood in. Recorded on the first physics tick
	# instead, by which time it is where it was actually put.


func _physics_process(delta: float) -> void:
	if not _home_set:
		_home_set = true
		_home = global_position
		print("[DUMMY] %s standing at %.1f, %.1f, %.1f"
				% [name, _home.x, _home.y, _home.z])

	# Being taken: the spider owns where we are, so gravity and the
	# floor are not ours to obey. Skipping move_and_slide is what stops
	# the dummy sliding off a spike it has just been put on.
	if _taken_by != null:
		return
	if _spike != null:
		if is_instance_valid(_spike) and _spike.has_method("impale_point"):
			global_position = _spike.call("impale_point")
		# It bleeds like anyone else, and going down releases it —
		# otherwise a dummy left on a spike would revive still pinned to
		# it, alive at full health, forever.
		_health = maxf(0.0, _health - BLEED_ON_SPIKE * delta)
		if _health <= 0.0:
			released()
			_go_down()
		return

	# Gravity only. No steering, no chasing, no input — the operator
	# asked for something that just stands there, and every rescue
	# story is testable against a thing that is merely present and
	# hurtable.
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0
	velocity.x = 0.0
	velocity.z = 0.0
	move_and_slide()

	if _revive > 0.0:
		_revive -= delta
		if _revive <= 0.0:
			_stand_up()


# --- The player-shaped surface everything else already knows ---------

func health() -> float:
	return _health


func max_health() -> float:
	return MAX_HEALTH


func take_damage(amount: float) -> void:
	if _revive > 0.0:
		return  # already down, waiting to get back up
	_health = maxf(0.0, _health - amount)
	DebugOverlay.log("player/combat", self, "%s: -%.1f hp -> %.0f/%.0f",
			[name, amount, _health, MAX_HEALTH])
	if _health <= 0.0:
		_go_down()


## An enemy hit us. Real players route this to the machine that owns
## them, because health is not replicated. The dummy is owned by
## nobody, so it simply takes the hit where it stands.
func hurt_by_enemy(amount: float) -> void:
	take_damage(amount)


# --- Being taken by the spider (STO-ENEMIES-034) ---------------------
#
# The dummy exists so the taking and the rescue can be tried by one
# person at a keyboard, so it has to be grabbable exactly like a real
# player. It has no screen and no timing game — it just gets taken, and
# bleeds on the spike like anybody else.

var _taken_by: Node3D = null
var _spike: Node3D = null


func grabbed_by(spider: Node3D) -> bool:
	if _taken_by != null or _spike != null or _revive > 0.0:
		return false
	_taken_by = spider
	velocity = Vector3.ZERO
	DebugOverlay.log("player/combat", self, "%s: GRABBED by %s",
			[name, spider.name if spider != null else "?"])
	return true


func smashed_down(amount: float) -> void:
	take_damage(amount)


func dragged_to(point: Vector3) -> void:
	global_position = point
	velocity = Vector3.ZERO


func impaled_on(spike: Node3D) -> void:
	_taken_by = null
	_spike = spike
	if spike != null and spike.has_method("impale_point"):
		global_position = spike.call("impale_point")
	DebugOverlay.log("player/combat", self, "%s: IMPALED on %s",
			[name, spike.name if spike != null else "?"])


func released() -> void:
	_taken_by = null
	_spike = null


func is_taken() -> bool:
	return _taken_by != null or _spike != null


func is_impaled() -> bool:
	return _spike != null


func bleed_rate() -> float:
	return BLEED_ON_SPIKE if _spike != null else 0.0


## Tells the rest of delve this is not somebody's actual character —
## for anything that should not happen to a real person, and for tests.
func is_dummy() -> bool:
	return true


func is_down() -> bool:
	return _revive > 0.0


# --- Down and up -----------------------------------------------------

func _go_down() -> void:
	_revive = REVIVE_DELAY
	DebugOverlay.log("player/combat", self, "%s: knocked over", [name])


func _stand_up() -> void:
	_health = MAX_HEALTH
	global_position = _home
	velocity = Vector3.ZERO
	DebugOverlay.log("player/combat", self, "%s: back up, full health", [name])
