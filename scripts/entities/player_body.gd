# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
## Owns every component on the player [CharacterBody3D] and wires their dependencies
## in [method Node._enter_tree]. This is the only wiring site, components never look up
## their siblings themselves.
##
## Exports win over auto-resolution: a component or node dragged into an inspector slot
## is used, otherwise the body finds the first child of that type.
## [MovementProfile] is a [Resource] and cannot be found in the tree, so a fresh
## instance is used when none is exported.
class_name PlayerBody
extends CharacterBody3D

@export_group("Components")
@export var input: InputComponent
@export var facing: FacingComponent
@export var movement: Movement3DComponent
@export var interaction: InteractionComponent
@export var animation: AnimationComponent
@export var sanity: SanityComponent
@export var inventory: InventoryComponent
@export var net_sync: NetSyncComponent
@export_group("Data")
@export var movement_profile: MovementProfile

@export_group("Scene Nodes")
@export var sprite: AnimatedSprite3D
@export var collision_shape: CollisionShape3D
@export var state_chart: StateChart


func _enter_tree() -> void:
	_wire_components()


func _wire_components() -> void:
	input = _pick(input, InputComponent)
	facing = _pick(facing, FacingComponent)
	movement = _pick(movement, Movement3DComponent)
	interaction = _pick(interaction, InteractionComponent)
	animation = _pick(animation, AnimationComponent)
	sanity = _pick(sanity, SanityComponent)
	inventory = _pick(inventory, InventoryComponent)
	net_sync = _pick(net_sync, NetSyncComponent)
	sprite = _pick(sprite, AnimatedSprite3D)
	collision_shape = _pick(collision_shape, CollisionShape3D)
	state_chart = _pick(state_chart, StateChart)

	if not movement_profile:
		movement_profile = MovementProfile.new()

	if sanity:
		sanity.interact_component = interaction
	if inventory:
		inventory.sanity = sanity
		inventory.body = self
	if movement:
		movement.body = self
		movement.profile = movement_profile
		movement.input_component = input
		movement.facing_component = facing
		movement.interact_component = interaction
		movement.collision_shape = collision_shape
		movement.state_chart = state_chart
	if interaction:
		interaction.body = self
		interaction.input_component = input
		interaction.state_chart = state_chart
	if animation:
		animation.sprite = sprite
		animation.movement = movement
		animation.facing = facing
	if net_sync:
		net_sync.body = self
		net_sync.sprite = sprite


# The export if set, otherwise the first child of [param type].
func _pick(current: Node, type: Variant) -> Node:
	return current if current else Component.find_component(self, type)


#region Dialogue API
# Called from .dialogue files, the body is passed in as extra game state.
# Items are ids, see [method ItemData.load_id]. All of these need an [InventoryComponent].
## Gives the item. Returns false if there is no room.
func give_item(id: String, count: int = 1) -> bool:
	return inventory.add(ItemData.load_id(id), count)


func remove_item(id: String, count: int = 1) -> bool:
	return inventory.remove(ItemData.load_id(id), count)


func has_item(id: String, count: int = 1) -> bool:
	return inventory.has(ItemData.load_id(id), count)


func use_item(id: String) -> bool:
	return inventory.use(ItemData.load_id(id))


## Does nothing without a [SanityComponent].
func sanity_add(amount: float) -> void:
	if sanity:
		sanity.add(amount)
#endregion


#region Flags
# Per-level flags for dialogue consequences and quest state. Keys are strings,
# writers use a prefix: "quest.", "favor.", "sanctuary.". Called from .dialogue
# files as set_flag("favor.bread") and if get_flag("favor.bread").
# @warning: requires a game state, see [GameState]. A scene run directly from
# the editor has none and these are no-ops.
## Returns the flag, false when unset.
func get_flag(flag: String) -> bool:
	return GameState.get_level_flag(GameState.get_current_level_path(), flag)


## Sets the flag. See [method GameState.set_level_flag].
func set_flag(flag: String, value: bool = true) -> void:
	GameState.set_level_flag(GameState.get_current_level_path(), flag, value)
#endregion
