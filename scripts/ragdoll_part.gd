extends RigidBody3D
## One ragdoll bone (STO-ENEMIES-010). Clamps its own velocities from
## INSIDE the physics step, via _integrate_forces, so a deep contact
## with thin geometry (procmap walls are 0.3 m thick) can never hand
## the joint solver an absurd velocity. Post-step clamping was too
## late — by then the part had been ejected and the joints yanked.

const MAX_LIN := 18.0    # m/s
const MAX_ANG := 14.0    # rad/s
## Below this depth we let the solver do its job; deeper than this the
## part is inside geometry, so we also bleed speed to settle it.
const DEEP_CONTACT := 0.08


func _ready() -> void:
	# Needed for get_contact_count()/depth queries below.
	contact_monitor = true
	max_contacts_reported = 4


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var lv := state.linear_velocity
	var av := state.angular_velocity

	# Deep penetration (thin wall, corner wedge): kill the energy that
	# would otherwise be released as a violent ejection.
	var deepest := 0.0
	for i in state.get_contact_count():
		deepest = maxf(deepest, -state.get_contact_local_normal(i).dot(
				state.get_contact_local_position(i)
				- state.get_contact_collider_position(i)))
	if state.get_contact_count() > 0 and deepest > DEEP_CONTACT:
		lv *= 0.35
		av *= 0.25

	if lv.length() > MAX_LIN:
		lv = lv.normalized() * MAX_LIN
	if av.length() > MAX_ANG:
		av = av.normalized() * MAX_ANG

	state.linear_velocity = lv
	state.angular_velocity = av
