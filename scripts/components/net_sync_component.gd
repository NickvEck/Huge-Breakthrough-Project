# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
## Publishes the local player's position, facing and animation through [code]Net[/code].
## Dependencies (body, sprite) are injected by the body.
class_name NetSyncComponent
extends Component

## Seconds between updates.
@export var send_interval: float = 0.1

var body: Node3D
var sprite: AnimatedSprite3D


func _on_setup() -> void:
	if not _require({ "body": body, "sprite": sprite }):
		return
	var timer := Timer.new()
	timer.wait_time = send_interval
	# Sampled in the physics step, where the body has moved.
	timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	timer.autostart = true
	timer.timeout.connect(_send)
	add_child(timer)


func _send() -> void:
	Net.send_state(body.global_position, sprite.flip_h, sprite.animation)
