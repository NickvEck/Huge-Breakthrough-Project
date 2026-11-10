# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
## Saved game data, accessed through the static helpers.
class_name GameState
extends Resource

const STATE_NAME: String = "GameState"
const FILE_PATH = "res://scripts/game_state.gd"

## Level scene path or uid to [LevelState].
@export var level_states: Dictionary[String, LevelState] = { }
@export var current_level_path: String
@export var checkpoint_level_path: String
@export var total_games_played: int
@export var play_time: int
@export var total_time: int


## Returns the saved [LevelState] for a level scene path or uid, or null without a game state.
## A level seen for the first time gets a state created and saved, so a read can write.
static func get_level_state(level_state_key: String) -> LevelState:
	level_state_key = ResourceUID.ensure_path(level_state_key)
	if not has_game_state():
		return
	var game_state := get_or_create_state()
	if level_state_key.is_empty():
		return
	if level_state_key in game_state.level_states:
		return game_state.level_states[level_state_key]
	else:
		var new_level_state := LevelState.new()
		game_state.level_states[level_state_key] = new_level_state
		GlobalState.save()
		return new_level_state


static func has_game_state() -> bool:
	return GlobalState.has_state(STATE_NAME)


static func get_or_create_state() -> GameState:
	return GlobalState.get_or_create_state(STATE_NAME, FILE_PATH)


static func get_current_level_path() -> String:
	if not has_game_state():
		return ""
	var game_state := get_or_create_state()
	return game_state.current_level_path


static func get_checkpoint_level_path() -> String:
	if not has_game_state():
		return ""
	var game_state := get_or_create_state()
	return game_state.checkpoint_level_path


static func get_levels_reached() -> int:
	if not has_game_state():
		return 0
	var game_state := get_or_create_state()
	return game_state.level_states.size()


static func set_checkpoint_level_path(level_path: String) -> void:
	var game_state := get_or_create_state()
	game_state.checkpoint_level_path = level_path
	get_level_state(level_path)
	GlobalState.save()


static func set_current_level_path(level_path: String) -> void:
	var game_state := get_or_create_state()
	game_state.current_level_path = level_path
	GlobalState.save()


static func start_game() -> void:
	var game_state := get_or_create_state()
	game_state.total_games_played += 1
	GlobalState.save()


static func continue_game() -> void:
	var game_state := get_or_create_state()
	game_state.current_level_path = game_state.checkpoint_level_path
	GlobalState.save()


## Wipes level progress and play time. [member total_games_played] is kept.
static func reset() -> void:
	var game_state := get_or_create_state()
	game_state.level_states.clear()
	game_state.current_level_path = ""
	game_state.checkpoint_level_path = ""
	game_state.play_time = 0
	game_state.total_time = 0
	GlobalState.save()


## True if [param flag] was set in that level. Unknown level or flag = false.
## Used for "this pickup is already taken" persistence, see [member InteractableThing.persistent_id].
static func get_level_flag(level_path: String, flag: String) -> bool:
	var level_state := get_level_state(level_path)
	return level_state != null and level_state.flags.get(flag, false)


## Saves immediately. Warns and saves nothing if the level has no state.
static func set_level_flag(level_path: String, flag: String, value: bool = true) -> void:
	var level_state := get_level_state(level_path)
	if not level_state:
		push_warning("no level state for '%s', flag '%s' not saved" % [level_path, flag])
		return
	level_state.flags[flag] = value
	GlobalState.save()
