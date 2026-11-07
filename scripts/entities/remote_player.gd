# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
## Another player, shown from a net_player row. Display only, no physics or input.
## Expects an [AnimatedSprite3D] child whose animations match [Animations].
class_name RemotePlayer
extends Node3D

## Seconds to ease toward the latest position. Keep it above the send interval of
## [NetSyncComponent] or motion stutters between updates.
@export var smoothing: float = 0.15

var _sprite: AnimatedSprite3D
var _target: Vector3
var _placed: bool = false


func _ready() -> void:
	_sprite = Component.find_component(self, AnimatedSprite3D, true) as AnimatedSprite3D


func _process(delta: float) -> void:
	global_position = global_position.lerp(_target, 1.0 - exp(-delta / smoothing))


## Applies the latest row. The first call snaps to the position instead of easing from the origin.
func apply(row: FaerieNetPlayer) -> void:
	_target = Vector3(row.x, row.y, row.z)
	if not _placed:
		global_position = _target
		_placed = true
	_sprite.flip_h = row.flip
	if _sprite.animation == row.animation:
		return
	if not _sprite.sprite_frames.has_animation(row.animation):
		push_error("%s: no animation '%s'" % [name, row.animation])
		return
	_sprite.play(row.animation)
