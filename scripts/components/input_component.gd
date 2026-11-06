# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
## Base class for input sources. Builds one [InputFrame] per physics frame and caches it,
## so every caller in the same frame gets the same object.
## Override [method _build_frame] for a new source (AI, replay, etc).
class_name InputComponent
extends Component

var _frame: InputFrame
var _frame_index: int = -1


## Returns this physics frame's input. Only call from physics code, the cache is per physics frame.
func get_frame() -> InputFrame:
	var index: int = Engine.get_physics_frames()
	if index != _frame_index:
		_frame_index = index
		_frame = _build_frame()
	return _frame


func _build_frame() -> InputFrame:
	return InputFrame.new()
