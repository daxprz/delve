class_name SpiderMind
extends Node
## The giant spider's mind (STO-ENEMIES-038 + EPI-ENEMIES-SPIDER-LEARNS).
##
## ## The honest limit, first
##
## **This is not a brain.** It keeps score and adapts. A creature that
## starts knowing nothing and discovers walking needs neural networks
## and thousands of training runs, which does not fit in delve. What is
## here is bookkeeping and rules — but played against it genuinely gets
## harder, because it really is counting what you do and really is
## changing what it does about it.
##
## Saying that plainly here matters more than it sounds: the operator
## asked for "almost infinite possibilities", and the honest answer is
## that those come from **combining many small behaviours**, not from
## one clever mind. This file is the many small behaviours.
##
## ## What it does
##
## | | |
## |---|---|
## | **Senses** you by sweeping for hitboxes, not by being told (038) |
## | **Remembers** where you were, and hunts that when it loses you (038) |
## | **Practises** its own walk, starting from one that works (043) |
## | **Copes** when hurt or stuck (044) |
## | **Saves** what it knows about you, forever (045) |
## | **Watches** your running, hiding and character (046) |
## | **Chooses** a plan, and sometimes the wrong one (047) |

# --- Senses (STO-ENEMIES-038) ----------------------------------------

## How far it can feel for hitboxes. Big, because it is a big creature
## in an open world — but finite, which is the entire point: it used to
## know where every player was, everywhere, always.
const RADAR_RANGE := 26.0
## How many bodies one sweep may return.
const RADAR_MAX := 24
## Close enough to the remembered place to count as having checked it.
const ARRIVED := 2.5

var _target: Node3D = null
var _last_known := Vector3.ZERO
var _has_trail := false
var _senses := 0                 # sweeps that found something (tests)

# --- Watching you (STO-ENEMIES-046) ----------------------------------

## How often to take a sample of what you are doing, in seconds. Not
## every frame: 60 samples a second of a player standing still would
## drown out the handful of moments they actually did something.
const WATCH_EVERY := 0.25
## Size of a "place" when remembering where you like to be. Coarse on
## purpose — "over by the crates" is a useful thing to know, an exact
## coordinate you stood on once is not.
const PLACE_SIZE := 6.0
## How far ahead to aim when it has learned which way you break.
const LEAD_MAX := 3.5

var _watch_timer := 0.0
var _last_seen_at := Vector3.ZERO
var _have_last_seen := false

# --- Plans (STO-ENEMIES-047) -----------------------------------------

## The plans it can pick between. Deliberately few and readable: a long
## list of near-identical plans would make its choices impossible to
## see, and being able to SEE it commit to something wrong is what
## makes it baitable.
const PLANS: Array = ["charge", "cut_off", "wait", "check_hideout"]
## How often it picks a plan it does not believe in. The operator asked
## for "smart, but makes mistakes" — a monster you cannot fool is not
## frightening, it is unfair. One in six is often enough to be baited
## and rare enough to still read as clever.
const MISTAKE_CHANCE := 0.17
## How strongly a good score pushes the choice. Keeps the preference
## real but never absolute.
const SCORE_WEIGHT := 2.5

var _plan := "charge"
var _mistakes := 0
var _choices := 0

# --- Practising its walk (STO-ENEMIES-043) ---------------------------

## How long each attempt lasts before it judges it.
const TRY_TIME := 4.0
## How big a nudge to try.
const TUNE_STEP := 0.06
## Floor and ceiling on anything it is allowed to tune, as a multiple
## of the gait it was born with. It must never be able to practise
## itself into being unable to walk.
const TUNE_MIN := 0.75
const TUNE_MAX := 1.35

var _gait := 1.0                 # multiplier on its stride
var _gait_best := 1.0
var _best_score := -1.0
var _trying := 0.0
var _distance_this_try := 0.0
var _tries := 0

# --- Coping (STO-ENEMIES-044) ----------------------------------------

