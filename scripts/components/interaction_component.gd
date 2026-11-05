# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
## finds the closest [InteractableThing] in range and runs it on interact press.
## things with [member InteractableThing.auto] run once when the player walks into their
## radius (again after leaving and re-entering), without locking.
## if the thing has [member InteractableThing.locks_player], the lock lasts until
## [method InteractableThing.run] returns. nothing new starts while one is running.
## the lock is owned here, not by the state chart: movement and sanity listen to
## [signal interact_started] / [signal interact_ended] and [member is_locked].
## dependencies (input_component, state_chart, body) are injected by the body.
class_name InteractionComponent
extends Component

signal interact_started
signal interact_ended

@export var interact_radius: float = 2.0

var input_component: InputComponent
var state_chart: StateChart
var body: Node3D

var is_locked: bool = false

var _busy: bool = false
## instance ids of auto things the player is currently standing in.
var _auto_inside: Array[int] = []


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
	# the press that closed the dialogue still counts as "just pressed" for a physics
	# frame or two, wait it out so it doesn't start the interaction again.
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
			_auto_inside.append(id)
			thing.run(body)
		elif not inside:
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
