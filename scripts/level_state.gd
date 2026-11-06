# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
## Saved data for one level, see [GameState].
class_name LevelState
extends Resource

@export var color: Color
@export var tutorial_read: bool = false
## Per-level flags, e.g. "thing.box_01" for a pickup that is gone for good.
@export var flags: Dictionary = { }
