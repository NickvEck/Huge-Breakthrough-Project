# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
## The sanity meter. Changes through [method add] or a flat [member drain_per_second].
## Drain pauses during interaction (interact_component is injected by the body).
class_name SanityComponent
extends Component

## Emitted on every change.
signal changed(value: float, ratio: float)
## Emitted when the ratio crosses one of [member thresholds], up or down.
signal zone_changed(zone: int)
## Emitted when the value hits 0.
signal depleted

@export var max_sanity: float = 100.0
## 0 = no drain.
@export var drain_per_second: float = 0.0
## Ratios (0 to 1, ascending) that split the meter into zones.
@export var thresholds: PackedFloat32Array = PackedFloat32Array([0.25, 0.5, 0.75])

var interact_component: InteractionComponent

var value: float
## Number of [member thresholds] the ratio is at or above. 0 = lowest zone.
var zone: int = 0


func _physics_process(delta: float) -> void:
	if drain_per_second <= 0.0:
		return
	if interact_component and interact_component.is_locked:
		return
	add(-drain_per_second * delta)


## Returns value / max_sanity, from 0 to 1.
func get_ratio() -> float:
	return value / max_sanity


## Adds [param amount] (negative drains), clamped to 0 and [member max_sanity].
func add(amount: float) -> void:
	set_value(value + amount)


func set_value(new_value: float) -> void:
	new_value = clampf(new_value, 0.0, max_sanity)
	if is_equal_approx(new_value, value):
		return
	value = new_value
	changed.emit(value, get_ratio())

	var new_zone: int = _zone_for(get_ratio())
	if new_zone != zone:
		zone = new_zone
		zone_changed.emit(zone)

	if value <= 0.0:
		depleted.emit()


func _on_ready() -> void:
	value = max_sanity
	zone = _zone_for(get_ratio())


func _zone_for(ratio: float) -> int:
	var count: int = 0
	for threshold: float in thresholds:
		if ratio >= threshold:
			count += 1
	return count
