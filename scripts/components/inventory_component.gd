# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
## The player's inventory, [ItemData] to count. A stack of [member ItemData.max_stack]
## takes one slot, [member max_slots] limits the slots used in total.
## Dependencies (body, optional sanity) are injected by the body.
class_name InventoryComponent
extends Component

## Emitted after an item was added.
signal item_added(item: ItemData, count: int)
## Emitted when [method add] found no room.
signal add_failed(item: ItemData)

@export var max_slots: int = 8
## Prints inventory changes. Testing only.
@export var debug: bool = true

var sanity: SanityComponent
var body: Node
## Item to count. Read only, change it through [method add] and [method remove].
var items: Dictionary[ItemData, int] = { }

# Item use dialogues are skipped while another dialogue is open.
var _in_dialogue: bool = false


## True if at least [param count] of [param item] are carried.
func has(item: ItemData, count: int = 1) -> bool:
	return item != null and items.get(item, 0) >= count


func slots_used() -> int:
	var used: int = 0
	for item: ItemData in items:
		used += _slots_for(item, items[item])
	return used


## True if [param count] more of [param item] fit in the free slots.
func can_carry(item: ItemData, count: int = 1) -> bool:
	var have: int = items.get(item, 0)
	var extra: int = _slots_for(item, have + count) - _slots_for(item, have)
	return slots_used() + extra <= max_slots


## All or nothing. Returns false when there is no room and nothing was added.
func add(item: ItemData, count: int = 1) -> bool:
	if not item:
		return false
	if not can_carry(item, count):
		_log("no room for %s" % _id(item))
		add_failed.emit(item)
		return false
	items[item] = items.get(item, 0) + count
	_log("+%d %s" % [count, _id(item)])
	item_added.emit(item, count)
	return true


## Returns false when fewer than [param count] are carried and nothing was removed.
func remove(item: ItemData, count: int = 1) -> bool:
	if not has(item, count):
		return false
	items[item] -= count
	if items[item] <= 0:
		items.erase(item)
	_log("-%d %s" % [count, _id(item)])
	return true


## Applies the item's effects and consumes it if [member ItemData.consumed_on_use].
## Its use dialogue only shows when no dialogue is open.
## Returns false if the item is not carried.
func use(item: ItemData) -> bool:
	if not has(item):
		return false
	_log("used %s" % _id(item))
	if sanity and item.sanity_restore != 0.0:
		sanity.add(item.sanity_restore)
	if item.consumed_on_use:
		remove(item)
	if item.use_dialogue and not _in_dialogue:
		DialogueManager.show_dialogue_balloon(item.use_dialogue, item.use_dialogue_cue, [body])
	return true


func _on_ready() -> void:
	DialogueManager.dialogue_started.connect(
		func(_r: DialogueResource) -> void:
			_in_dialogue = true,
	)
	DialogueManager.dialogue_ended.connect(
		func(_r: DialogueResource) -> void:
			_in_dialogue = false,
	)


func _on_setup() -> void:
	_require({ "body": body })


func _log(message: String) -> void:
	if debug:
		print("[inv] %s (slots %d/%d)" % [message, slots_used(), max_slots])


# The id is the .tres file name, same as in .dialogue files.
func _id(item: ItemData) -> String:
	return item.resource_path.get_file().get_basename()


func _slots_for(item: ItemData, count: int) -> int:
	return ceili(float(count) / item.max_stack)
