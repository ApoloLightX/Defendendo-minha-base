extends Node

signal data_changed

const SAVE_PATH := "user://aetherfall_save.json"

var data: Dictionary = {}

func _ready() -> void:
	data = _default_data()
	_load()

func _default_data() -> Dictionary:
	return {
		"gold": 760,
		"crystals": 12,
		"unlocked_stages": [1],
		"stage_stars": {},
		"unlocked_heroes": ["kael", "lyra"],
		"owned_skins": [],
		"owned_effects": [],
		"equipped_skin": "default",
		"equipped_effect": "default",
		"research": {},
		"base_bonus": 0,
		"claimed_missions": [],
		"achievements": [],
		"tutorial_seen": false,
		"stats": {
			"kills": 0,
			"abilities": 0,
			"bosses": 0,
			"perfect_wins": 0,
			"lightning_kills": 0,
			"wins": 0,
			"tower_types": 0,
			"tower_type_list": [],
			"towers_built": 0
		},
		"settings": {
			"music": 0.6,
			"sfx": 0.8,
			"ambient": 0.4,
			"reduced_motion": false,
			"high_contrast": false
		}
	}

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		commit()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		commit()
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_merge_data(parsed)
	commit()

func _merge_data(incoming: Dictionary) -> void:
	for key in incoming.keys():
		if key == "stats" or key == "settings":
			if incoming[key] is Dictionary:
				for nested_key in incoming[key].keys():
					data[key][nested_key] = incoming[key][nested_key]
		elif data.has(key):
			data[key] = incoming[key]

func commit() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
	data_changed.emit()

func reset_progress() -> void:
	data = _default_data()
	commit()

func add_gold(amount: int) -> void:
	data["gold"] = maxi(0, int(data.get("gold", 0)) + amount)
	commit()

func add_crystals(amount: int) -> void:
	data["crystals"] = maxi(0, int(data.get("crystals", 0)) + amount)
	commit()

func increment_stat(stat: String, amount: int = 1) -> void:
	data["stats"][stat] = int(data["stats"].get(stat, 0)) + amount

func record_tower_type(tower_id: String) -> bool:
	var types: Array = data["stats"].get("tower_type_list", [])
	if types.has(tower_id):
		return false
	types.append(tower_id)
	data["stats"]["tower_type_list"] = types
	data["stats"]["tower_types"] = types.size()
	return true

func has_hero(hero_id: String) -> bool:
	return data["unlocked_heroes"].has(hero_id)

func unlock_hero(hero_id: String) -> void:
	if not data["unlocked_heroes"].has(hero_id):
		data["unlocked_heroes"].append(hero_id)

func is_stage_unlocked(stage_id: int) -> bool:
	if data["unlocked_stages"].has(stage_id):
		return true
	if stage_id <= 1:
		return stage_id == 1
	var world: int = int((stage_id - 1) / 5)
	var local: int = (stage_id - 1) % 5
	if local == 0 and world > 0:
		return world_stars(world - 1) >= 10
	return int(data["stage_stars"].get(str(stage_id - 1), 0)) >= 1

func world_stars(world: int) -> int:
	var total := 0
	for local in range(5):
		total += int(data["stage_stars"].get(str(world * 5 + local + 1), 0))
	return total

func total_stars() -> int:
	var total := 0
	for value in data["stage_stars"].values():
		total += int(value)
	return total

func complete_stage(stage_id: int, stars: int, world: int) -> void:
	var key := str(stage_id)
	data["stage_stars"][key] = maxi(int(data["stage_stars"].get(key, 0)), stars)
	var next_stage := stage_id + 1
	var can_unlock_next := stage_id % 5 != 0 or world_stars(world) >= 10
	if next_stage <= 25 and can_unlock_next and not data["unlocked_stages"].has(next_stage):
		data["unlocked_stages"].append(next_stage)

func mission_claimed(mission_id: String) -> bool:
	return data["claimed_missions"].has(mission_id)

func claim_mission(mission_id: String) -> void:
	if not data["claimed_missions"].has(mission_id):
		data["claimed_missions"].append(mission_id)

func setting(key: String, fallback = null):
	return data["settings"].get(key, fallback)
