# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
## Anything the player can interact with: a tree, a box, a person.
## [method run] gives [member item] (if any), shows [member dialogue] (if any) and
## returns when it ends, so the caller can hold the interact lock for the whole interaction.
## When blocked (missing [member requires_item], missing [member requires_flag] or
## no room) nothing is given and the thing stays.
class_name InteractableThing
extends Node3D

## Emitted when blocked. [param reason] is [constant REQUIRES_ITEM], [constant REQUIRES_FLAG]
## or [constant FULL].
signal blocked(by: Node, reason: StringName)

## Group every thing joins. [InteractionComponent] scans it.
const GROUP: StringName = &"interactable"
const REQUIRES_ITEM: StringName = &"requires_item"
const REQUIRES_FLAG: StringName = &"requires_flag"
const FULL: StringName = &"full"

@export var enabled: bool = true
## Plays [member sprite] on interact, paused otherwise.
@export var animate_on_interact: bool = false
## Frees the node after the interaction ended (pickups).
@export var free_after: bool = false
## Freezes the player until the interaction ended. Off = player keeps moving (signs, barks).
@export var locks_player: bool = true
## With [member free_after]: once freed it stays gone, saved per level in [LevelState].
## Must be unique within the level.
@export var persistent_id: String = ""
## Defaults to the first [AnimatedSprite3D] child when [member animate_on_interact] is set.
@export var sprite: AnimatedSprite3D
@export_group("Pickup")
@export var item: ItemData
@export var item_count: int = 1
## Nothing is given until the player carries this. It is not taken away.
@export var requires_item: ItemData
## Nothing runs until this flag is set, see [method PlayerBody.set_flag].
## Checked before [member requires_item].
@export var requires_flag: String = ""
## Runs when the player walks into [member auto_radius] instead of on interact press.
## Never locks, so give it no dialogue.
@export var auto: bool = false
@export var auto_radius: float = 1.0
@export_group("Dialogue")
@export var dialogue: DialogueResource
@export var dialogue_cue: String = "start"
## Cue shown when blocked. Needs [member dialogue], ignored for [member auto]. Empty = silent.
@export var blocked_cue: String = ""

var _running: bool = false


func _ready() -> void:
	if auto and dialogue:
		push_error("%s: auto things must not have a dialogue" % name)
	if persistent_id != "" and not free_after:
		push_warning("%s: persistent_id does nothing without free_after" % name)
	# Already taken in an earlier visit. Gone before it joins the group.
	if free_after and persistent_id != "" and GameState.get_level_flag(_level_path(), _done_key()):
		queue_free()
		return
	add_to_group(GROUP)
	if not animate_on_interact:
		return
	if not sprite:
		sprite = Component.find_component(self, AnimatedSprite3D, true) as AnimatedSprite3D
	if sprite:
		sprite.pause()


## Runs the interaction for [param by] and returns when it ends.
## [param by] is duck typed. It needs [code]get_flag[/code] if [member requires_flag] is set,
## [code]has_item[/code] if [member requires_item] is set and [code]give_item[/code] if
## [member item] is set, see the dialogue API of [PlayerBody].
func run(by: Node) -> void:
	if not enabled or _running:
		return
	if not _has_api(by):
		return
	if requires_flag != "" and not by.get_flag(requires_flag):
		await _block(by, REQUIRES_FLAG)
		return
	if requires_item and not by.has_item(requires_item.id()):
		await _block(by, REQUIRES_ITEM)
		return
	if item and not by.give_item(item.id(), item_count):
		await _block(by, FULL)
		return
	_running = true
	if animate_on_interact and sprite:
		sprite.play()
	if dialogue:
		DialogueManager.show_dialogue_balloon(dialogue, dialogue_cue, [by])
		await DialogueManager.dialogue_ended
	_running = false
	if free_after:
		if persistent_id != "":
			GameState.set_level_flag(_level_path(), _done_key())
		queue_free()


# Only the methods this thing actually calls are required of [param by].
func _has_api(by: Node) -> bool:
	var needed: Array[StringName] = []
	if requires_flag != "":
		needed.append(&"get_flag")
	if requires_item:
		needed.append(&"has_item")
	if item:
		needed.append(&"give_item")
	for method: StringName in needed:
		if not by.has_method(method):
			push_error("%s: %s has no %s()" % [name, by.name, method])
			return false
	return true


func _block(by: Node, reason: StringName) -> void:
	print("[thing] %s blocked: %s" % [name, reason])
	blocked.emit(by, reason)
	if auto or not dialogue or blocked_cue == "":
		return
	_running = true
	DialogueManager.show_dialogue_balloon(dialogue, blocked_cue, [by])
	await DialogueManager.dialogue_ended
	_running = false


func _done_key() -> String:
	return "thing." + persistent_id


# Scene path of the level this was placed in. Falls back to the current level
# when there is no owner (added from code).
# The topmost owner, not the direct one: inside an instanced prefab the direct
# owner is the prefab root, which would share the flag across every level.
func _level_path() -> String:
	if not owner:
		return GameState.get_current_level_path()
	var level: Node = owner
	while level.owner:
		level = level.owner
	return level.scene_file_path
