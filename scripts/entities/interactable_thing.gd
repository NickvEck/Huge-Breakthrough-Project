# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
## anything the player can interact with: a tree, a box, a person.
## [method run] gives [member item] (if any), shows [member dialogue] (if any) and
## returns when it ends, so the caller can hold the interact lock for the whole interaction.
## blocked (missing [member requires_item] or no room) = nothing is given and the thing stays.
class_name InteractableThing
extends Node3D

## [param reason] is [code]&"requires"[/code] or [code]&"full"[/code].
signal blocked(by: Node, reason: StringName)

## group every thing joins, [InteractionComponent] scans it.
const GROUP: StringName = &"interactable"

@export var enabled: bool = true
@export var animate_on_interact: bool = false
## frees the node after the interaction ended (pickups).
@export var free_after: bool = false
## freezes the player until the interaction ended. off = player can keep moving (signs, barks).
@export var locks_player: bool = true
## with [member free_after]: once freed it stays gone (saved per level in [LevelState]).
## must be unique within the level.
@export var persistent_id: String = ""
@export var sprite: AnimatedSprite3D
@export_group("Pickup")
@export var item: ItemData
@export var item_count: int = 1
## not given until the player carries this (it is not taken away).
@export var requires_item: ItemData
## walk over it instead of pressing interact. never locks, so give it no dialogue.
@export var auto: bool = false
@export var auto_radius: float = 1.0
@export_group("Dialogue")
@export var dialogue: DialogueResource
@export var dialogue_cue: String = "start"
## cue shown when blocked (needs [member dialogue], ignored for [member auto]). empty = silent.
@export var blocked_cue: String = ""

var _running: bool = false


func _ready() -> void:
	if auto and dialogue:
		push_error("%s: auto things must not have a dialogue" % name)
	if persistent_id != "" and not free_after:
		push_warning("%s: persistent_id does nothing without free_after" % name)
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


func run(by: Node) -> void:
	if not enabled or _running:
		return
	var player := by as PlayerBody
	if (item or requires_item) and not (player and player.inventory):
		push_error("%s: item/requires_item set but %s has no inventory" % [name, by.name])
		return
	if requires_item and not player.inventory.has(requires_item):
		await _block(by, &"requires")
		return
	if item and not player.inventory.add(item, item_count):
		await _block(by, &"full")
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


## the level scene this thing was placed in (works in any scene, even without the level manager).
func _level_path() -> String:
	return owner.scene_file_path if owner else GameState.get_current_level_path()
