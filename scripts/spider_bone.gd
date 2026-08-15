class_name SpiderBone
extends RigidBody3D
## One physics bone of the spider's leg (STO-ENEMIES-055), which knows
## when something has hit it (STO-ENEMIES-056).
##
## > "make it so if anything colides with the spiders legs then it
## > stumbles" — operator, 2026-08-15
##
## The whole difficulty is telling a KNOCK from the floor. A spider's
## feet are in contact with the ground every moment it is standing, so
## "did something touch a leg?" answers yes forever and would leave it
## stumbling permanently.
##
## The contact NORMAL settles it. Standing on the floor pushes a leg
## straight up; walking into a wall pushes it sideways. So a contact
## whose normal is mostly vertical is the ground holding the creature
## up, and a contact whose normal is mostly horizontal is something
## getting in its way. One measurement, no list of what counts as a
## floor — the same shape as the clamber rule (STO-ENEMIES-027), which
## is the rule in this project that has held up best.

## How horizontal a contact has to be before it counts as a knock. 0.6
## leaves a wide band of slopes reading as ground, which is the safe
## way round: a false stumble is far more annoying than a missed one.
const SIDEWAYS := 0.6
## How hard the contact has to be. Brushing past a wall is not a knock;
## walking into one is. Measured as how fast the bone was travelling
## into the surface.
## Lowered from 1.1: a leg PRESSED against a wall by a walking
## creature is barely moving into it, and that is the commonest way a
## leg gets caught. At 1.1 only a leg swung hard into something counted,
## which made tripping a coin flip on where the gait happened to be.
const KNOCK_SPEED := 0.55

## Bodies that are part of this same spider, which must never count.
var kin: Array = []
## Is this the bottom segment of a leg?
##
## Feet are excluded from knocks entirely, and the contact normal alone
## was not enough to do it. A foot pressed into the floor by the leg
## drive penetrates slightly, and the solver then expels it through
## whichever face is nearest — which for a buried capsule is often a
## SIDE face. So the ground kept reporting itself as a wall with a
## perfectly horizontal normal.
##
## Excluding feet is also the more honest reading of what was asked. A
## foot on the floor is not "something colliding with its legs"; a crate
## catching it mid-shin is. The upper and lower segments are 68% of the
## leg and are what an obstacle actually fouls.
var is_foot := false

var _knocks := 0
var _hardest := 0.0


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if is_foot:
		return
	for i in state.get_contact_count():
		var other := state.get_contact_collider_object(i)
		if other == null or kin.has(other):
			continue
		# Turned into WORLD space before being judged.
		#
		# get_contact_local_normal is in this body's own frame, and
		# these bones are rotated to lie along a leg — so the ground's
		# straight-up normal arrives here pointing sideways, and the
		# floor was reporting itself as an obstacle four times a walk.
		var n: Vector3 = (state.transform.basis * \
				state.get_contact_local_normal(i)).normalized()
		if absf(n.y) > SIDEWAYS:
			continue                    # the floor holding us up
		# How fast this bone was going INTO the thing it hit.
		var into: float = -state.linear_velocity.dot(n)
		if into < KNOCK_SPEED:
			continue                    # a brush, not a knock
		_knocks += 1
		_hardest = maxf(_hardest, into)


## How many knocks since anyone last asked, and how hard the worst was.
## Reading clears them, so one knock cannot be counted twice.
func take_knocks() -> float:
	if _knocks == 0:
		return 0.0
	var worst := _hardest
	_knocks = 0
	_hardest = 0.0
	return worst
