# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
## Reads keyboard, mouse and controller into an [InputFrame].
## Presses and releases come from input events and are latched. Held state is polled.
## Side effect: adds the parent to the "player" group.
class_name PlayerInputComponent
extends InputComponent

var _jump_pressed: bool = false
var _jump_released: bool = false
var _dash_pressed: bool = false
var _interact_pressed: bool = false


# Drops edges nobody asked for, so a press is seen by one physics frame only.
# Without this, a press during an interaction lock would fire after it.
func _physics_process(_delta: float) -> void:
	_jump_pressed = false
	_jump_released = false
	_dash_pressed = false
	_interact_pressed = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"jump"):
		_jump_pressed = true
	elif event.is_action_released(&"jump"):
		_jump_released = true
	elif event.is_action_pressed(&"dash"):
		_dash_pressed = true
	elif event.is_action_pressed(&"interact"):
		_interact_pressed = true


func _on_ready() -> void:
	get_parent().add_to_group(&"player")
	# Runs after every consumer of the frame.
	process_physics_priority = 100


func _build_frame() -> InputFrame:
	var frame := InputFrame.new()
	# Held state stays polled. Tracking it from events desyncs when UI consumes a release.
	frame.move = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	frame.run = Input.is_action_pressed(&"run")
	frame.crouch = Input.is_action_pressed(&"crouch")
	frame.jump_pressed = _jump_pressed
	frame.jump_released = _jump_released
	frame.dash_pressed = _dash_pressed
	frame.interact_pressed = _interact_pressed
	return frame
