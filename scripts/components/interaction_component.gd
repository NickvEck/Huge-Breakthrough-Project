# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
## Finds the closest [InteractableThing] in range and runs it on interact press.
## Things with [member InteractableThing.auto] run once when the player walks into their
## radius (again after leaving and re-entering) and never lock.
## With [member InteractableThing.locks_player] the lock lasts until [method InteractableThing.run]
## returns. Nothing new starts while one is running.
## The lock lives here, not in the state chart. Movement and sanity listen to
## [signal interact_started], [signal interact_ended] and [member is_locked].
## Dependencies (input_component, state_chart, body) are injected by the body.
class_name InteractionComponent
extends Component

## Emitted when a locking interaction starts.
signal interact_started
## Emitted when a locking interaction ends.
signal interact_ended

## Max distance to a thing for the interact press to pick it.
@export var interact_radius: float = 2.0

var input_component: InputComponent
var state_chart: StateChart
var body: Node3D

## True during a locking interaction.
var is_locked: bool = false

var _busy: bool = false
# Instance ids of auto things the player is standing in. The values are unused,
# a Dictionary gives constant time has and erase.
var _auto_inside: Dictionary[int, bool] = { }


func _physics_process(_delta: float) -> void:
	if is_locked:
		return
	_check_auto()
	if _busy:
		return
	if input_component.get_frame().interact_pressed:
		_interact()


func _on_setup() -> void:
	var deps := { "body": body, "input_component": input_component, "state_chart": state_chart }
	if not _require(deps):
		set_physics_process(false)


#region Interaction
func _interact() -> void:
	var target: InteractableThing = _find_closest()
	if not target:
		return
	var locks: bool = target.locks_player
	_busy = true
	if locks:
		_set_locked(true)
		state_chart.send_event(StateEvents.INTERACT)
	await target.run(body)
	# The press that closed the dialogue can still be latched as a press. Wait it
	# out so it does not restart the interaction.
	await get_tree().physics_frame
	await get_tree().physics_frame
	if locks:
		state_chart.send_event(StateEvents.INTERACT_END)
		_set_locked(false)
	_busy = false


func _find_closest() -> InteractableThing:
	var closest: InteractableThing = null
	var closest_dist_sq: float = interact_radius * interact_radius
	var origin: Vector3 = body.global_position
	for node: Node in get_tree().get_nodes_in_group(InteractableThing.GROUP):
		var candidate := node as InteractableThing
		if not candidate or not candidate.enabled or candidate.auto:
			continue
		var dist_sq: float = origin.distance_squared_to(candidate.global_position)
		if dist_sq <= closest_dist_sq:
			closest_dist_sq = dist_sq
			closest = candidate
	return closest


func _check_auto() -> void:
	var origin: Vector3 = body.global_position
	for node: Node in get_tree().get_nodes_in_group(InteractableThing.GROUP):
		var thing := node as InteractableThing
		if not thing or not thing.enabled or not thing.auto:
			continue
		var id: int = thing.get_instance_id()
		var inside: bool = origin.distance_squared_to(thing.global_position) <= thing.auto_radius * thing.auto_radius
		if inside and not _auto_inside.has(id):
			_auto_inside[id] = true
			# Not awaited, auto things never lock.
			thing.run(body)
		elif not inside:
			_auto_inside.erase(id)
	# Freed things (pickups) leave the group while their id is still in here.
	for id: int in _auto_inside.keys():
		if not is_instance_id_valid(id):
			_auto_inside.erase(id)
#endregion


#region Lock
func _set_locked(value: bool) -> void:
	is_locked = value
	if value:
		interact_started.emit()
	else:
		interact_ended.emit()
#endregion
