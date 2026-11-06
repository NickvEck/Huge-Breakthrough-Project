# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
## Anything the player can interact with: a tree, a box, a person.
## [method run] gives [member item] (if any), shows [member dialogue] (if any) and
## returns when it ends, so the caller can hold the interact lock for the whole interaction.
## When blocked (missing [member requires_item], missing [member requires_flag] or
## no room) nothing is given and the thing stays.
class_name InteractableThing
extends Node3D

## Emitted when blocked. [param reason] is [code]&"requires"[/code],
## [code]&"requires_flag"[/code] or [code]&"full"[/code].
signal blocked(by: Node, reason: StringName)

## Group every thing joins. [InteractionComponent] scans it.
const GROUP: StringName = &"interactable"

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
## [param by] needs an [InventoryComponent] if [member item] or [member requires_item] is set.
func run(by: Node) -> void:
	if not enabled or _running:
		return
	var player := by as PlayerBody
	if (item or requires_item) and not (player and player.inventory):
		push_error("%s: item/requires_item set but %s has no inventory" % [name, by.name])
		return
	if requires_flag != "" and not (player and player.get_flag(requires_flag)):
		await _block(by, &"requires_flag")
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


# Scene path of the level this was placed in. Falls back to the current level
# when there is no owner (added from code).
func _level_path() -> String:
	return owner.scene_file_path if owner else GameState.get_current_level_path()
