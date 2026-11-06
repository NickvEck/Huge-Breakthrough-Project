# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
## Base class for everything that lives on a character as a component.
## Extend it instead of [Node] to get the [method _on_ready] and [method _on_setup] hooks.
##
## The body (the ancestor that owns the components) injects dependencies in its
## [method Node._enter_tree]. That runs top-down, so they are set in both hooks.
## Dependencies are plain typed fields, not [code]@export[/code]. The body holds the exports
## and assigns them once, see [PlayerBody]. Check them in [method _on_setup].
##
## [method _on_setup] is deferred, so every sibling has finished [method Node._ready] by then.
## @warning: The hooks are not chained. Components extending [Component] directly must not
## call [code]super()[/code]. Subclasses of non-leaf components (e.g. [Movement3DComponent])
## must, the parent does real work.
class_name Component
extends Node


## Returns the first descendant of [param root] that is a [param type], or null.
## Pushes a warning when nothing is found and [param warn] is true.
static func find_component(root: Node, type: Variant, warn: bool = false) -> Node:
	for node: Node in root.find_children("*", "", true, false):
		if is_instance_of(node, type):
			return node
	if warn:
		push_warning("%s: no %s found." % [root.name, type])
	return null


func _ready() -> void:
	_on_ready()
	call_deferred("_on_setup")


func _on_ready() -> void:
	pass


func _on_setup() -> void:
	pass


# Pushes one error naming every null dependency ({ "label": value }).
# Returns true when all are set, so the caller can bail out.
func _require(deps: Dictionary) -> bool:
	var missing: PackedStringArray = PackedStringArray()
	for dep_name: String in deps:
		if not deps[dep_name]:
			missing.append(dep_name)
	if not missing.is_empty():
		push_error("%s: missing required dependencies: %s" % [name, ", ".join(missing)])
	return missing.is_empty()
