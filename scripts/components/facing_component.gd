# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
## Tracks which way the character faces.
## Feed it with [method update] every frame.
class_name FacingComponent
extends Component

## Emitted when the horizontal facing changes. Vertical changes are not a flip.
signal flipped(new_facing_x: float)

## Initial horizontal facing.
@export var default_facing_right: bool = true

## Last non-zero direction per axis. x: -1 left, 1 right. y: -1 up, 1 down.
var facing: Vector2


## [param direction] is the raw input. A zero axis keeps the old facing on that axis.
func update(direction: Vector2) -> void:
	if not is_zero_approx(direction.x):
		var x: float = signf(direction.x)
		if x != facing.x:
			flipped.emit(x)
		facing.x = x
	if not is_zero_approx(direction.y):
		facing.y = signf(direction.y)


func _on_setup() -> void:
	facing = Vector2(1.0 if default_facing_right else -1.0, -1.0)