## How many ticks of being blocked before it accepts the way it chose
## is not working.
const STUCK_TICKS := 45
var _stuck := 0
var _detour := 0.0               # seconds left going deliberately aside
var _detour_side := 1.0

# --- Memory that survives the game closing (STO-ENEMIES-045) ---------

const MEMORY_FILE := "user://spider_memory.json"

## Everything it knows, per player name. One dictionary so saving is
## one call and there is no chance of half the memory persisting.
var _mem: Dictionary = {}

var _rng := RandomNumberGenerator.new()


func _init(seed_value: int = 1) -> void:
	_rng.seed = seed_value if seed_value != 0 else 1


# --- Sensing ---------------------------------------------------------

## Sweep for anything huntable within reach.
##
## Uses a real shape query against the world rather than a list of
## players, so the spider finds you the same way anything else would —
## by there being a body where it is feeling. Give it an empty world and
## it finds nothing, which is exactly the behaviour that was missing.
func sense(world: World3D, from: Vector3, exclude: RID) -> Node3D:
	var shape := SphereShape3D.new()
	shape.radius = RADAR_RANGE
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.transform = Transform3D(Basis(), from)
	q.collide_with_bodies = true
	q.exclude = [exclude]
	var hits := world.direct_space_state.intersect_shape(q, RADAR_MAX)

	var best: Node3D = null
	var best_d := INF
	for h in hits:
		var n = h.get("collider")
		if n is not Node3D or not (n as Node).is_in_group("players"):
			continue
		var d: float = from.distance_to((n as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = n as Node3D

	if best != null:
		_target = best
		_last_known = best.global_position
		_has_trail = true
		_senses += 1
	else:
		_target = null
	return best


## Where to go when nothing can be sensed: the last place it knew of.
## Returns false once the trail has gone cold.
func hunting_memory() -> bool:
	return _has_trail


func last_known() -> Vector3:
	return _last_known


## Called on arriving at the remembered place and finding nothing.
func trail_cold() -> void:
	_has_trail = false


func senses() -> int:
	return _senses


## Has it arrived where it remembered?
func reached_memory(from: Vector3) -> bool:
	return _has_trail and from.distance_to(_last_known) <= ARRIVED


# --- Watching you (STO-ENEMIES-046) ----------------------------------

## Take note of what a player is doing. Called every frame; samples
## itself down.
func watch(who: Node3D, delta: float, from: Vector3) -> void:
	if who == null or not is_instance_valid(who):
		return
	_watch_timer -= delta
	if _watch_timer > 0.0:
		return
	_watch_timer = WATCH_EVERY

	var key := String(who.name)
	var m: Dictionary = _mem.get(key, _blank())

	# Which character are they playing? Told by asking them, which is
	# something anyone watching could see.
	if who.has_method("character_id"):
		m["character"] = String(who.call("character_id"))

	# Where do they like to be? Coarse buckets, not coordinates.
	var place := _place_key(who.global_position)
	var places: Dictionary = m["places"]
	places[place] = int(places.get(place, 0)) + 1

	# Which way do they break? Measured across the SPIDER'S OWN LINE OF
	# SIGHT, which is the only frame in which the answer is useful to
	# it: "they always go left" only means anything relative to whoever
	# is watching.
	#
	# The first version measured their sideways movement relative to
	# their own direction of travel, which is exactly zero by
	# definition, every time, forever. It learned nothing and reported
	# a confident 0.000.
	if _have_last_seen:
		var moved: Vector3 = who.global_position - _last_seen_at
		moved.y = 0.0
		var to_them: Vector3 = who.global_position - from
		to_them.y = 0.0
		if moved.length() > 0.05 and to_them.length() > 0.5:
			var side := Vector3.UP.cross(to_them.normalized()).normalized()
			m["break_sum"] = float(m["break_sum"]) + moved.dot(side)
			m["break_n"] = int(m["break_n"]) + 1
			m["side"] = [side.x, side.y, side.z]

	# Dodging and blocking: both are things you can watch someone do.
	if who.has_method("is_rolling") and bool(who.call("is_rolling")):
		m["dodges"] = int(m["dodges"]) + 1
	if who.has_method("is_blocking") and bool(who.call("is_blocking")):
		m["blocks"] = int(m["blocks"]) + 1

	m["seen"] = int(m["seen"]) + 1
	_mem[key] = m
	_last_seen_at = who.global_position
	_have_last_seen = true


func _place_key(p: Vector3) -> String:
	return "%d,%d" % [int(floor(p.x / PLACE_SIZE)), int(floor(p.z / PLACE_SIZE))]


func _blank() -> Dictionary:
	return {"places": {}, "break_sum": 0.0, "break_n": 0, "dodges": 0,
			"blocks": 0, "seen": 0, "character": "", "wins": {},
			"side": null}


## Where to aim for a player, given what it has learned about them.
##
## This is the payoff of watching: with nothing learned it returns
## exactly where they are — the old behaviour — and the more it has
## seen you break one way, the further ahead of you it aims. It stops
## chasing and starts cutting you off.
func aim_at(who: Node3D) -> Vector3:
	if who == null or not is_instance_valid(who):
		return Vector3.ZERO
	var here: Vector3 = who.global_position
	var m: Dictionary = _mem.get(String(who.name), {})
	var n: int = int(m.get("break_n", 0))
	if n < 4:
		return here                       # not enough watching yet
	var bias: float = float(m.get("break_sum", 0.0)) / float(n)
	var raw = m.get("side", null)
	if raw is not Array or (raw as Array).size() != 3:
		return here
	var side := Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	var lead: float = clampf(bias * 12.0, -LEAD_MAX, LEAD_MAX)
	return here + side * lead


## Their favourite place, or ZERO if it has not learned one.
func favourite_place(who_name: String) -> Vector3:
	var m: Dictionary = _mem.get(who_name, {})
	var places: Dictionary = m.get("places", {})
	var best := ""
	var best_n := 0
	for k in places:
		if int(places[k]) > best_n:
			best_n = int(places[k])
			best = String(k)
	if best == "":
		return Vector3.ZERO
	var parts := best.split(",")
	return Vector3((float(parts[0]) + 0.5) * PLACE_SIZE, 0.0,
			(float(parts[1]) + 0.5) * PLACE_SIZE)


## How much it knows about somebody, as a plain count of observations.
func knows(who_name: String) -> int:
	return int(_mem.get(who_name, {}).get("seen", 0))


func character_of(who_name: String) -> String:
	return String(_mem.get(who_name, {}).get("character", ""))


func break_bias(who_name: String) -> float:
	var m: Dictionary = _mem.get(who_name, {})
	var n: int = int(m.get("break_n", 0))
	return 0.0 if n == 0 else float(m.get("break_sum", 0.0)) / float(n)


# --- Choosing a plan (STO-ENEMIES-047) -------------------------------

## Pick what to try next against `who`.
##
## Weighted by what has worked on this particular player before — and
## deliberately wrong sometimes, because being baitable is the design,
## not a shortfall of it.
func choose_plan(who_name: String) -> String:
	_choices += 1
	var m: Dictionary = _mem.get(who_name, _blank())
	var wins: Dictionary = m.get("wins", {})

	if _rng.randf() < MISTAKE_CHANCE:
		# A mistake: pick anything at all, including the plan it has the
		# least faith in. This is what makes it possible to bait.
		_mistakes += 1
		_plan = String(PLANS[_rng.randi() % PLANS.size()])
		return _plan

	var total := 0.0
	var weights: Array = []
	for p in PLANS:
		var w: float = 1.0 + maxf(0.0, float(wins.get(p, 0.0))) * SCORE_WEIGHT
		weights.append(w)
		total += w
	var roll := _rng.randf() * total
	for i in PLANS.size():
		roll -= float(weights[i])
		if roll <= 0.0:
			_plan = String(PLANS[i])
			return _plan
	_plan = String(PLANS[0])
	return _plan


## Tell it how that went. Good news raises that plan's score for this
## player; bad news lowers it.
func note_outcome(who_name: String, plan: String, good: bool) -> void:
	var m: Dictionary = _mem.get(who_name, _blank())
	var wins: Dictionary = m.get("wins", {})
	wins[plan] = float(wins.get(plan, 0.0)) + (1.0 if good else -0.6)
	m["wins"] = wins
	_mem[who_name] = m


func plan() -> String:
	return _plan


func mistakes() -> int:
	return _mistakes


func choices() -> int:
	return _choices


func score_for(who_name: String, plan_name: String) -> float:
	return float(_mem.get(who_name, {}).get("wins", {}).get(plan_name, 0.0))


# --- Practising its walk (STO-ENEMIES-043) ---------------------------

## Report how far it travelled this frame. It judges itself on distance
## actually covered, which is the only measure that cannot be faked by
## flailing faster.
##
## Hill-climbing: try a nudge, measure, keep it only if it did better.
## It never starts from nothing — the gait it was born with is the
## first thing it measures itself against, which is exactly the
## operator's "it already existed before the player was there".
func practise(distance: float, delta: float) -> void:
	_distance_this_try += distance
	_trying += delta
	if _trying < TRY_TIME:
		return
	var score := _distance_this_try / _trying
	if score > _best_score:
		_best_score = score
		_gait_best = _gait
	else:
		_gait = _gait_best              # that was worse; go back
	# Try a new nudge, always inside the safe range.
	_gait = clampf(_gait_best + _rng.randf_range(-TUNE_STEP, TUNE_STEP),
			TUNE_MIN, TUNE_MAX)
	_trying = 0.0
	_distance_this_try = 0.0
	_tries += 1


func gait() -> float:
	return _gait


func best_gait() -> float:
	return _gait_best


func tries() -> int:
	return _tries


# --- Coping (STO-ENEMIES-044) ----------------------------------------

## Called every tick with how far it actually got, and whether it was
## TRYING to go anywhere at all. Enough consecutive frames of trying and
## failing, and it stops grinding and takes a different line — which is
## the difference between a creature and a machine pressed against a
## wall.
##
## `trying` is load-bearing, not a nicety. Without it, a spider that has
## deliberately stopped — because it is on top of you, winding up, or
## holding you still to smash you into the ground — counts every one of
## those frames as being stuck, and wanders off mid-grab to "try
## something else". Standing still on purpose is not being stuck.
func note_progress(moved: float, delta: float, trying: bool) -> void:
	if _detour > 0.0:
		_detour -= delta
		return
	if not trying:
		_stuck = 0
		return
	if moved < 0.01:
		_stuck += 1
		if _stuck >= STUCK_TICKS:
			_stuck = 0
			_detour = 1.4
			_detour_side = 1.0 if _rng.randf() < 0.5 else -1.0
	else:
		_stuck = 0


func is_detouring() -> bool:
	return _detour > 0.0


func detour_side() -> float:
	return _detour_side


## How badly hurt it is changes how it moves, not merely how fast: a
## damaged creature goes wider and more carefully.
func caution(legs_left: int, legs_total: int) -> float:
	if legs_total <= 0:
		return 0.0
	return clampf(1.0 - float(legs_left) / float(legs_total), 0.0, 1.0)


# --- Remembering forever (STO-ENEMIES-045) ---------------------------

## Write everything it knows to a file.
func save_memory(path := MEMORY_FILE) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(_mem))
	f.close()
	return true


## Read it back. A missing or corrupt file leaves it blank rather than
## crashing — a creature that cannot start because its diary is damaged
## would be a worse bug than a creature that has forgotten you.
func load_memory(path := MEMORY_FILE) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if parsed is not Dictionary:
		return false
	_mem = parsed
	return true


## Everything it knows, for tests and for the debug overlay.
func memory() -> Dictionary:
	return _mem


func forget_everything() -> void:
	_mem = {}
