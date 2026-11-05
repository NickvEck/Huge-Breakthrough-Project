# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
## tracks which way the character faces as a [Vector2].
## feed it with [method update] every frame.
## [signal flipped] only fires on x, y is tracked but turning up/down isn't a "flip".
class_name FacingComponent
extends Component

signal flipped(new_facing_x: float)

@export var default_facing_right: bool = true

var facing: Vector2


## [param direction] is the raw input, a zero axis keeps the old facing on that axis.
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
