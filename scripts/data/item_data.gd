# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
## one kind of item, saved as a .tres in [constant DIR]. the id is the file name,
## that is what .dialogue files use: [code]give_item("apple")[/code].
class_name ItemData
extends Resource

const DIR: String = "res://scenes/items/"

@export var display_name: String = ""
@export_multiline var description: String = ""
## 1 = does not stack.
@export_range(1, 99, 1) var max_stack: int = 1
@export var consumed_on_use: bool = true
@export var sanity_restore: float = 0.0
@export_group("Use")
## shown when the item is used outside a dialogue (not nested inside one).
@export var use_dialogue: DialogueResource
@export var use_dialogue_cue: String = "start"


## loads the item with this id, or pushes an error and returns null.
static func load_id(id: String) -> ItemData:
	var path: String = "%s%s.tres" % [DIR, id]
	if not ResourceLoader.exists(path):
		push_error("no item '%s', expected %s" % [id, path])
		return null
	return load(path) as ItemData
