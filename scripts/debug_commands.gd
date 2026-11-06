# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
## Debug commands for [LimboConsole]. Autoload.
## The player is resolved per command, not cached, so respawns and scene
## transitions do not leave a stale [PlayerBody] behind.
##
## [LimboConsole] silently fails to register a bare callable, the command name
## must be passed as the second argument even when the function name matches.
extends Node

const PLAYER_GROUP: StringName = &"player"


func _ready() -> void:
	LimboConsole.register_command(give_item, "give", "Gives an item. Usage: give <item_id> <count>")
	LimboConsole.register_command(set_sanity, "sanity", "Sets the player's sanity. Usage: sanity <value>")
	LimboConsole.add_argument_autocomplete_source("give", 0, _item_ids)


#region Commands
## Gives [param count] of the item with [param id]. The id is the .tres file name,
## same as in .dialogue files, see [method ItemData.load_id].
func give_item(id: String, count: int = 1) -> void:
	var player: PlayerBody = _player()
	if not player or not player.inventory:
		LimboConsole.error("no player inventory")
		return
	var item: ItemData = ItemData.load_id(id)
	if not item:
		LimboConsole.error("unknown item '%s'" % id)
		return
	if player.inventory.add(item, count):
		LimboConsole.info("+%d %s" % [count, id])
	else:
		LimboConsole.error("no room for %d %s" % [count, id])


## Sets the sanity meter to [param value], clamped to [member SanityComponent.max_sanity].
func set_sanity(value: float) -> void:
	var player: PlayerBody = _player()
	if not player or not player.sanity:
		LimboConsole.error("no player sanity")
		return
	player.sanity.set_value(value)
	LimboConsole.info("sanity %.0f/%.0f" % [player.sanity.value, player.sanity.max_sanity])
#endregion


# The "player" group is added by [method PlayerInputComponent._on_ready], so it
# is looked up on demand. A field set in _ready would be null on the first run.
func _player() -> PlayerBody:
	return get_tree().get_first_node_in_group(PLAYER_GROUP) as PlayerBody


# Autocomplete for the give command: every .tres in [constant ItemData.DIR], by id.
func _item_ids() -> Array[String]:
	var ids: Array[String] = []
	var dir: DirAccess = DirAccess.open(ItemData.DIR)
	if not dir:
		return ids
	for file: String in dir.get_files():
		if file.get_extension() == "tres":
			ids.append(file.get_basename())
	return ids
