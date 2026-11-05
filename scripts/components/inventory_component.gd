# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
# inventory_component.gd
## the player's inventory, [ItemData] -> count. a stack of [member ItemData.max_stack]
## takes one slot, [member max_slots] limits the slots used in total.
## dependencies (sanity) are injected by the body.
class_name InventoryComponent
extends Component

signal item_added(item: ItemData, count: int)
signal add_failed(item: ItemData)
signal item_used(item: ItemData)
signal item_consumed(item: ItemData)

@export var max_slots: int = 8

@export var debug: bool = true

var sanity: SanityComponent
var items: Dictionary[ItemData, int] = { }


func has(item: ItemData, count: int = 1) -> bool:
	return item != null and items.get(item, 0) >= count


func slots_used() -> int:
	var used: int = 0
	for item: ItemData in items:
		used += _slots_for(item, items[item])
	return used


func can_carry(item: ItemData, count: int = 1) -> bool:
	var have: int = items.get(item, 0)
	var extra: int = _slots_for(item, have + count) - _slots_for(item, have)
	return slots_used() + extra <= max_slots


## all or nothing. false = no room, nothing was added.
func add(item: ItemData, count: int = 1) -> bool:
	if not item:
		return false
	if not can_carry(item, count):
		add_failed.emit(item)
		return false
	items[item] = items.get(item, 0) + count
	item_added.emit(item, count)
	return true


func remove(item: ItemData, count: int = 1) -> bool:
	if not has(item, count):
		return false
	items[item] -= count
	if items[item] <= 0:
		items.erase(item)
	return true


func use(item: ItemData) -> bool:
	if not has(item):
		return false
	if sanity and item.sanity_restore != 0.0:
		sanity.add(item.sanity_restore)
	item_used.emit(item)
	if item.consumed_on_use:
		remove(item)
		item_consumed.emit(item)
	return true


func _on_ready() -> void:
	if not debug:
		return
	item_added.connect(
		func(item: ItemData, count: int) -> void:
			print("[inv] +%d %s (slots %d/%d)" % [count, item.resource_path.get_basename().get_file(), slots_used(), max_slots]),
	)
	add_failed.connect(
		func(item: ItemData) -> void:
			print("[inv] no room for %s (slots %d/%d)" % [item.resource_path.get_basename().get_file(), slots_used(), max_slots]),
	)
	item_used.connect(
		func(item: ItemData) -> void:
			print("[inv] used %s" % item.resource_path.get_basename().get_file()),
	)
	item_consumed.connect(
		func(item: ItemData) -> void:
			print("[inv] %s consumed, %d left" % [item.resource_path.get_basename().get_file(), items.get(item, 0)]),
	)
	if sanity:
		sanity.changed.connect(
			func(value: float, _ratio: float) -> void:
				print("[sanity] %.1f" % value),
		)


func _slots_for(item: ItemData, count: int) -> int:
	return ceili(float(count) / item.max_stack)
