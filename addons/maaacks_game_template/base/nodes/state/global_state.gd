class_name GlobalState
extends Node

const NO_VERSION_NAME = "0.0.0"

## Save file path. An extra instance for multiplayer testing passes [code]--save=<name>[/code]
## after [code]--[/code] and gets its own file, because all editor instances share user://.
static var save_state_path : String = _default_save_path()
static var current : GlobalStateData
static var current_version : String

static func _default_save_path() -> String:
	for arg : String in OS.get_cmdline_user_args():
		if arg.begins_with("--save="):
			return "user://global_state_%s.tres" % arg.trim_prefix("--save=")
	return "user://global_state.tres"

static func _log_opened() -> void:
	if current is GlobalStateData:
		current.last_unix_time_opened = int(Time.get_unix_time_from_system())

static func _log_version() -> void:
	if current is GlobalStateData:
		current_version = ProjectSettings.get_setting("application/config/version", NO_VERSION_NAME)
		if current_version.is_empty():
			current_version = NO_VERSION_NAME
		if not current.first_version_opened:
			current.first_version_opened = current_version
		current.last_version_opened = current_version

static func _load_current_state() -> void:
	if FileAccess.file_exists(save_state_path):
		current = ResourceLoader.load(save_state_path)
	if not current:
		current = GlobalStateData.new()

static func open() -> void:
	if current is GlobalStateData:
		return
	_load_current_state()
	_log_opened()
	_log_version()
	save()

static func save() -> void:
	if current is GlobalStateData:
		ResourceSaver.save(current, save_state_path)

static func has_state(state_key : String) -> bool:
	open()
	return current.has_state(state_key)

static func get_or_create_state(state_key : String, state_type_path : String) -> Resource:
	open()
	return current.get_or_create_state(state_key, state_type_path)

static func reset() -> void:
	if current is not GlobalStateData:
		return
	current.states.clear()
	save()
