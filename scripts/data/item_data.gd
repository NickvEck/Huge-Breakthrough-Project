# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
## One kind of item, saved as a .tres in [constant DIR]. The id is the file name,
## which is what .dialogue files use: [code]give_item("apple")[/code].
class_name ItemData
extends Resource

const DIR: String = "res://scenes/items/"

@export var display_name: String = ""
@export_multiline var description: String = ""
## 1 = does not stack.
@export_range(1, 99, 1) var max_stack: int = 1
@export var consumed_on_use: bool = true
## Added to sanity on use. Negative drains.
@export var sanity_restore: float = 0.0
@export_group("Use")
## Shown when the item is used outside a dialogue.
@export var use_dialogue: DialogueResource
@export var use_dialogue_cue: String = "start"


## Loads the item with this id. Pushes an error and returns null if it does not exist.
static func load_id(id: String) -> ItemData:
	var path: String = "%s%s.tres" % [DIR, id]
	if not ResourceLoader.exists(path):
		push_error("no item '%s', expected %s" % [id, path])
		return null
	return load(path) as ItemData


## The id .dialogue files and [method PlayerBody.give_item] use: the file name without extension.
func id() -> String:
	return resource_path.get_file().get_basename()
