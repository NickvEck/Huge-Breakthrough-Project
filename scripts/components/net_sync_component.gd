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

var _timer: float = 0.0


func _physics_process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = send_interval
	Net.send_state(body.global_position, sprite.flip_h, sprite.animation)


func _on_setup() -> void:
	if not _require({ "body": body, "sprite": sprite }):
		set_physics_process(false)
