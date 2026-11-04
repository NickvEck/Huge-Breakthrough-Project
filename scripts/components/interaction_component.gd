# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
# interaction_component.gd
## finds the closest [InteractableThing] in range and runs it on interact press.
## if the thing has [member InteractableThing.locks_player], the lock lasts until
## [method InteractableThing.run] returns. nothing new starts while one is running.
## the lock is owned here, not by the state chart: movement and sanity listen to
## [signal interact_started] / [signal interact_ended] and [member is_locked].
## dependencies (input, state_chart, interact_area, body) are injected by the body.
class_name InteractionComponent
extends Component

signal interacted(target: InteractableThing)
signal interact_started
signal interact_ended

@export var interact_radius: float = 2.0

var input_component: InputComponent
var state_chart: StateChart
var interact_area: Area3D
var body: Node3D

var is_locked: bool = false

var _busy: bool = false


func _physics_process(_delta: float) -> void:
	if is_locked or _busy or not input_component or not body:
		return
	if input_component.get_frame().interact_pressed:
		_interact()


func _on_setup() -> void:
	var missing: PackedStringArray = PackedStringArray()
	if not body:
		missing.append("body")
	if not input_component:
		missing.append("input_component")
	if not state_chart:
		missing.append("state_chart")
	if not missing.is_empty():
		push_error("%s: missing required dependencies: %s" % [name, ", ".join(missing)])
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
	interacted.emit(target)
	await target.run(body)
	# wait phusics frame or two, wait out so it doesn't start the interaction again and i get stuck i gojos infinity domain
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
	for node: Node in get_tree().get_nodes_in_group(&"interactable"):
		var candidate := node as InteractableThing
		if not candidate or not candidate.enabled:
			continue
		var dist_sq: float = origin.distance_squared_to(candidate.global_position)
		if dist_sq <= closest_dist_sq:
			closest_dist_sq = dist_sq
			closest = candidate
	return closest
#endregion


#region Lock
func _set_locked(value: bool) -> void:
	is_locked = value
	if value:
		interact_started.emit()
	else:
		interact_ended.emit()
#endregion
