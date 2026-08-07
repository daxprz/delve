extends Node
## The sound bus (STO-CHARACTER-050).
##
## Anything noisy — a gunshot, a punch landing, a pounce, a body
## hitting the floor — reports it here, and everyone hears it. The
## Sniper turns that into something it can SEE; nobody else uses it
## yet, which is fine: the bus does not care who is listening.
##
## Crucially this is BROADCAST, so the other players' actions are
## audible to a Sniper on a different machine. Movement already
## replicates through position sync, but a punch is an event: without
## this, a Sniper would be deaf to everything its friends did.

signal sound_made(position: Vector3, loudness: float)

## Rough loudness for common events. 1.0 is "a solid thump".
const FOOTFALL := 0.5
const PUNCH := 1.4
const RAGDOLL_LANDING := 1.2
const POUNCE := 1.1
const GUNSHOT := 4.0


## Report a noise at a world position. Call this from anywhere.
func make(position: Vector3, loudness := 1.0) -> void:
	_hear(position, loudness)
	# Tell the other machines, so their Snipers hear it too.
	if multiplayer.multiplayer_peer != null \
			and multiplayer.multiplayer_peer is not OfflineMultiplayerPeer \
			and multiplayer.has_multiplayer_peer():
		_remote_sound.rpc(position, loudness)


@rpc("any_peer", "call_remote", "unreliable")
func _remote_sound(position: Vector3, loudness: float) -> void:
	_hear(position, loudness)


func _hear(position: Vector3, loudness: float) -> void:
	sound_made.emit(position, maxf(loudness, 0.05))
