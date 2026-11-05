# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
# interactable_thing.gd
## anything the player can interact with: a tree, a box, a person.
## [method run] gives [member item] (if any), shows [member dialogue] (if any) and
## returns when it ends, so the caller can hold the interact lock for the whole interaction.
## no room for the item = nothing happens and the thing stays.
class_name InteractableThing
extends Node3D

signal interacted(by: Node)

@export var enabled: bool = true
@export var animate_on_interact: bool = false
## frees the node after the interaction ended (pickups).
@export var free_after: bool = false
## freezes the player until the interaction ended. off = player can keep moving (signs, barks).
@export var locks_player: bool = true
@export var sprite: AnimatedSprite3D
@export_group("Pickup")
@export var item: ItemData
@export var item_count: int = 1
@export_group("Dialogue")
@export var dialogue: DialogueResource
@export var dialogue_cue: String = "start"

var _running: bool = false


func _ready() -> void:
	add_to_group(&"interactable")
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
	if item and player and player.inventory and not player.inventory.add(item, item_count):
		return
	_running = true
	if animate_on_interact and sprite:
		sprite.play()
	interacted.emit(by)
	if dialogue:
		DialogueManager.show_dialogue_balloon(dialogue, dialogue_cue, [by])
		await DialogueManager.dialogue_ended
	_running = false
	if free_after:
		queue_free()
