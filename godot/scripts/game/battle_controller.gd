class_name BattleController
extends Node2D
func _art_texture(key: String) -> Texture2D:
	if not art_textures.has(key):
		art_textures[key] = load("res://art/" + key + ".png")
	return art_textures[key]


signal hud_changed(payload: Dictionary)
signal toast_requested(title: String, message: String, tone: String)
signal battle_finished(result: String, payload: Dictionary)

const VIEW_SIZE := Vector2(1280.0, 720.0)
const TAU_VALUE := PI * 2.0
const FIELD_ORIGIN := Vector2(18, 112)
const FIELD_SCALE := Vector2(0.76, 0.66)
const FIELD_RECT := Rect2(18, 112, 972.8, 475.2)
var pending_skill := ""
var cast_target := Vector2(640, 360)
var scheduled_arrows: Array[float] = []

func cancel_command() -> void:
	pending_skill = ""
	build_type = ""
	selected_tower_id = -1
	_emit_hud()
	queue_redraw()

var worlds: Array = []
var terrain_art := TerrainArt.new()
var art_textures: Dictionary = {}
var tower_defs: Dictionary = {}
var enemy_defs: Dictionary = {}
var hero_defs: Dictionary = {}
var boss_defs: Array = []
var difficulties: Dictionary = {}

var active := false
var paused := false
var ended := false
var result := ""
var stage: Dictionary = {}
var difficulty_key := "normal"
var difficulty: Dictionary = {}
var selected_hero_id := "kael"
var path_points: Array[Vector2] = []
var path_lengths: Array[float] = []
var path_total := 1.0
var tower_spots: Array = []
var towers: Array = []
var enemies: Array = []
var projectiles: Array = []
var particles: Array = []
var effects: Array = []
var floating_texts: Array = []
var spawn_queue: Array = []

var wave := 0
var max_waves := 12
var wave_active := false
var spawn_timer := 0.0
var intermission := 0.0
var base_hp := 20.0
var base_max := 20.0
var gold := 330
var selected_tower_id := -1
var build_type := ""
var game_speed := 1.0
var kills := 0
var damage_done := 0.0
var tower_build_count := 0
var boss: Dictionary = {}
var sandstorm_until := 0.0
var reinforce_until := 0.0
var hero: Dictionary = {}
var global_cooldowns := {"meteor": 0.0, "freeze": 0.0, "barrage": 0.0, "reinforce": 0.0}
var game_time := 0.0
var hud_clock := 0.0
var screen_shake := 0.0
var tutorial := false
var tutorial_step := 0
var rng := RandomNumberGenerator.new()
var next_tower_id := 1
var next_enemy_id := 1

func _ready() -> void:
	worlds = GameData.worlds()
	tower_defs = GameData.tower_defs()
	enemy_defs = GameData.enemy_defs()
	hero_defs = GameData.hero_defs()
	boss_defs = GameData.boss_defs()
	difficulties = GameData.difficulties()
	rng.randomize()
	visible = false
	set_process(true)

func _process(delta: float) -> void:
	if not active:
		return
	queue_redraw()
	if paused or ended:
		return
	var scaled_delta := minf(delta, 0.05) * game_speed
	game_time += scaled_delta
	screen_shake = maxf(0.0, screen_shake - scaled_delta * 4.8)
	hud_clock -= scaled_delta
	_update_wave(scaled_delta)
	_update_enemies(scaled_delta)
	_update_towers(scaled_delta)
	_update_hero(scaled_delta)
	_update_projectiles(scaled_delta)
	_update_particles(scaled_delta)
	_update_effects(scaled_delta)
	_update_floating_texts(scaled_delta)
	if hud_clock <= 0.0:
		hud_clock = 0.1
		_emit_hud()

func start_battle(stage_id: int, selected_difficulty: String, hero_id: String) -> void:
	pending_skill = ""
	scheduled_arrows.clear()
	stage = _stage_from_id(stage_id)
	difficulty_key = selected_difficulty if difficulties.has(selected_difficulty) else "normal"
	difficulty = difficulties[difficulty_key]
	selected_hero_id = hero_id if hero_defs.has(hero_id) else "kael"
	active = true
	paused = false
	ended = false
	result = ""
	wave = 0
	max_waves = int(stage["waves"])
	wave_active = false
	spawn_queue.clear()
	spawn_timer = 0.0
	intermission = 0.0
	base_max = float(difficulty["base_hp"]) + int(SaveManager.data.get("base_bonus", 0))
	base_hp = base_max
	gold = 330
	towers.clear()
	enemies.clear()
	projectiles.clear()
	particles.clear()
	effects.clear()
	floating_texts.clear()
	boss.clear()
	sandstorm_until = 0.0
	reinforce_until = 0.0
	selected_tower_id = -1
	build_type = ""
	game_speed = 1.0
	kills = 0
	damage_done = 0.0
	tower_build_count = 0
	game_time = 0.0
	screen_shake = 0.0
	next_tower_id = 1
	next_enemy_id = 1
	path_points = _build_path(int(stage["world"]), int(stage["variant"]))
	_build_path_lengths()
	tower_spots = _build_tower_spots(int(stage["world"]), int(stage["variant"]))
	var hero_def: Dictionary = hero_defs[selected_hero_id]
	terrain_art.prepare(int(stage["world"]), path_points, tower_spots)
	var hero_start := _point_on_path(0.25)
	hero = {"id": selected_hero_id, "level": 1, "xp": 0.0, "next_xp": 100.0, "x": hero_start.x, "y": hero_start.y, "target_x": hero_start.x, "target_y": hero_start.y, "hp": float(hero_def["hp"]), "max_hp": float(hero_def["hp"]), "cooldown": 0.0, "skill_cooldowns": [0.0, 0.0, 0.0], "ultimate": 0.0, "invulnerable": 0.0, "respawn": 0.0, "facing": 1.0, "attack_flash": 0.0}
	global_cooldowns = {"meteor": 0.0, "freeze": 0.0, "barrage": 0.0, "reinforce": 0.0}
	tutorial = stage_id == 1 and not bool(SaveManager.data.get("tutorial_seen", false))
	tutorial_step = 1 if tutorial else 0
	visible = true
	AudioManager.start_music(false)
	_emit_hud()
	queue_redraw()

func stop_battle() -> void:
	active = false
	paused = false
	ended = true
	visible = false
	AudioManager.stop_music()

func stage_data() -> Dictionary:
	return stage.duplicate(true)

func debug_add_gold(amount: int = 1000) -> void:
	if not OS.is_debug_build() or not active:
		return
	gold += amount
	_add_floating_text(640.0, 72.0, "+%d DEV OURO" % amount, Color("#f2bd6b"), 0.9)
	_emit_hud()

func debug_skip_wave() -> void:
	if not OS.is_debug_build() or not active or ended:
		return
	for enemy in enemies:
		enemy["dead"] = true
	spawn_queue.clear()
	wave_active = false
	intermission = 0.0
	if wave >= max_waves:
		_finish_battle("victory")
	else:
		start_next_wave()

func debug_kill_all() -> void:
	if not OS.is_debug_build() or not active or ended:
		return
	for enemy in enemies:
		if not bool(enemy["dead"]):
			_kill_enemy(enemy, "debug", "magic")
	_emit_hud()

func debug_spawn_boss() -> void:
	if not OS.is_debug_build() or not active or ended or not boss.is_empty():
		return
	_spawn_enemy("boss")
	_emit_hud()

func debug_unlock_all() -> void:
	if not OS.is_debug_build():
		return
	var unlocked: Array = []
	for stage_id in range(1, 26):
		unlocked.append(stage_id)
	SaveManager.data["unlocked_stages"] = unlocked
	SaveManager.data["unlocked_heroes"] = ["kael", "lyra", "orion", "volt", "nyx"]
	SaveManager.commit()
	toast_requested.emit("Modo de desenvolvimento", "Campanha e heróis desbloqueados.", "success")

func set_game_speed(value: float) -> void:
	game_speed = clampf(value, 1.0, 3.0)

func set_paused(value: bool) -> void:
	paused = value

func start_next_wave() -> void:
	if not active or ended or paused or wave_active or wave >= max_waves:
		return
	var early := wave > 0 and intermission > 0.2
	wave += 1
	spawn_queue = _create_wave_plan(wave)
	spawn_timer = 0.0
	wave_active = true
	intermission = 0.0
	if early:
		gold += 10
		_add_floating_text(VIEW_SIZE.x - 145.0, 50.0, "+10 ANTECIPAÇÃO", Color("#f2bd6b"), 1.2)
		AudioManager.coin()
	if tutorial and tutorial_step == 2:
		tutorial_step = 3
		toast_requested.emit("O ouro compra tempo", "Use os recursos da onda para melhorar sua formação.", "info")
	AudioManager.wave()
	_emit_hud()

func select_build_type(type_id: String) -> void:
	pending_skill = ""
	if not active or ended:
		return
	if not tower_defs.has(type_id):
		return
	build_type = "" if build_type == type_id else type_id
	selected_tower_id = -1
	_emit_hud()
	queue_redraw()

func select_tower(tower_id: int) -> void:
	if not active:
		return
	selected_tower_id = tower_id
	build_type = ""
	_emit_hud()
	queue_redraw()

func upgrade_selected_tower() -> void:
	var tower := _tower_by_id(selected_tower_id)
	if tower.is_empty() or int(tower["level"]) >= 3:
		return
	var definition: Dictionary = tower_defs[tower["type"]]
	var cost := int(round(float(definition["cost"]) * (0.7 + int(tower["level"]) * 0.52)))
	if gold < cost:
		toast_requested.emit("Ouro insuficiente", "Ainda faltam %d de ouro para este upgrade." % (cost - gold), "error")
		return
	gold -= cost
	tower["level"] = int(tower["level"]) + 1
	tower["invested"] = int(tower["invested"]) + cost
	AudioManager.upgrade()
	_spawn_burst(float(tower["x"]), float(tower["y"]), Color("#" + definition["color"]), 18, 68.0)
	_add_floating_text(float(tower["x"]), float(tower["y"]) - 26.0, "NÍVEL %d" % int(tower["level"]), Color("#75e5ef"), 0.8)
	if tutorial and tutorial_step == 3:
		tutorial_step = 4
		toast_requested.emit("Comando liberado", "Heróis, protocolos globais e especializações estão disponíveis.", "success")
		SaveManager.data["tutorial_seen"] = true
		tutorial = false
		SaveManager.commit()
	_emit_hud()
	queue_redraw()

func specialize_selected_tower(spec_id: String) -> void:
	var tower := _tower_by_id(selected_tower_id)
	if tower.is_empty() or int(tower["level"]) < 3:
		return
	var definition: Dictionary = tower_defs[tower["type"]]
	for branch in definition["branches"]:
		if branch["id"] == spec_id:
			tower["spec"] = spec_id
			AudioManager.upgrade()
			_spawn_burst(float(tower["x"]), float(tower["y"]), Color("#" + definition["color"]), 22, 75.0)
			_add_floating_text(float(tower["x"]), float(tower["y"]) - 28.0, str(branch["name"]).to_upper(), Color("#" + definition["color"]), 1.0)
			_emit_hud()
			queue_redraw()
			return

func sell_selected_tower() -> void:
	var index := _tower_index_by_id(selected_tower_id)
	if index < 0:
		return
	var tower: Dictionary = towers[index]
	var refund := int(round(int(tower["invested"]) * 0.68))
	var spot_index := int(tower["spot_index"])
	if spot_index >= 0 and spot_index < tower_spots.size():
		tower_spots[spot_index]["tower_id"] = -1
	gold += refund
	_spawn_burst(float(tower["x"]), float(tower["y"]), Color("#f2bd6b"), 10, 36.0)
	_add_floating_text(float(tower["x"]), float(tower["y"]) - 22.0, "+%d OURO" % refund, Color("#f2bd6b"), 0.8)
	towers.remove_at(index)
	selected_tower_id = -1
	AudioManager.coin()
	_emit_hud()
	queue_redraw()

func use_hero_skill(index: int) -> void:
	if not active or ended or paused or hero.is_empty() or float(hero["respawn"]) > 0.0:
		return
	var definition: Dictionary = hero_defs[hero["id"]]
	var skills: Array = definition["skills"]
	if index < 0 or index >= skills.size() or float(hero["skill_cooldowns"][index]) > 0.0:
		return
	var offensive: bool = index == 0 or (hero["id"] == "kael" and index == 2) or (hero["id"] == "orion" and index == 2)
	if offensive:
		var targets := _sorted_live_enemies()
		if hero["id"] == "kael" and index == 0:
			targets = _enemies_near(hero["x"], hero["y"], 86.0)
		elif hero["id"] == "orion" and index == 2:
			targets = _enemies_near(hero["x"], hero["y"], 110.0)
		if targets.is_empty():
			toast_requested.emit("Sem alvo", "Aproxime o herói dos inimigos. A habilidade não foi gasta.", "info")
			return
	hero["skill_cooldowns"][index] = float(skills[index]["cooldown"])
	_increment_stat("abilities", 1)
	AudioManager.ability()
	match hero["id"]:
		"kael": _kael_skill(index)
		"lyra": _lyra_skill(index)
		"orion": _orion_skill(index)
		"volt": _volt_skill(index)
		"nyx": _nyx_skill(index)
	# Movement abilities must replace the old movement order.
	if index == 2:
		hero["target_x"] = hero["x"]
		hero["target_y"] = hero["y"]
	_spawn_burst(float(hero["x"]), float(hero["y"]), Color("#" + definition["color"]), 16, 58.0)
	_add_effect({"kind": "ability", "x": hero["x"], "y": hero["y"], "life": 0.7, "max_life": 0.7, "color": Color("#" + definition["color"])})
	_emit_hud()

func use_hero_ultimate() -> void:
	if not active or ended or paused or hero.is_empty() or float(hero["ultimate"]) < 100.0 or float(hero["respawn"]) > 0.0:
		return
	var hero_id: String = hero["id"]
	var definition: Dictionary = hero_defs[hero_id]
	hero["ultimate"] = 0.0
	_increment_stat("abilities", 1)
	AudioManager.ability()
	match hero_id:
		"kael":
			for enemy in _enemies_near(float(hero["x"]), float(hero["y"]), 150.0): _deal_damage(enemy, 300.0 + int(hero["level"]) * 25.0, "physical", "hero-kael", true)
		"lyra":
			for i in range(9): _schedule_arrow_burst(i)
		"orion":
			for enemy in enemies:
				if not enemy["dead"]:
					enemy["stun"] = maxf(float(enemy["stun"]), 3.0)
					_deal_damage(enemy, 245.0 + int(hero["level"]) * 18.0, "magic", "hero-orion", false)
		"volt": _lightning_burst(8, 360.0)
		"nyx":
			var targets := _sorted_live_enemies()
			for enemy in targets.slice(0, mini(12, targets.size())): _deal_damage(enemy, 260.0 + int(hero["level"]) * 22.0, "physical", "hero-nyx", true)
	_add_effect({"kind": "ultimate", "x": hero["x"], "y": hero["y"], "life": 1.2, "max_life": 1.2, "color": Color("#" + definition["color"])})
	_spawn_burst(float(hero["x"]), float(hero["y"]), Color("#" + definition["color"]), 34, 130.0)
	screen_shake = maxf(screen_shake, 0.6)
	_add_floating_text(float(hero["x"]), float(hero["y"]) - 40.0, str(definition["ultimate"]).to_upper(), Color("#" + definition["color"]), 1.2)
	_emit_hud()

func use_global_skill(skill_id: String, confirmed: bool = false) -> void:
	if not active or ended or paused or not global_cooldowns.has(skill_id) or float(global_cooldowns[skill_id]) > 0.0:
		return
	if not confirmed and skill_id != "reinforce":
		pending_skill = "" if pending_skill == skill_id else skill_id
		build_type = ""
		selected_tower_id = -1
		cast_target = Vector2(hero["x"], hero["y"])
		toast_requested.emit("Escolha o alvo", "Toque no campo para lançar. Toque novamente na habilidade para cancelar.", "info")
		_emit_hud()
		queue_redraw()
		return
	pending_skill = ""
	var cooldowns := {"meteor": 18.0, "freeze": 24.0, "barrage": 28.0, "reinforce": 32.0}
	global_cooldowns[skill_id] = cooldowns[skill_id]
	_increment_stat("abilities", 1)
	AudioManager.ability()
	match skill_id:
		"meteor":
			var target := {"x": cast_target.x, "y": cast_target.y}
			_add_effect({"kind": "meteor", "x": target["x"], "y": target["y"], "life": 1.0, "max_life": 1.0, "color": Color("#ff7187"), "fired": false})
		"freeze":
			for enemy in _enemies_near(cast_target.x, cast_target.y, 120.0):
				if not enemy["dead"]:
					enemy["stun"] = maxf(float(enemy["stun"]), 2.4)
					enemy["status"] = "CONGELADO"
			_add_effect({"kind": "freeze_all", "x": cast_target.x, "y": cast_target.y, "life": 1.0, "max_life": 1.0, "color": Color("#a6e9ff")})
			_spawn_burst(cast_target.x, cast_target.y, Color("#a6e9ff"), 38, 150.0)
		"barrage":
			_add_effect({"kind": "barrage", "x": cast_target.x, "y": cast_target.y, "life": 1.8, "max_life": 1.8, "color": Color("#f2bd6b"), "shots": 0})
		"reinforce":
			reinforce_until = game_time + 9.0
			_add_effect({"kind": "reinforce", "x": 640.0, "y": 360.0, "life": 0.8, "max_life": 0.8, "color": Color("#72e4b3")})
			_add_floating_text(640.0, 105.0, "TORRES REFORÇADAS · 9s", Color("#72e4b3"), 0.95)
	_emit_hud()

func set_hero_target(target: Vector2) -> void:
	if hero.is_empty():
		return
	hero["target_x"] = clampf(target.x, 48.0, 1230.0)
	hero["target_y"] = clampf(target.y, 48.0, 672.0)
	_add_effect({"kind": "move_marker", "x": target.x, "y": target.y, "life": 0.45, "max_life": 0.45, "color": Color("#" + hero_defs[hero["id"]]["color"])})

func _unhandled_input(event: InputEvent) -> void:
	if not active or paused or ended:
		return
	if event is InputEventScreenTouch and event.pressed:
		_handle_pointer(event.position)
	elif event is InputEventMouseButton and event.device != -1 and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_pointer(event.position)

func _handle_pointer(position: Vector2) -> void:
	# The battle HUD owns the top rail, right command rail and bottom build tray.
	# Keeping the canvas input inside this safe playfield prevents a button tap from
	# also placing a tower underneath the UI on touch devices.
	if not FIELD_RECT.has_point(position):
		return
	var point := (position - FIELD_ORIGIN) / FIELD_SCALE
	if pending_skill != "":
		cast_target = point
		use_global_skill(pending_skill, true)
		return
	var spot_index := _nearest_spot(point, 38.0)
	if build_type != "":
		if spot_index >= 0 and int(tower_spots[spot_index]["tower_id"]) < 0:
			_add_tower(build_type, spot_index)
		elif spot_index >= 0:
			select_tower(int(tower_spots[spot_index]["tower_id"]))
		else:
			toast_requested.emit("Posição inválida", "Toque em um círculo de construção.", "info")
		return
	if spot_index >= 0 and int(tower_spots[spot_index]["tower_id"]) >= 0:
		select_tower(int(tower_spots[spot_index]["tower_id"]))
		return
	selected_tower_id = -1
	set_hero_target(point)
	_emit_hud()
	queue_redraw()

func _stage_from_id(stage_id: int) -> Dictionary:
	var safe_id := clampi(stage_id, 1, 25)
	var world_index := int((safe_id - 1) / 5)
	var local_index := (safe_id - 1) % 5
	var world: Dictionary = worlds[world_index]
	var is_boss := local_index == 4
	var boss_data: Dictionary = boss_defs[world_index]
	return {"id": safe_id, "world": world_index, "local": local_index, "name": world["stages"][local_index], "subtitle": world["stage_subtitles"][local_index], "is_boss": is_boss, "boss": boss_data if is_boss else {}, "waves": 12 + int(world_index * 1.5) + (3 if is_boss else 0), "reward": 140 + world_index * 55 + local_index * 25, "variant": local_index % 3}

func _build_path(world_index: int, variant: int) -> Array[Vector2]:
	var source: Array = worlds[world_index]["path"]
	var result_points: Array[Vector2] = []
	for index in range(source.size()):
		var source_point: Array = source[index]
		var x := clampf(float(source_point[0]), -30.0, 1235.0)
		var y := float(source_point[1])
		if variant == 1: y = clampf(y + (20.0 if index % 2 else -16.0), 55.0, 650.0)
		elif variant == 2: y = clampf(y + sin(float(index) * 1.7) * 24.0, 45.0, 660.0)
		result_points.append(Vector2(x, y))
	return result_points

func _build_path_lengths() -> void:
	path_lengths.clear()
	path_total = 0.0
	for index in range(1, path_points.size()):
		var length := path_points[index - 1].distance_to(path_points[index])
		path_lengths.append(length)
		path_total += length
	path_total = maxf(path_total, 1.0)

func _point_on_path(progress: float) -> Vector2:
	var target_distance := clampf(progress, 0.0, 1.0) * path_total
	var travelled := 0.0
	for index in range(path_lengths.size()):
		var segment: float = path_lengths[index]
		if travelled + segment >= target_distance:
			var local := (target_distance - travelled) / maxf(segment, 0.001)
			return path_points[index].lerp(path_points[index + 1], local)
		travelled += segment
	return path_points.back()

func _build_tower_spots(world_index: int, variant: int) -> Array:
	var sets: Array = [
		[[112, 212], [283, 176], [320, 348], [455, 343], [578, 176], [610, 333], [772, 456], [895, 283], [756, 280]],
		[[104, 380], [156, 252], [318, 174], [374, 340], [544, 407], [610, 548], [835, 172], [900, 278], [985, 280]],
		[[128, 174], [369, 230], [190, 442], [430, 473], [640, 222], [810, 172], [813, 448], [950, 285], [958, 500]]
	]
	var points: Array = sets[variant % sets.size()]
	var result_spots: Array = []
	for index in range(points.size()):
		result_spots.append({"id": index, "x": float(points[index][0]), "y": float(points[index][1]), "tower_id": -1})
	return result_spots

func _create_wave_plan(wave_number: int) -> Array:
	var world_index: int = stage["world"]
	var count := mini(23, int(round((5.0 + wave_number * 1.25 + world_index * 1.6) * float(difficulty["count"]))))
	var plan: Array = []
	for index in range(count):
		var enemy_type := "basic"
		if wave_number >= 2 and index % 5 == 0: enemy_type = "runner"
		if world_index >= 1 and wave_number >= 3 and index % 7 == 0: enemy_type = "armored"
		if world_index >= 1 and wave_number >= 4 and index % 9 == 0: enemy_type = "tank"
		if world_index >= 1 and wave_number >= 5 and index % 8 == 0: enemy_type = "shielded"
		if world_index >= 2 and wave_number >= 3 and index % 6 == 0: enemy_type = "flying"
		if world_index >= 2 and wave_number >= 5 and index % 10 == 0: enemy_type = "saboteur"
		if world_index >= 2 and wave_number >= 6 and index % 11 == 0: enemy_type = "healer"
		if world_index >= 3 and wave_number >= 4 and index % 9 == 0: enemy_type = "teleporter"
		if world_index >= 3 and wave_number >= 7 and index % 12 == 0: enemy_type = "summoner"
		if wave_number % 4 == 0 and index % 3 == 0: enemy_type = "runner"
		plan.append({"type": enemy_type, "delay": 0.0 if index == 0 else 0.34 + (index % 3) * 0.06})
	if bool(stage["is_boss"]) and wave_number == max_waves:
		plan.append({"type": "tank", "delay": 0.7})
		plan.append({"type": "healer", "delay": 0.7})
		plan.append({"type": "boss", "delay": 1.2})
	return plan

func _spawn_enemy(type_id: String) -> Dictionary:
	if type_id == "boss":
		var boss_data: Dictionary = stage["boss"] if not stage["boss"].is_empty() else boss_defs[int(stage["world"])]
		var boss_hp := float(boss_data["hp"]) * (1.0 + int(stage["world"]) * 0.2) * float(difficulty["hp"])
		var start := _point_on_path(0.0)
		var boss_enemy := {"id": next_enemy_id, "type": "boss", "name": boss_data["name"], "color": Color("#" + boss_data["color"]), "x": start.x, "y": start.y, "progress": 0.0, "speed": float(boss_data["speed"]) * float(difficulty["speed"]), "hp": boss_hp, "max_hp": boss_hp, "radius": 28.0, "reward": 320 + int(stage["world"]) * 110, "leak": 12, "armor": 0.28, "magic_resist": 0.18, "shield": 0.0, "max_shield": 0.0, "flying": false, "healer": false, "saboteur": false, "summoner": false, "teleporter": false, "ability_timer": 5.0, "summon_count": 0, "teleport_charge": 0.0, "slow": 1.0, "slow_time": 0.0, "stun": 0.0, "hit_flash": 0.0, "dead": false, "contact_timer": 0.0, "status": "", "boss_phase": 1, "boss_timer": 5.0, "boss_def": boss_data}
		next_enemy_id += 1
		enemies.append(boss_enemy)
		boss = boss_enemy
		_spawn_burst(boss_enemy["x"], boss_enemy["y"], boss_enemy["color"], 34, 95.0)
		_add_effect({"kind": "boss_banner", "x": 640.0, "y": 94.0, "life": 4.0, "max_life": 4.0, "color": boss_enemy["color"]})
		_add_floating_text(boss_enemy["x"], boss_enemy["y"] - 48.0, "BOSS ENCONTROU A ROTA", boss_enemy["color"], 1.5)
		AudioManager.boss()
		AudioManager.start_music(true)
		return boss_enemy
	var definition: Dictionary = enemy_defs[type_id]
	var wave_factor := 1.0 + wave * 0.085 + int(stage["world"]) * 0.16
	var hp := float(definition["hp"]) * wave_factor * float(difficulty["hp"])
	var start := _point_on_path(0.0)
	var enemy := {"id": next_enemy_id, "type": type_id, "name": definition["name"], "color": Color("#" + definition["color"]), "x": start.x, "y": start.y, "progress": 0.0, "speed": float(definition["speed"]) * float(difficulty["speed"]) * (1.0 + wave * 0.01), "hp": hp, "max_hp": hp, "radius": float(definition["radius"]), "reward": int(round(float(definition["reward"]) * (1.0 + int(stage["world"]) * 0.12))), "leak": int(definition["leak"]), "armor": float(definition.get("armor", 0.0)), "magic_resist": float(definition.get("magic_resist", 0.0)), "shield": float(definition.get("shield", 0.0)) * (1.0 + wave * 0.045), "max_shield": float(definition.get("shield", 0.0)) * (1.0 + wave * 0.045), "flying": bool(definition.get("flying", false)), "healer": bool(definition.get("healer", false)), "saboteur": bool(definition.get("saboteur", false)), "summoner": bool(definition.get("summoner", false)), "teleporter": bool(definition.get("teleporter", false)), "ability_timer": 2.5 + rng.randf_range(0.0, 2.0), "summon_count": 0, "teleport_charge": 0.0, "slow": 1.0, "slow_time": 0.0, "stun": 0.0, "hit_flash": 0.0, "dead": false, "contact_timer": 0.0, "status": ""}
	next_enemy_id += 1
	enemies.append(enemy)
	_spawn_burst(enemy["x"], enemy["y"], enemy["color"], 5 if enemy["flying"] else 3, 26.0)
	return enemy

func _update_wave(delta: float) -> void:
	if not wave_active:
		if intermission > 0.0:
			intermission = maxf(0.0, intermission - delta)
			if intermission <= 0.0: start_next_wave()
		return
	spawn_timer -= delta
	if not spawn_queue.is_empty() and spawn_timer <= 0.0:
		var next: Dictionary = spawn_queue.pop_front()
		_spawn_enemy(next["type"])
		spawn_timer = float(next["delay"])
	if spawn_queue.is_empty() and enemies.is_empty():
		wave_active = false
		if wave >= max_waves:
			_finish_battle("victory")
		else:
			intermission = 8.0
			_add_floating_text(640.0, 80.0, "ROTA LIMPA · PRÓXIMA ONDA LIBERADA", Color("#72e4b3"), 1.15)
			AudioManager.play_tone(360.0, 0.18, 0.07)

func _update_enemies(delta: float) -> void:
	var pending_cleanup: Array[int] = []
	for index in range(enemies.size()):
		var enemy: Dictionary = enemies[index]
		if bool(enemy["dead"]):
			pending_cleanup.append(index)
			continue
		var point := _point_on_path(float(enemy["progress"]))
		enemy["x"] = point.x
		enemy["y"] = point.y
		enemy["hit_flash"] = maxf(0.0, float(enemy["hit_flash"]) - delta)
		enemy["slow_time"] = maxf(0.0, float(enemy["slow_time"]) - delta)
		if float(enemy["slow_time"]) <= 0.0: enemy["slow"] = 1.0
		enemy["stun"] = maxf(0.0, float(enemy["stun"]) - delta)
		enemy["contact_timer"] = float(enemy["contact_timer"]) - delta

		if enemy["type"] == "boss": _update_boss(enemy, delta)
		if bool(enemy["healer"]) and float(enemy["ability_timer"]) <= 0.0:
			enemy["ability_timer"] = 2.6
			var healed := 0
			for ally in enemies:
				if ally == enemy or bool(ally["dead"]): continue
				if _enemy_distance(enemy, ally) < 92.0 and healed < 4:
					ally["hp"] = minf(float(ally["max_hp"]), float(ally["hp"]) + float(ally["max_hp"]) * 0.085)
					ally["hit_flash"] = 0.12
					_add_effect({"kind": "heal", "x": ally["x"], "y": ally["y"], "life": 0.55, "max_life": 0.55, "color": enemy["color"]})
					healed += 1
			if healed > 0: _add_floating_text(enemy["x"], enemy["y"] - 20.0, "CURA", enemy["color"], 0.65)
		if bool(enemy["saboteur"]) and float(enemy["ability_timer"]) <= 0.0:
			enemy["ability_timer"] = 4.6
			if not towers.is_empty():
				var chosen: Dictionary = towers[rng.randi_range(0, towers.size() - 1)]
				chosen["disabled_until"] = maxf(float(chosen["disabled_until"]), game_time + 2.8)
				_add_effect({"kind": "glitch", "x": chosen["x"], "y": chosen["y"], "life": 1.1, "max_life": 1.1, "color": enemy["color"]})
				_add_floating_text(chosen["x"], chosen["y"] - 24.0, "DESATIVADA", enemy["color"], 0.75)
		if bool(enemy["summoner"]) and float(enemy["ability_timer"]) <= 0.0 and int(enemy["summon_count"]) < 3:
			enemy["ability_timer"] = 5.4
			enemy["summon_count"] = int(enemy["summon_count"]) + 1
			var minion := _spawn_enemy("basic")
			minion["progress"] = maxf(0.0, float(enemy["progress"]) - 0.025)
			minion["x"] = enemy["x"]
			minion["y"] = enemy["y"]
			_add_effect({"kind": "summon", "x": enemy["x"], "y": enemy["y"], "life": 0.75, "max_life": 0.75, "color": enemy["color"]})
			_add_floating_text(enemy["x"], enemy["y"] - 22.0, "INVOCANDO", enemy["color"], 0.75)
		if bool(enemy["teleporter"]): _update_teleporter(enemy, delta)
		enemy["ability_timer"] = float(enemy["ability_timer"]) - delta
		if float(enemy["teleport_charge"]) <= 0.0 and float(enemy["stun"]) <= 0.0:
			var slow_factor := float(enemy["slow"]) if float(enemy["slow_time"]) > 0.0 else 1.0
			enemy["progress"] += (float(enemy["speed"]) * slow_factor * delta) / path_total
		if float(enemy["progress"]) >= 1.0:
			_reach_base(enemy)
			continue
		if not hero.is_empty() and float(hero["respawn"]) <= 0.0 and float(hero["invulnerable"]) <= 0.0 and not bool(enemy["flying"]) and _enemy_distance(enemy, hero) < float(enemy["radius"]) + 16.0 and float(enemy["contact_timer"]) <= 0.0:
			enemy["contact_timer"] = 1.2
			var contact_damage := 22.0 if enemy["type"] == "boss" else (13.0 if enemy["type"] == "tank" else 7.0)
			hero["hp"] = maxf(0.0, float(hero["hp"]) - contact_damage)
			hero["invulnerable"] = 0.45
			_add_floating_text(hero["x"], hero["y"] - 24.0, "-%d" % int(contact_damage), Color("#ff7187"), 0.65)
			_spawn_burst(hero["x"], hero["y"], Color("#ff7187"), 5, 35.0)
			if float(hero["hp"]) <= 0.0:
				hero["respawn"] = 4.0
				_add_floating_text(hero["x"], hero["y"] - 38.0, "HERÓI FORA DE COMBATE", Color("#ff7187"), 1.1)
	for index in range(pending_cleanup.size() - 1, -1, -1): enemies.remove_at(pending_cleanup[index])

func _update_teleporter(enemy: Dictionary, delta: float) -> void:
	if float(enemy["teleport_charge"]) > 0.0:
		enemy["teleport_charge"] = float(enemy["teleport_charge"]) - delta
		enemy["status"] = "SALTANDO"
		if float(enemy["teleport_charge"]) <= 0.0:
			enemy["progress"] = minf(0.91, float(enemy["progress"]) + 0.105)
			enemy["ability_timer"] = 4.8
			enemy["status"] = ""
			_add_effect({"kind": "teleport", "x": enemy["x"], "y": enemy["y"], "life": 0.75, "max_life": 0.75, "color": enemy["color"]})
			_spawn_burst(enemy["x"], enemy["y"], enemy["color"], 10, 38.0)
			AudioManager.play_tone(650.0, 0.14, 0.07)
	elif float(enemy["ability_timer"]) <= 0.0 and float(enemy["progress"]) < 0.82:
		enemy["teleport_charge"] = 0.82
		enemy["status"] = "CARREGANDO"
		_add_effect({"kind": "telegraph", "x": enemy["x"], "y": enemy["y"], "life": 0.82, "max_life": 0.82, "color": enemy["color"]})

func _update_boss(enemy: Dictionary, delta: float) -> void:
	var ratio := float(enemy["hp"]) / maxf(float(enemy["max_hp"]), 1.0)
	var desired_phase := 4 if ratio <= 0.15 else (3 if ratio <= 0.4 else (2 if ratio <= 0.7 else 1))
	if desired_phase > int(enemy["boss_phase"]):
		enemy["boss_phase"] = desired_phase
		enemy["boss_timer"] = 1.4
		enemy["status"] = enemy["boss_def"]["phases"][desired_phase - 1]
		_add_effect({"kind": "boss_phase", "x": enemy["x"], "y": enemy["y"], "life": 1.2, "max_life": 1.2, "color": enemy["color"]})
		_add_floating_text(enemy["x"], enemy["y"] - 48.0, "FASE %d · %s" % [desired_phase, str(enemy["status"]).to_upper()], enemy["color"], 1.1)
		_spawn_burst(enemy["x"], enemy["y"], enemy["color"], 24, 78.0)
		screen_shake = maxf(screen_shake, 0.45)
		AudioManager.boss()
	enemy["boss_timer"] = float(enemy["boss_timer"]) - delta
	if float(enemy["boss_timer"]) <= 0.0:
		enemy["boss_timer"] = maxf(3.2, 7.0 - int(enemy["boss_phase"]) * 0.75)
		_boss_ability(enemy)

func _boss_ability(boss_enemy: Dictionary) -> void:
	var world_entry: Dictionary = worlds[int(stage["world"])]
	var world_key: String = world_entry["key"]
	match world_key:
		"forest":
			if not towers.is_empty():
				var tower: Dictionary = towers[rng.randi_range(0, towers.size() - 1)]
				tower["disabled_until"] = game_time + 3.2
				_add_effect({"kind": "roots", "x": tower["x"], "y": tower["y"], "life": 1.2, "max_life": 1.2, "color": boss_enemy["color"]})
				_add_floating_text(tower["x"], tower["y"] - 22.0, "RAÍZES", boss_enemy["color"], 0.7)
		"desert":
			for i in range(int(boss_enemy["boss_phase"])):
				var soldier := _spawn_enemy("runner" if i % 2 else "armored")
				soldier["progress"] = maxf(0.0, float(boss_enemy["progress"]) - 0.07 - i * 0.025)
			_add_effect({"kind": "sandstorm", "x": boss_enemy["x"], "y": boss_enemy["y"], "life": 1.3, "max_life": 1.3, "color": boss_enemy["color"]})
			if int(boss_enemy["boss_phase"]) >= 3: sandstorm_until = game_time + 4.5
		"city":
			for tower in towers: tower["disabled_until"] = maxf(float(tower["disabled_until"]), game_time + (3.5 if int(boss_enemy["boss_phase"]) >= 3 else 1.6))
			_add_effect({"kind": "emp", "x": 650.0, "y": 360.0, "life": 1.1, "max_life": 1.1, "color": boss_enemy["color"]})
			_add_floating_text(650.0, 320.0, "PULSO EMP", boss_enemy["color"], 0.9)
		"frozen":
			for enemy in enemies:
				if enemy != boss_enemy and not bool(enemy["dead"]): enemy["slow"] = 0.34; enemy["slow_time"] = 4.0
			_add_effect({"kind": "blizzard", "x": 650.0, "y": 360.0, "life": 1.4, "max_life": 1.4, "color": boss_enemy["color"]})
			_add_floating_text(650.0, 300.0, "INVERNO TOTAL", boss_enemy["color"], 0.9)
		"void":
			boss_enemy["hp"] = minf(float(boss_enemy["max_hp"]), float(boss_enemy["hp"]) + float(boss_enemy["max_hp"]) * 0.035)
			boss_enemy["progress"] = maxf(0.0, float(boss_enemy["progress"]) - 0.025)
			_add_effect({"kind": "rift", "x": boss_enemy["x"], "y": boss_enemy["y"], "life": 1.25, "max_life": 1.25, "color": boss_enemy["color"]})
			_add_floating_text(boss_enemy["x"], boss_enemy["y"] - 46.0, "A FENDA DEVOLVE", boss_enemy["color"], 0.9)

func _reach_base(enemy: Dictionary) -> void:
	if bool(enemy["dead"]): return
	enemy["dead"] = true
	var hit := int(maxi(8, int(ceil(base_max * 0.55)))) if enemy["type"] == "boss" else int(enemy["leak"])
	base_hp = maxf(0.0, base_hp - hit)
	_add_floating_text(1210.0, 646.0, "-%d" % hit, Color("#ff7187"), 0.8)
	_spawn_burst(1210.0, 646.0, Color("#ff7187"), 20 if enemy["type"] == "boss" else 8, 65.0)
	screen_shake = maxf(screen_shake, 0.7 if enemy["type"] == "boss" else 0.18)
	AudioManager.defeat()
	if base_hp <= 0.0: _finish_battle("defeat")

func _update_towers(delta: float) -> void:
	for tower in towers:
		tower["cooldown"] = maxf(0.0, float(tower["cooldown"]) - delta)
		tower["attack_flash"] = maxf(0.0, float(tower["attack_flash"]) - delta)
		if float(tower["disabled_until"]) > game_time or float(tower["cooldown"]) > 0.0:
			continue
		var stats := _tower_stats(tower)
		var target := _tower_target(tower, stats)
		if target.is_empty():
			continue
		tower["cooldown"] = float(stats["cooldown"])
		tower["attack_flash"] = 0.14
		_fire_tower(tower, stats, target)

func _tower_stats(tower: Dictionary) -> Dictionary:
	var definition: Dictionary = tower_defs[tower["type"]]
	var level: int = int(tower["level"])
	var research: int = int(SaveManager.data["research"].get(tower["type"], 0))
	var damage: float = float(definition["damage"]) * (1.0 + (level - 1) * 0.34) * (1.0 + research * 0.08)
	var cooldown: float = float(definition["cooldown"]) * (1.0 - (level - 1) * 0.1)
	var range_value: float = float(definition["range"]) + (level - 1) * 8.0
	var area: float = float(definition.get("area", 0.0))
	var crit: float = 0.08 if tower["type"] == "archer" else (0.18 if tower["type"] == "sentinel" else 0.04)
	var chain: int = int(definition.get("chain", 0))
	var slow: float = float(definition.get("slow", 1.0))
	var multi := 1
	match tower.get("spec", ""):
		"marksman": damage *= 1.42; cooldown *= 1.24; range_value += 22.0; crit += 0.18
		"arrowmaster": damage *= 0.72; cooldown *= 0.58; multi = 2
		"astral": damage *= 1.24; area += 13.0
		"rift": range_value += 28.0; area += 8.0; slow = 0.54
		"siege": damage *= 1.48; cooldown *= 1.13; crit += 0.1
		"shrapnel": damage *= 0.82; area += 24.0
		"winter": slow = 0.3
		"rime": damage *= 1.38; area += 12.0; slow = 0.62
		"storm": chain += 2; range_value += 15.0
		"surge": chain = maxi(1, chain - 1); damage *= 1.5; crit += 0.13
		"executioner": crit += 0.2; damage *= 1.12
		"oracle": range_value += 42.0; crit += 0.06
	if sandstorm_until > game_time: range_value *= 0.65
	if reinforce_until > game_time: damage *= 1.26; cooldown *= 0.76
	return {"id": tower["type"], "damage": damage, "cooldown": cooldown, "range": range_value, "area": area, "crit": crit, "chain": chain, "slow": slow, "multi": multi, "can_air": bool(definition["can_air"]), "projectile": definition["projectile"], "type": definition["type"], "color": Color("#" + definition["color"])}

func _tower_target(tower: Dictionary, stats: Dictionary) -> Dictionary:
	var candidates: Array = []
	for enemy in enemies:
		if bool(enemy["dead"]): continue
		if bool(enemy["flying"]) and not bool(stats["can_air"]): continue
		if Vector2(float(tower["x"]), float(tower["y"])).distance_to(Vector2(float(enemy["x"]), float(enemy["y"]))) <= float(stats["range"]): candidates.append(enemy)
	candidates.sort_custom(func(a, b): return float(a["progress"]) > float(b["progress"]))
	return candidates[0] if not candidates.is_empty() else {}

func _fire_tower(tower: Dictionary, stats: Dictionary, target: Dictionary) -> void:
	if stats["id"] == "volt":
		var chain_targets: Array = [target]
		var previous: Dictionary = target
		for jump in range(1, int(stats["chain"])):
			var nearest: Dictionary = {}
			var nearest_distance := 99999.0
			for enemy in enemies:
				if bool(enemy["dead"]) or chain_targets.has(enemy): continue
				if bool(enemy["flying"]) and not bool(stats["can_air"]): continue
				var candidate_distance: float = Vector2(float(previous["x"]), float(previous["y"])).distance_to(Vector2(float(enemy["x"]), float(enemy["y"])))
				if candidate_distance < 82.0 and candidate_distance < nearest_distance: nearest = enemy; nearest_distance = candidate_distance
			if nearest.is_empty(): break
			chain_targets.append(nearest)
			previous = nearest
		for index in range(chain_targets.size()):
			var chain_enemy: Dictionary = chain_targets[index]
			_deal_damage(chain_enemy, float(stats["damage"]) * pow(0.72, index), "electric", "tower", false)
			var from_point := Vector2(float(tower["x"]), float(tower["y"])) if index == 0 else Vector2(float(chain_targets[index - 1]["x"]), float(chain_targets[index - 1]["y"]))
			_add_effect({"kind": "chain", "from": from_point, "to": Vector2(float(chain_enemy["x"]), float(chain_enemy["y"])), "life": 0.18, "max_life": 0.18, "color": stats["color"]})
		_spawn_burst(float(target["x"]), float(target["y"]), stats["color"], 5, 26.0)
		AudioManager.hit("electric")
		return
	var count: int = int(stats["multi"])
	for index in range(count):
		projectiles.append({"x": float(tower["x"]), "y": float(tower["y"]) - 5.0, "target_id": int(target["id"]), "target_last": Vector2(float(target["x"]), float(target["y"])), "speed": 280.0 if stats["id"] == "cannon" else (500.0 if stats["id"] == "sentinel" else 410.0), "damage": float(stats["damage"]) * (1.0 - index * 0.08), "tower_type": stats["id"], "projectile": stats["projectile"], "area": float(stats["area"]), "slow": float(stats["slow"]), "slow_time": 2.8 if stats["id"] == "frost" else (1.3 if stats["id"] == "mage" else 0.0), "crit": float(stats["crit"]), "arc": 23.0 if stats["id"] == "cannon" else 0.0, "life": 3.0, "angle": 0.0, "color": stats["color"]})
	AudioManager.hit("frost" if stats["id"] == "frost" else str(stats["type"]))

func _update_projectiles(delta: float) -> void:
	for projectile in projectiles:
		projectile["life"] = float(projectile["life"]) - delta
		var target := _enemy_by_id(int(projectile["target_id"]))
		if not target.is_empty() and not bool(target["dead"]): projectile["target_last"] = Vector2(float(target["x"]), float(target["y"]))
		var target_point: Vector2 = projectile["target_last"]
		var current := Vector2(float(projectile["x"]), float(projectile["y"]))
		var offset := target_point - current
		var distance_to_target := offset.length()
		var travel := float(projectile["speed"]) * delta
		if distance_to_target <= travel or float(projectile["life"]) <= 0.0:
			projectile["x"] = target_point.x
			projectile["y"] = target_point.y
			if not target.is_empty() and not bool(target["dead"]): _hit_projectile(projectile, target)
			projectile["dead"] = true
		else:
			projectile["x"] = current.x + offset.normalized().x * travel
			projectile["y"] = current.y + offset.normalized().y * travel
			projectile["angle"] = offset.angle()
	for index in range(projectiles.size() - 1, -1, -1):
		if bool(projectiles[index].get("dead", false)): projectiles.remove_at(index)

func _hit_projectile(projectile: Dictionary, target: Dictionary) -> void:
	var critical := rng.randf() < float(projectile["crit"])
	var type := "magic" if projectile["tower_type"] == "mage" else ("frost" if projectile["tower_type"] == "frost" else "physical")
	_deal_damage(target, float(projectile["damage"]) * (2.0 if critical else 1.0), type, "tower", critical)
	if float(projectile["slow"]) < 1.0 and not bool(target["dead"]):
		target["slow"] = minf(float(target["slow"]), float(projectile["slow"]))
		target["slow_time"] = maxf(float(target["slow_time"]), float(projectile["slow_time"]))
		target["status"] = "LENTO"
	if float(projectile["area"]) > 0.0:
		for enemy in enemies:
			if enemy == target or bool(enemy["dead"]): continue
			if bool(enemy["flying"]) and projectile["tower_type"] != "mage": continue
			if Vector2(float(target["x"]), float(target["y"])).distance_to(Vector2(float(enemy["x"]), float(enemy["y"]))) <= float(projectile["area"]): _deal_damage(enemy, float(projectile["damage"]) * 0.42, type, "tower", false)
	var effect_kind := "explosion" if projectile["tower_type"] == "cannon" else ("frost_hit" if projectile["tower_type"] == "frost" else ("magic_hit" if projectile["tower_type"] == "mage" else "hit"))
	_add_effect({"kind": effect_kind, "x": target["x"], "y": target["y"], "radius": projectile["area"], "life": 0.45 if effect_kind == "explosion" else 0.25, "max_life": 0.45 if effect_kind == "explosion" else 0.25, "color": projectile["color"]})
	_spawn_burst(float(target["x"]), float(target["y"]), projectile["color"], 12 if effect_kind == "explosion" else 5, 70.0 if effect_kind == "explosion" else 32.0)

func _deal_damage(enemy: Dictionary, raw_amount: float, damage_type: String, source: String, critical: bool) -> void:
	if enemy.is_empty() or bool(enemy["dead"]):
		return
	var amount := maxf(1.0, raw_amount)
	if float(enemy["shield"]) > 0.0:
		var absorbed := minf(float(enemy["shield"]), amount)
		enemy["shield"] = float(enemy["shield"]) - absorbed
		amount = maxf(0.0, amount - absorbed)
		enemy["status"] = "ESCUDO" if float(enemy["shield"]) > 0.0 else "ESCUDO ROMPIDO"
		_add_effect({"kind": "shield_hit", "x": enemy["x"], "y": enemy["y"], "life": 0.22, "max_life": 0.22, "color": Color("#74c8ff")})
		if float(enemy["shield"]) <= 0.0:
			_spawn_burst(float(enemy["x"]), float(enemy["y"]), Color("#74c8ff"), 12, 58.0)
			_add_floating_text(float(enemy["x"]), float(enemy["y"]) - 22.0, "ESCUDO ROMPIDO", Color("#a8e7ff"), 0.8)
	if amount > 0.0:
		if damage_type == "physical": amount *= 1.0 - float(enemy["armor"])
		elif damage_type == "magic" or damage_type == "frost" or damage_type == "electric": amount *= 1.0 - float(enemy["magic_resist"])
		enemy["hp"] = float(enemy["hp"]) - amount
		damage_done += amount
		enemy["hit_flash"] = 0.12
		var label := "%d%s" % [int(round(amount)), " CRÍTICO!" if critical else ""]
		var label_color := Color("#ffe2a6") if critical else (Color("#d4c7ff") if damage_type == "magic" else (Color("#a8e7ff") if damage_type == "electric" else Color("#f2f5ff")))
		_add_floating_text(float(enemy["x"]) + rng.randf_range(-8.0, 8.0), float(enemy["y"]) - float(enemy["radius"]) - 8.0, label, label_color, 0.95 if critical else 0.62)
	if float(enemy["hp"]) <= 0.0: _kill_enemy(enemy, source, damage_type)

func _kill_enemy(enemy: Dictionary, source: String = "tower", damage_type: String = "physical") -> void:
	if bool(enemy["dead"]):
		return
	enemy["dead"] = true
	kills += 1
	gold += int(enemy["reward"])
	_increment_stat("kills", 1)
	if damage_type == "electric" or source == "hero-volt": _increment_stat("lightning_kills", 1)
	if enemy["type"] == "boss":
		_increment_stat("bosses", 1)
		_add_floating_text(float(enemy["x"]), float(enemy["y"]) - 54.0, "BOSS DERROTADO", Color("#f2bd6b"), 1.4)
		_spawn_burst(float(enemy["x"]), float(enemy["y"]), enemy["color"], 38, 122.0)
		screen_shake = maxf(screen_shake, 0.9)
		AudioManager.victory()
	else:
		_spawn_burst(float(enemy["x"]), float(enemy["y"]), enemy["color"], 8 if enemy["flying"] else 5, 44.0 if enemy["flying"] else 28.0)
	_add_floating_text(float(enemy["x"]), float(enemy["y"]) - float(enemy["radius"]) - 22.0, "+%d" % int(enemy["reward"]), Color("#f2bd6b"), 0.78)
	_give_hero_xp(80.0 if enemy["type"] == "boss" else 14.0 + int(enemy["reward"]) / 4.0)
	AudioManager.coin()

func _give_hero_xp(amount: float) -> void:
	if hero.is_empty() or float(hero["respawn"]) > 0.0:
		return
	hero["xp"] = float(hero["xp"]) + amount
	hero["ultimate"] = clampf(float(hero["ultimate"]) + amount * 0.17, 0.0, 100.0)
	while float(hero["xp"]) >= float(hero["next_xp"]):
		hero["xp"] = float(hero["xp"]) - float(hero["next_xp"])
		hero["level"] = int(hero["level"]) + 1
		hero["next_xp"] = float(round(float(hero["next_xp"]) * 1.25))
		hero["max_hp"] = float(hero["max_hp"]) + 12.0
		hero["hp"] = hero["max_hp"]
		_add_floating_text(float(hero["x"]), float(hero["y"]) - 38.0, "NÍVEL %d" % int(hero["level"]), Color("#75e5ef"), 1.05)
		_spawn_burst(float(hero["x"]), float(hero["y"]), Color("#75e5ef"), 15, 52.0)
		AudioManager.upgrade()

func _increment_stat(stat: String, amount: int) -> void:
	SaveManager.increment_stat(stat, amount)
	_check_achievements()

func _check_achievements() -> void:
	var achievements: Array = GameData.achievements()
	for achievement in achievements:
		var value: int = int(SaveManager.data["stats"].get(str(achievement["stat"]), 0))
		if value >= int(achievement["target"]) and not SaveManager.data["achievements"].has(achievement["id"]):
			SaveManager.data["achievements"].append(achievement["id"])
			toast_requested.emit("Conquista desbloqueada", achievement["title"], "reward")
			AudioManager.upgrade()

func _update_hero(delta: float) -> void:
	if hero.is_empty():
		return
	var definition: Dictionary = hero_defs[hero["id"]]
	hero["invulnerable"] = maxf(0.0, float(hero["invulnerable"]) - delta)
	hero["attack_flash"] = maxf(0.0, float(hero["attack_flash"]) - delta)
	var cooldowns: Array = hero["skill_cooldowns"]
	for index in range(cooldowns.size()): cooldowns[index] = maxf(0.0, float(cooldowns[index]) - delta)
	for key in global_cooldowns.keys(): global_cooldowns[key] = maxf(0.0, float(global_cooldowns[key]) - delta)
	if float(hero["respawn"]) > 0.0:
		hero["respawn"] = float(hero["respawn"]) - delta
		if float(hero["respawn"]) <= 0.0:
			hero["hp"] = hero["max_hp"]
			hero["invulnerable"] = 1.4
			_add_floating_text(hero["x"], hero["y"] - 30.0, "HERÓI RETORNOU", Color("#72e4b3"), 0.8)
		return
	var current := Vector2(float(hero["x"]), float(hero["y"]))
	var target := Vector2(float(hero["target_x"]), float(hero["target_y"]))
	var travel := current.distance_to(target)
	if travel > 2.0:
		var step := minf(travel, float(definition["speed"]) * delta)
		hero["facing"] = 1.0 if target.x >= current.x else -1.0
		var next := current + current.direction_to(target) * step
		hero["x"] = next.x
		hero["y"] = next.y
	hero["cooldown"] = maxf(0.0, float(hero["cooldown"]) - delta)
	if float(hero["cooldown"]) > 0.0:
		return
	var target_enemy := _hero_target(float(definition["range"]))
	if target_enemy.is_empty():
		return
	hero["cooldown"] = float(definition["cooldown"]) * (1.0 - minf(0.18, (int(hero["level"]) - 1) * 0.035))
	hero["attack_flash"] = 0.14
	hero["facing"] = 1.0 if float(target_enemy["x"]) >= float(hero["x"]) else -1.0
	if hero["id"] == "kael" or hero["id"] == "nyx":
		var critical: bool = hero["id"] == "nyx" and rng.randf() < 0.28
		_deal_damage(target_enemy, float(definition["damage"]) * (1.0 + (int(hero["level"]) - 1) * 0.16) * (2.1 if critical else 1.0), "physical", "hero-" + hero["id"], critical)
		_add_effect({"kind": "hero_slash", "x": target_enemy["x"], "y": target_enemy["y"], "life": 0.16, "max_life": 0.16, "color": Color("#" + definition["color"])})
	else:
		projectiles.append({"x": hero["x"], "y": hero["y"] - 7.0, "target_id": target_enemy["id"], "target_last": Vector2(target_enemy["x"], target_enemy["y"]), "speed": 500.0, "damage": float(definition["damage"]) * (1.0 + (int(hero["level"]) - 1) * 0.16), "tower_type": "volt" if hero["id"] == "volt" else "mage", "projectile": "chain" if hero["id"] == "volt" else "orb", "area": 24.0 if hero["id"] == "orion" else 0.0, "slow": 0.66 if hero["id"] == "orion" else 1.0, "slow_time": 1.5 if hero["id"] == "orion" else 0.0, "crit": 0.05, "life": 2.0, "angle": 0.0, "color": Color("#" + definition["color"])})

func _hero_target(range_value: float) -> Dictionary:
	var candidates: Array = []
	for enemy in enemies:
		if bool(enemy["dead"]): continue
		if Vector2(float(hero["x"]), float(hero["y"])).distance_to(Vector2(float(enemy["x"]), float(enemy["y"]))) <= range_value: candidates.append(enemy)
	candidates.sort_custom(func(a, b): return float(a["progress"]) > float(b["progress"]))
	return candidates[0] if not candidates.is_empty() else {}

func _kael_skill(index: int) -> void:
	if index == 0:
		for enemy in _enemies_near(hero["x"], hero["y"], 86.0): _deal_damage(enemy, 78.0 + int(hero["level"]) * 8.0, "physical", "hero-kael", false)
	elif index == 1:
		for enemy in _enemies_near(hero["x"], hero["y"], 116.0): enemy["slow"] = 0.45; enemy["slow_time"] = 3.0; enemy["status"] = "PROVOCADO"
	else:
		var target: Dictionary = _sorted_live_enemies()[0] if not _sorted_live_enemies().is_empty() else {}
		if not target.is_empty(): hero["x"] = float(target["x"]) - 24.0; hero["y"] = target["y"]; _deal_damage(target, 115.0 + int(hero["level"]) * 12.0, "physical", "hero-kael", true)

func _lyra_skill(index: int) -> void:
	var targets := _sorted_live_enemies()
	if index == 0 and not targets.is_empty():
		var progress := float(targets[0]["progress"])
		for enemy in enemies:
			if not enemy["dead"] and absf(float(enemy["progress"]) - progress) < 0.055: _deal_damage(enemy, 95.0 + int(hero["level"]) * 9.0, "physical", "hero-lyra", false)
	elif index == 1:
		var point := Vector2(float(targets[0]["x"]), float(targets[0]["y"])) if not targets.is_empty() else Vector2(640.0, 360.0)
		for enemy in _enemies_near(point.x, point.y, 90.0): _deal_damage(enemy, 110.0 + int(hero["level"]) * 10.0, "physical", "hero-lyra", false)
	else:
		hero["x"] = clampf(float(hero["x"]) + float(hero["facing"]) * 88.0, 60.0, 1215.0)
		hero["y"] = clampf(float(hero["y"]) - 58.0, 45.0, 675.0)
		hero["invulnerable"] = 1.4

func _orion_skill(index: int) -> void:
	var targets := _sorted_live_enemies()
	if index == 0 and not targets.is_empty():
		var target: Dictionary = targets[0]
		_deal_damage(target, 145.0 + int(hero["level"]) * 12.0, "magic", "hero-orion", false)
		for enemy in _enemies_near(target["x"], target["y"], 45.0): _deal_damage(enemy, 54.0, "magic", "hero-orion", false)
	elif index == 1:
		for enemy in _enemies_near(hero["x"], hero["y"], 125.0): enemy["stun"] = 2.5; enemy["status"] = "PRESO"
	else:
		for enemy in _enemies_near(hero["x"], hero["y"], 110.0): _deal_damage(enemy, 110.0 + int(hero["level"]) * 10.0, "magic", "hero-orion", false)

func _volt_skill(index: int) -> void:
	if index == 0: _lightning_burst(3, 150.0)
	elif index == 1: _add_effect({"kind": "field", "x": hero["x"], "y": hero["y"], "radius": 88.0, "life": 5.0, "max_life": 5.0, "tick": 0.0, "color": Color("#74c8ff")})
	else:
		var targets := _sorted_live_enemies()
		if not targets.is_empty():
			var point := _point_on_path(clampf(float(targets[0]["progress"]) - 0.06, 0.1, 0.9)); hero["x"] = point.x; hero["y"] = point.y; hero["invulnerable"] = 0.8

func _nyx_skill(index: int) -> void:
	var targets := _sorted_live_enemies()
	if index == 0 and not targets.is_empty(): _deal_damage(targets[0], 230.0 + int(hero["level"]) * 18.0, "physical", "hero-nyx", true)
	elif index == 1: _add_effect({"kind": "clone", "x": hero["x"] + 18.0, "y": hero["y"] - 10.0, "life": 7.0, "max_life": 7.0, "tick": 0.0, "color": Color("#ff8eb1")})
	else: hero["invulnerable"] = 2.3

func _schedule_arrow_burst(index: int) -> void:
	scheduled_arrows.append(float(index) * 0.075)

func _lightning_burst(jumps: int, amount: float) -> void:
	var targets := _sorted_live_enemies()
	for index in range(mini(jumps, targets.size())):
		var target: Dictionary = targets[index]
		_deal_damage(target, amount * pow(0.86, index), "electric", "hero-volt", true)
		_add_effect({"kind": "chain", "from": Vector2(hero["x"], hero["y"]), "to": Vector2(target["x"], target["y"]), "life": 0.25, "max_life": 0.25, "color": Color("#74c8ff")})

func _enemies_near(x: float, y: float, radius: float) -> Array:
	var result_enemies: Array = []
	for enemy in enemies:
		if not enemy["dead"] and Vector2(x, y).distance_to(Vector2(float(enemy["x"]), float(enemy["y"]))) <= radius: result_enemies.append(enemy)
	return result_enemies

func _sorted_live_enemies() -> Array:
	var result_enemies: Array = []
	for enemy in enemies:
		if not bool(enemy["dead"]): result_enemies.append(enemy)
	result_enemies.sort_custom(func(a, b): return float(a["progress"]) > float(b["progress"]))
	return result_enemies

func _update_particles(delta: float) -> void:
	for particle in particles:
		particle["life"] = float(particle["life"]) - delta
		particle["position"] = Vector2(particle["position"]) + Vector2(particle["velocity"]) * delta
		particle["velocity"] = Vector2(particle["velocity"]) + Vector2(0.0, float(particle["gravity"])) * delta
		particle["velocity"] = Vector2(particle["velocity"]) * (1.0 - minf(0.8 * delta, 0.08))
	for index in range(particles.size() - 1, -1, -1):
		if float(particles[index]["life"]) <= 0.0: particles.remove_at(index)

func _update_effects(delta: float) -> void:
	for index in range(scheduled_arrows.size() - 1, -1, -1):
		scheduled_arrows[index] -= delta
		if scheduled_arrows[index] <= 0:
			scheduled_arrows.remove_at(index)
			var targets := _sorted_live_enemies()
			if not targets.is_empty():
				var target: Dictionary = targets[0]
				_deal_damage(target, 170.0 + int(hero["level"]) * 12.0, "physical", "hero-lyra", true)
				_spawn_burst(target["x"], target["y"], Color("#f2bd6b"), 6, 45)
	for effect in effects.duplicate():
		effect["life"] = float(effect["life"]) - delta
		if effect["kind"] == "field" or effect["kind"] == "clone":
			effect["tick"] = float(effect.get("tick", 0.0)) - delta
			if effect["kind"] == "field" and float(effect["tick"]) <= 0.0:
				effect["tick"] = 0.55
				for enemy in _enemies_near(float(effect["x"]), float(effect["y"]), float(effect["radius"])):
					enemy["stun"] = maxf(float(enemy["stun"]), 0.28)
					_deal_damage(enemy, 22.0, "electric", "hero-volt", false)
			if effect["kind"] == "clone" and float(effect["tick"]) <= 0.0:
				effect["tick"] = 0.72
				var target: Dictionary = _sorted_live_enemies()[0] if not _sorted_live_enemies().is_empty() else {}
				if not target.is_empty(): _deal_damage(target, 48.0, "physical", "hero-nyx", false)
		if effect["kind"] == "meteor" and not bool(effect.get("fired", false)) and float(effect["life"]) < 0.65:
			effect["fired"] = true
			for enemy in _enemies_near(float(effect["x"]), float(effect["y"]), 84.0): _deal_damage(enemy, 180.0, "magic", "global", true)
			_spawn_burst(float(effect["x"]), float(effect["y"]), effect["color"], 22, 95.0)
			screen_shake = maxf(screen_shake, 0.45)
		if effect["kind"] == "barrage":
			var total_progress := 1.0 - float(effect["life"]) / float(effect["max_life"])
			var shot_index := int(floor(total_progress * 9.0))
			if shot_index > int(effect.get("shots", 0)):
				effect["shots"] = shot_index
				var targets := _enemies_near(float(effect["x"]), float(effect["y"]), 120.0)
				if not targets.is_empty():
					var target: Dictionary = targets[shot_index % targets.size()]
					for enemy in _enemies_near(float(target["x"]), float(target["y"]), 42.0): _deal_damage(enemy, 72.0, "physical", "global", false)
					_add_effect({"kind": "explosion", "x": target["x"], "y": target["y"], "radius": 42.0, "life": 0.35, "max_life": 0.35, "color": Color("#f2bd6b")})
	for index in range(effects.size() - 1, -1, -1):
		if float(effects[index]["life"]) <= 0.0: effects.remove_at(index)

func _update_floating_texts(delta: float) -> void:
	for text in floating_texts:
		text["life"] = float(text["life"]) - delta
		text["position"] = Vector2(text["position"]) + Vector2(0.0, -20.0 * delta)
	for index in range(floating_texts.size() - 1, -1, -1):
		if float(floating_texts[index]["life"]) <= 0.0: floating_texts.remove_at(index)

func _add_effect(effect: Dictionary) -> void:
	if effects.size() < 260:
		effects.append(effect)

func _spawn_burst(x: float, y: float, color: Color, amount: int, speed: float) -> void:
	var count := amount
	if bool(SaveManager.setting("reduced_motion", false)): count = maxi(2, int(ceil(float(amount) * 0.38)))
	for index in range(count):
		if particles.size() >= 620: break
		var angle := rng.randf_range(0.0, TAU_VALUE)
		var velocity := Vector2(cos(angle), sin(angle)) * rng.randf_range(speed * 0.55, speed * 1.35)
		var life := rng.randf_range(0.32, 0.78)
		particles.append({"position": Vector2(x, y), "velocity": velocity, "gravity": rng.randf_range(20.0, 65.0), "size": rng.randf_range(1.2, 4.0), "life": life, "max_life": life, "color": color})

func _add_floating_text(x: float, y: float, text: String, color: Color, life: float) -> void:
	if floating_texts.size() >= 36: return
	floating_texts.append({"position": Vector2(x, y), "text": text, "color": color, "life": life, "max_life": life})

func _enemy_distance(a: Dictionary, b: Dictionary) -> float:
	return Vector2(float(a["x"]), float(a["y"])).distance_to(Vector2(float(b["x"]), float(b["y"])))

func _enemy_by_id(enemy_id: int) -> Dictionary:
	for enemy in enemies:
		if int(enemy["id"]) == enemy_id: return enemy
	return {}

func _tower_by_id(tower_id: int) -> Dictionary:
	for tower in towers:
		if int(tower["id"]) == tower_id: return tower
	return {}

func _tower_index_by_id(tower_id: int) -> int:
	for index in range(towers.size()):
		if int(towers[index]["id"]) == tower_id: return index
	return -1

func _nearest_spot(point: Vector2, radius: float) -> int:
	var result := -1
	var best := radius
	for index in range(tower_spots.size()):
		var spot: Dictionary = tower_spots[index]
		var candidate := Vector2(float(spot["x"]), float(spot["y"]))
		var distance_value := point.distance_to(candidate)
		if distance_value < best: best = distance_value; result = index
	return result

func _add_tower(type_id: String, spot_index: int) -> void:
	if not tower_defs.has(type_id) or spot_index < 0 or spot_index >= tower_spots.size(): return
	var spot: Dictionary = tower_spots[spot_index]
	if int(spot["tower_id"]) >= 0: return
	var definition: Dictionary = tower_defs[type_id]
	var cost := int(definition["cost"])
	if gold < cost:
		toast_requested.emit("Recursos insuficientes", "São necessários %d de ouro para esta torre." % cost, "error")
		return
	gold -= cost
	var tower := {"id": next_tower_id, "type": type_id, "level": 1, "spec": "", "x": float(spot["x"]), "y": float(spot["y"]), "spot_index": spot_index, "cooldown": 0.25, "attack_flash": 0.0, "disabled_until": 0.0, "invested": cost}
	next_tower_id += 1
	towers.append(tower)
	spot["tower_id"] = int(tower["id"])
	selected_tower_id = int(tower["id"])
	build_type = ""
	tower_build_count += 1
	_increment_stat("towers_built", 1)
	SaveManager.record_tower_type(type_id)
	if tutorial and tutorial_step == 1:
		tutorial_step = 2
		toast_requested.emit("A rota está sendo lida", "Agora inicie a primeira onda e observe onde a pressão aumenta.", "success")
	AudioManager.build()
	_spawn_burst(float(tower["x"]), float(tower["y"]), Color("#" + definition["color"]), 17, 54.0)
	_add_floating_text(float(tower["x"]), float(tower["y"]) - 25.0, "DEFESA ATIVA", Color("#" + definition["color"]), 0.75)
	_emit_hud()
	queue_redraw()

func _preview_types(wave_number: int) -> Array:
	if wave_number <= 0: return ["basic"]
	var types: Array = ["basic"]
	var world_index: int = stage["world"]
	if wave_number >= 2: types.append("runner")
	if world_index >= 1 and wave_number >= 3: types.append("armored")
	if world_index >= 1 and wave_number >= 5: types.append("shielded")
	if world_index >= 2 and wave_number >= 3: types.append("flying")
	if world_index >= 2 and wave_number >= 5: types.append("healer")
	if world_index >= 3 and wave_number >= 4: types.append("teleporter")
	if world_index >= 3 and wave_number >= 7: types.append("summoner")
	if bool(stage["is_boss"]) and wave_number == max_waves: types.append("boss")
	return types.slice(0, mini(types.size(), 4))

func _finish_battle(result_key: String) -> void:
	if ended:
		return
	ended = true
	result = result_key
	wave_active = false
	spawn_queue.clear()
	var session_earned := maxi(0, gold - 330)
	var stars := 0
	var reward := 0
	var crystals := 0
	if result_key == "victory":
		stars = 1
		if base_hp >= base_max * 0.5:
			stars += 1
		if tower_build_count <= 7:
			stars += 1
		reward = int(round(float(stage["reward"]) * float(difficulty["reward"]))) + session_earned
		crystals = (2 if bool(stage["is_boss"]) else 0) + (1 if stars == 3 else 0)
		SaveManager.data["gold"] = int(SaveManager.data.get("gold", 0)) + reward
		SaveManager.data["crystals"] = int(SaveManager.data.get("crystals", 0)) + crystals
		SaveManager.increment_stat("wins", 1)
		if base_hp >= base_max:
			SaveManager.increment_stat("perfect_wins", 1)
		SaveManager.complete_stage(int(stage["id"]), stars, int(stage["world"]))
		SaveManager.commit()
		AudioManager.stop_music()
		AudioManager.victory()
		toast_requested.emit("Setor estabilizado", "%d estrelas conquistadas." % stars, "success")
	else:
		reward = int(round(session_earned * 0.25))
		if reward > 0:
			SaveManager.data["gold"] = int(SaveManager.data.get("gold", 0)) + reward
			SaveManager.commit()
		AudioManager.stop_music()
		AudioManager.defeat()
		toast_requested.emit("A rota rompeu", "O núcleo ainda pode ser recuperado.", "error")
	var result_payload := {
		"stage_id": int(stage.get("id", 1)), "stage_name": str(stage.get("name", "")),
		"world": int(stage.get("world", 0)), "difficulty": difficulty_key,
		"stars": stars, "gold": reward, "crystals": crystals,
		"time": game_time, "kills": kills, "damage": damage_done,
		"base_hp": base_hp, "base_max": base_max, "wave": wave,
		"tower_count": tower_build_count, "is_boss": bool(stage.get("is_boss", false))
	}
	_emit_hud()
	battle_finished.emit(result_key, result_payload)

func _draw() -> void:
	if not active:
		return
	var shake := screen_shake if not bool(SaveManager.setting("reduced_motion", false)) else 0.0
	var offset := Vector2(sin(game_time * 89.0) * shake * 7.0, cos(game_time * 73.0) * shake * 5.0)
	var world: Dictionary = worlds[int(stage["world"])]
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color("#0e2029"))
	draw_set_transform(FIELD_ORIGIN + offset, 0.0, FIELD_SCALE)
	_draw_background(world)
	_draw_path(world)
	_draw_spots(world)
	if pending_skill != "":
		var cursor := (get_global_mouse_position() - FIELD_ORIGIN) / FIELD_SCALE
		var radius := 84.0 if pending_skill == "meteor" else 120.0
		draw_circle(cursor, radius, Color(1, 0.8, 0.4, 0.12))
		draw_arc(cursor, radius, 0, TAU, 48, Color("#ffdc85"), 3, true)
	_draw_effects()
	if selected_tower_id >= 0:
		var selected := _tower_by_id(selected_tower_id)
		if not selected.is_empty():
			var selected_stats := _tower_stats(selected)
			draw_circle(Vector2(selected["x"], selected["y"]), selected_stats["range"], Color(0.45, 0.9, 0.95, 0.045))
			draw_arc(Vector2(selected["x"], selected["y"]), selected_stats["range"], 0.0, TAU_VALUE, 80, Color("#75e5ef88"), 1.2, true)
	if build_type != "":
		var build_def: Dictionary = tower_defs[build_type]
		var build_color := Color("#" + build_def["color"])
		for spot in tower_spots:
			if int(spot["tower_id"]) >= 0: continue
			draw_circle(Vector2(spot["x"], spot["y"]), 24.0 + sin(game_time * 3.0 + int(spot["id"])) * 2.0, Color(build_color, 0.08))
			draw_arc(Vector2(spot["x"], spot["y"]), 24.0, 0.0, TAU_VALUE, 30, Color(build_color, 0.72), 1.5, true)
	for tower in towers: _draw_tower(tower)
	for enemy in enemies:
		if not bool(enemy["dead"]): _draw_enemy(enemy)
	for projectile in projectiles: _draw_projectile(projectile)
	_draw_hero()
	_draw_particles()
	_draw_floating_texts()
	if not boss.is_empty() and not bool(boss["dead"]): _draw_boss_bar(boss)
	_draw_base_and_portal(world)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_background(world: Dictionary) -> void :
	terrain_art.draw_ground(self, int(stage["world"]))
	var accent: = Color("#" + str(world["accent"]))
	for i in range(22):
		var p: = Vector2(fmod(i * 131.0 + game_time * 6.0, 1280.0), fmod(i * 73.0 + game_time * (12.0 if world["key"] == "frozen" else 2.0), 720.0))
		draw_circle(p, 1.4, Color(accent, 0.38))

func _draw_path(_world: Dictionary) -> void :
	terrain_art.draw_route(self, PackedVector2Array(path_points))

func _draw_spots(world: Dictionary) -> void:
	for spot in tower_spots:
		var position := Vector2(spot["x"], spot["y"])
		var occupied := int(spot["tower_id"]) >= 0
		draw_circle(position, 21.0 if occupied else 18.0, Color("#040a1499"))
		draw_arc(position, 21.0 if occupied else 18.0, 0.0, TAU_VALUE, 32, Color("#" + world["accent"] + ("55" if occupied else "78")), 1.0, true)
		if not occupied:
			var diamond := PackedVector2Array([position + Vector2(0, -6), position + Vector2(6, 0), position + Vector2(0, 6), position + Vector2(-6, 0)])
			draw_polyline(diamond, Color("#" + world["accent"] + "6a"), 1.0, true)

func _draw_tower(tower: Dictionary) -> void :
	var position: = Vector2(tower["x"], tower["y"])
	var skin: String = str(SaveManager.data.get("equipped_skin", "default"))
	if skin not in ["default", "dusk", "ember"]: skin = "default"
	var texture: = _art_texture("towers/" + str(tower["type"]) + "_" + skin)
	var attack: float = clampf(float(tower["attack_flash"]) / 0.14, 0, 1)
	var color: = Color("#" + str(tower_defs[tower["type"]]["color"]))
	var scale_value: = 1.0 + (int(tower["level"]) - 1) * 0.07
	var size: = Vector2(55, 64) * scale_value
	draw_texture_rect(texture, Rect2(position - Vector2(size.x * 0.5, size.y * 0.82) + Vector2(0, attack * 2), size), false)
	if int(tower["id"]) == selected_tower_id:
		draw_arc(position, 28, 0, TAU, 40, Color(color, 0.85), 2, true)
	for level in range(int(tower["level"])):
		draw_circle(position + Vector2((level - (int(tower["level"]) - 1) * 0.5) * 7, 15), 2.4, Color("#f1d49a"))
	if str(tower.get("spec", "")) != "":
		draw_colored_polygon(PackedVector2Array([position + Vector2(19, -28), position + Vector2(27, -22), position + Vector2(19, -16)]), color)
	if float(tower["disabled_until"]) > game_time:
		draw_circle(position + Vector2(0, -15), 24, Color("#08111c99"))
		draw_line(position + Vector2(-12, -28), position + Vector2(12, -4), Color("#ff8eb1"), 3, true)

func _draw_enemy(enemy: Dictionary) -> void:
	var position := Vector2(float(enemy["x"]), float(enemy["y"]))
	if bool(enemy["flying"]): position.y -= 17.0 + sin(game_time * 5.0 + float(enemy["progress"]) * 10.0) * 3.0
	var color: Color = Color.WHITE if float(enemy["hit_flash"]) > 0.0 else enemy["color"]
	var radius: float = float(enemy["radius"])
	draw_circle(position, radius + 4.0 if enemy["type"] == "boss" else radius + 2.0, Color(color, 0.1))
	if enemy["type"] == "boss":
		draw_circle(position, 30.0 + sin(game_time * 2.0) * 1.5, Color(color, 0.18))
		draw_arc(position, 30.0, 0.0, TAU_VALUE, 40, color, 2.2, true)
		var crown := PackedVector2Array([position + Vector2(0, -29), position + Vector2(9, -14), position + Vector2(27, -9), position + Vector2(16, 6), position + Vector2(18, 26), position + Vector2(0, 17), position + Vector2(-18, 26), position + Vector2(-16, 6), position + Vector2(-27, -9), position + Vector2(-9, -14)])
		draw_colored_polygon(crown, Color(color, 0.22)); draw_polyline(crown, color, 2.0, true); draw_rect(Rect2(position - Vector2(5, 2), Vector2(10, 4)), color)
	else:
		match enemy["type"]:
			"runner":
				draw_colored_polygon(PackedVector2Array([position + Vector2(14, 0), position + Vector2(-8, -10), position + Vector2(-4, 0), position + Vector2(-8, 10)]), Color(color, 0.3)); draw_polyline(PackedVector2Array([position + Vector2(14, 0), position + Vector2(-8, -10), position + Vector2(-4, 0), position + Vector2(-8, 10)]), color, 1.7, true)
			"tank":
				var shape := PackedVector2Array([position + Vector2(-14, -11), position + Vector2(-5, -18), position + Vector2(9, -15), position + Vector2(17, -3), position + Vector2(12, 14), position + Vector2(-7, 17), position + Vector2(-17, 6)])
				draw_colored_polygon(shape, Color(color, 0.28)); draw_polyline(shape, color, 2.0, true); draw_rect(Rect2(position - Vector2(5, 4), Vector2(10, 8)), color)
			"armored":
				_draw_rotated_box(position, Vector2(20, 20), PI / 4.0, Color(color, 0.3), color); draw_circle(position, 3.0, color)
			"shielded":
				draw_circle(position, 12.0, Color(color, 0.3)); draw_arc(position, 12.0, 0.0, TAU_VALUE, 24, color, 1.5, true); draw_arc(position + Vector2(-2, 0), 18.0, -1.25, 1.25, 16, Color("#a8e7ff"), 3.0, true)
			"flying":
				_draw_ellipse(position, Vector2(13, 8), Color(color, 0.3), color)
				draw_arc(position + Vector2(-8, 0), 12.0, -2.5, 1.0, 16, color, 1.2, true); draw_arc(position + Vector2(8, 0), 12.0, 2.1, 5.6, 16, color, 1.2, true)
			"healer":
				draw_circle(position, 12.0, Color(color, 0.3)); draw_arc(position, 12.0, 0.0, TAU_VALUE, 24, color, 1.5, true); draw_rect(Rect2(position - Vector2(3, 8), Vector2(6, 16)), color); draw_rect(Rect2(position - Vector2(8, 3), Vector2(16, 6)), color)
			"saboteur":
				_draw_rotated_box(position, Vector2(18, 18), PI / 4.0, Color(color, 0.3), color); draw_line(position + Vector2(-6, 5), position + Vector2(6, -5), color, 1.5, true)
			"summoner":
				draw_circle(position, 13.0, Color(color, 0.3)); draw_arc(position, 13.0, 0.0, TAU_VALUE, 24, color, 1.5, true); draw_arc(position, 6.0 + sin(game_time * 4.0) * 1.5, 0.0, TAU_VALUE, 20, color, 1.3, true)
			"teleporter":
				draw_circle(position, 12.0, Color(color, 0.3)); draw_arc(position, 12.0, 0.0, TAU_VALUE, 24, color, 1.5, true); draw_arc(position, 6.0, 0.0, TAU_VALUE, 20, color, 1.0, true); draw_line(position + Vector2(-15, 0), position + Vector2(15, 0), color, 1.3, true)
			_:
				draw_circle(position, 11.0, Color(color, 0.3)); draw_arc(position, 11.0, 0.0, TAU_VALUE, 24, color, 1.5, true); draw_rect(Rect2(position - Vector2(3, 3), Vector2(6, 6)), color)
	var bar_width := radius * 2.8
	draw_rect(Rect2(position + Vector2(-bar_width / 2.0, -radius - 13.0), Vector2(bar_width, 4.0)), Color("#02060eb5"))
	draw_rect(Rect2(position + Vector2(-bar_width / 2.0, -radius - 13.0), Vector2(bar_width * clampf(float(enemy["hp"]) / float(enemy["max_hp"]), 0.0, 1.0), 4.0)), color)
	if float(enemy["max_shield"]) > 0.0 and float(enemy["shield"]) > 0.0: draw_rect(Rect2(position + Vector2(-bar_width / 2.0, -radius - 18.0), Vector2(bar_width * clampf(float(enemy["shield"]) / float(enemy["max_shield"]), 0.0, 1.0), 2.0)), Color("#74c8ff"))
	if float(enemy["stun"]) > 0:
		draw_line(position + Vector2(-radius, 0), position + Vector2(radius, 0), Color("#c9f4ff"), 3, true)
	elif float(enemy["slow_time"]) > 0:
		draw_arc(position, radius + 3, 0, PI, 16, Color("#99dbfa"), 2, true)

func _draw_rotated_box(center: Vector2, size: Vector2, angle: float, fill: Color, stroke: Color) -> void:
	var points := PackedVector2Array()
	for corner in [Vector2(-size.x / 2.0, -size.y / 2.0), Vector2(size.x / 2.0, -size.y / 2.0), Vector2(size.x / 2.0, size.y / 2.0), Vector2(-size.x / 2.0, size.y / 2.0)]: points.append(center + corner.rotated(angle))
	draw_colored_polygon(points, fill)
	points.append(points[0])
	draw_polyline(points, stroke, 1.5, true)

func _draw_ellipse(center: Vector2, radii: Vector2, fill: Color, stroke: Color) -> void:
	var points := PackedVector2Array()
	for index in range(25):
		var angle := TAU_VALUE * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, fill)
	draw_polyline(points, stroke, 1.5, true)

func _draw_projectile(projectile: Dictionary) -> void:
	var position := Vector2(projectile["x"], projectile["y"])
	var angle: float = float(projectile["angle"])
	var color: Color = projectile["color"]
	var direction := Vector2.RIGHT.rotated(angle)
	var side := direction.orthogonal()
	draw_circle(position, 3.0, Color(color, 0.22))
	if projectile["projectile"] == "arrow" or projectile["projectile"] == "bolt":
		draw_line(position - direction * 11.0, position + direction * 9.0, color, 2.0 if projectile["projectile"] == "arrow" else 3.0, true)
		draw_colored_polygon(PackedVector2Array([position + direction * 12.0, position + direction * 4.0 + side * 4.0, position + direction * 4.0 - side * 4.0]), color)
	elif projectile["projectile"] == "orb":
		draw_circle(position, 5.0 + sin(game_time * 12.0) * 1.0, color)
		draw_arc(position, 9.0, 0.0, TAU_VALUE, 20, Color(color, 0.45), 1.2, true)
	elif projectile["projectile"] == "shell":
		draw_circle(position, 6.0, color)
		draw_circle(position, 2.0, Color("#ffe2a6"))
	elif projectile["projectile"] == "shard":
		draw_colored_polygon(PackedVector2Array([position + direction * 10.0, position - direction * 4.0 + side * 5.0, position - direction * 8.0, position - direction * 4.0 - side * 5.0]), color)
	else:
		draw_circle(position, 4.0 + sin(game_time * 18.0), color)

func _draw_hero() -> void :
	if hero.is_empty(): return
	if float(hero["respawn"]) > 0.0 and int(game_time * 8.0) % 2 == 0: return
	var p: = Vector2(hero["x"], hero["y"])
	var moving: = p.distance_to(Vector2(hero["target_x"], hero["target_y"])) > 3
	var bounce: = sin(game_time * 12) * 2 if moving else 0.0
	var attack: = float(hero["attack_flash"]) / 0.14
	var tint: = Color(1, 1, 1, 0.6 if float(hero["invulnerable"]) > 0 else 1.0)
	draw_texture_rect(_art_texture("heroes/" + str(hero["id"])), Rect2(p + Vector2(-27 + attack * float(hero["facing"]) * 3, -49 + bounce), Vector2(54, 63)), false, tint)
	var hp: = clampf(float(hero["hp"]) / maxf(float(hero["max_hp"]), 1), 0, 1)
	draw_rect(Rect2(p + Vector2(-20, 17), Vector2(40, 5)), Color("#101c26"))
	draw_rect(Rect2(p + Vector2(-19, 18), Vector2(38 * hp, 3)), Color("#84d3a0"))

func _draw_boss_bar(boss_enemy: Dictionary) -> void:
	var width := 360.0
	var position := Vector2((1280.0 - width) / 2.0, 672.0)
	var ratio := clampf(float(boss_enemy["hp"]) / maxf(float(boss_enemy["max_hp"]), 1.0), 0.0, 1.0)
	var color: Color = boss_enemy["color"]
	draw_rect(Rect2(position, Vector2(width, 23)), Color("#030710dd")); draw_rect(Rect2(position + Vector2(5, 5), Vector2((width - 10.0) * ratio, 13)), color); draw_rect(Rect2(position, Vector2(width, 23)), Color(color, 0.55), false, 1.0)
	_draw_text(position + Vector2(0, 16), "%s · FASE %d" % [str(boss_enemy["name"]).to_upper(), int(boss_enemy["boss_phase"])], 10, Color("#f6f8ff"), HORIZONTAL_ALIGNMENT_CENTER, width)

func _draw_base_and_portal(world: Dictionary) -> void:
	var start := _point_on_path(0.0) + Vector2(14.0, 0.0)
	var end := _point_on_path(1.0) - Vector2(18.0, 0.0)
	draw_circle(start, 27.0 + sin(game_time * 2.0) * 2.0, Color("#ff71872c")); draw_arc(start, 25.0, 0.0, TAU_VALUE, 36, Color("#ff7187cc"), 2.0, true); draw_arc(start, 15.0, 0.0, TAU_VALUE, 28, Color("#ff718799"), 1.0, true); draw_circle(start, 4.0, Color("#ff7187"))
	var diamond := PackedVector2Array([end + Vector2(0, -21), end + Vector2(21, 0), end + Vector2(0, 21), end + Vector2(-21, 0)])
	draw_colored_polygon(diamond, Color("#75e5ef20")); draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color("#75e5efcc"), 2.0, true); draw_circle(end, 10.0 + sin(game_time * 2.3) * 2.0, Color("#" + world["accent"]))

func _draw_effects() -> void:
	for effect in effects:
		var max_life := maxf(float(effect.get("max_life", 1.0)), 0.001)
		var progress := 1.0 - float(effect["life"]) / max_life
		var alpha := clampf(float(effect["life"]) / max_life, 0.0, 1.0)
		var color: Color = effect.get("color", Color("#75e5ef"))
		match effect["kind"]:
			"chain":
				var from_point: Vector2 = effect["from"]; var to_point: Vector2 = effect["to"]; var midpoint := from_point.lerp(to_point, 0.5) + Vector2(sin(progress * 20.0) * 9.0, cos(progress * 17.0) * 7.0)
				draw_polyline(PackedVector2Array([from_point, midpoint, to_point]), Color(color, alpha), 3.0, true)
			"hit", "magic_hit", "frost_hit", "shield_hit":
				var position := Vector2(effect["x"], effect["y"]); var radius := 8.0 + progress * float(effect.get("radius", 22.0))
				draw_arc(position, radius, 0.0, TAU_VALUE, 28, Color(color, alpha), 1.8, true)
				if effect["kind"] == "frost_hit":
					for branch in range(4): draw_line(position, position + Vector2.UP.rotated(float(branch) * PI / 2.0) * (16.0 + progress * 9.0), Color(color, alpha), 1.4, true)
				if effect["kind"] == "shield_hit": draw_arc(position, 16.0 + progress * 13.0, -1.25, 1.25, 18, Color("#a8e7ff"), 2.5, true)
			"explosion":
				var explosion_position := Vector2(effect["x"], effect["y"]); var explosion_radius := 14.0 + progress * float(effect.get("radius", 50.0))
				draw_circle(explosion_position, explosion_radius, Color(color, alpha * 0.15)); draw_arc(explosion_position, explosion_radius, 0.0, TAU_VALUE, 34, Color(color, alpha), 2.0, true)
				for branch in range(6):
					var direction := Vector2.RIGHT.rotated(float(branch) * TAU_VALUE / 6.0); draw_line(explosion_position + direction * explosion_radius * 0.45, explosion_position + direction * explosion_radius * 1.25, Color(color, alpha), 1.5, true)
			"heal":
				var heal_position := Vector2(effect["x"], effect["y"]); draw_line(heal_position - Vector2(8, 0), heal_position + Vector2(8, 0), Color(color, alpha), 2.0, true); draw_line(heal_position - Vector2(0, 8), heal_position + Vector2(0, 8), Color(color, alpha), 2.0, true)
			"glitch":
				var glitch_position := Vector2(effect["x"], effect["y"]); draw_rect(Rect2(glitch_position - Vector2(21, 21), Vector2(42, 42)), Color(color, alpha), false, 1.5); draw_rect(Rect2(glitch_position + Vector2(-17, -2), Vector2(34, 4)), Color(color, alpha * 0.65))
			"summon":
				var summon_position := Vector2(effect["x"], effect["y"]); draw_arc(summon_position, 12.0 + progress * 20.0, 0.0, TAU_VALUE, 30, Color(color, alpha), 2.0, true); draw_arc(summon_position, 5.0 + progress * 7.0, 0.0, TAU_VALUE, 22, Color(color, alpha), 1.2, true)
			"telegraph":
				var telegraph_position := Vector2(effect["x"], effect["y"]); draw_arc(telegraph_position, 18.0 + progress * 14.0, 0.0, TAU_VALUE, 32, Color(color, alpha), 1.6, true); draw_line(telegraph_position - Vector2(11, 0), telegraph_position + Vector2(11, 0), Color(color, alpha), 1.0, true); draw_line(telegraph_position - Vector2(0, 11), telegraph_position + Vector2(0, 11), Color(color, alpha), 1.0, true)
			"teleport":
				var teleport_position := Vector2(effect["x"], effect["y"]); draw_arc(teleport_position, 12.0 + (1.0 - progress) * 25.0, 0.0, TAU_VALUE, 30, Color(color, alpha), 2.5, true)
			"boss_phase":
				var boss_position := Vector2(effect["x"], effect["y"]); draw_arc(boss_position, 28.0 + progress * 80.0, 0.0, TAU_VALUE, 50, Color(color, alpha), 2.0, true); draw_arc(boss_position, 18.0 + progress * 40.0, 0.0, TAU_VALUE, 40, Color(color, alpha), 1.0, true)
			"roots":
				var root_position := Vector2(effect["x"], effect["y"])
				for branch in range(6):
					var root_direction := Vector2.RIGHT.rotated(float(branch) * TAU_VALUE / 6.0)
					draw_line(root_position, root_position + root_direction * 28.0, Color(color, alpha), 2.0, true)
			"sandstorm", "blizzard":
				var storm_position := Vector2(effect["x"], effect["y"])
				for branch in range(5): draw_arc(storm_position, 25.0 + branch * 11.0 + progress * 45.0, -1.6, 1.4, 28, Color(color, alpha), 2.0, true)
			"emp":
				var emp_position := Vector2(effect["x"], effect["y"]); for branch in range(3): draw_arc(emp_position, 25.0 + (branch + progress) * 55.0, 0.0, TAU_VALUE, 48, Color(color, alpha), 1.6, true)
			"rift":
				var rift_position := Vector2(effect["x"], effect["y"]); _draw_ellipse(rift_position, Vector2(20.0 + progress * 35.0, 45.0 + progress * 68.0), Color(0, 0, 0, 0), Color(color, alpha))
			"field":
				var field_position := Vector2(effect["x"], effect["y"]); draw_circle(field_position, float(effect["radius"]), Color(color, alpha * 0.08)); draw_arc(field_position, float(effect["radius"]), 0.0, TAU_VALUE, 48, Color(color, alpha), 1.5, true)
			"clone":
				var clone_position := Vector2(effect["x"], effect["y"]); draw_arc(clone_position, 15.0, 0.0, TAU_VALUE, 24, Color(color, alpha * 0.48), 1.5, true); draw_polyline(PackedVector2Array([clone_position + Vector2(-10, 18), clone_position + Vector2(0, -16), clone_position + Vector2(10, 18)]), Color(color, alpha * 0.48), 1.5, true)
			"meteor":
				var meteor_position := Vector2(effect["x"], effect["y"]); draw_arc(meteor_position, 52.0, 0.0, TAU_VALUE, 42, Color(color, alpha * 0.7), 1.0, true); draw_circle(meteor_position + Vector2(112.0 - progress * 132.0, -112.0 + progress * 132.0), 8.0 + progress * 4.0, Color(color, alpha))
			"freeze_all":
				var freeze_position := Vector2(effect["x"], effect["y"]); draw_arc(freeze_position, 44.0 + progress * 480.0, 0.0, TAU_VALUE, 60, Color(color, alpha), 2.0, true)
				for branch in range(12):
					var freeze_direction := Vector2.RIGHT.rotated(float(branch) * TAU_VALUE / 12.0)
					draw_line(freeze_position + freeze_direction * 30.0, freeze_position + freeze_direction * (80.0 + progress * 240.0), Color(color, alpha), 1.0, true)
			"reinforce":
				draw_arc(Vector2(effect["x"], effect["y"]), 50.0 + progress * 330.0, 0.0, TAU_VALUE, 60, Color(color, alpha), 2.0, true)
			"move_marker":
				var marker := Vector2(effect["x"], effect["y"]); draw_arc(marker, 5.0 + progress * 10.0, 0.0, TAU_VALUE, 22, Color(color, alpha), 1.5, true); draw_line(marker - Vector2(11, 0), marker + Vector2(11, 0), Color(color, alpha), 1.0, true); draw_line(marker - Vector2(0, 11), marker + Vector2(0, 11), Color(color, alpha), 1.0, true)
			"hero_slash":
				draw_arc(Vector2(effect["x"], effect["y"]), 16.0 + progress * 16.0, -1.9, 0.35, 20, Color(color, alpha), 2.4, true)
			"ultimate", "ability":
				draw_arc(Vector2(effect["x"], effect["y"]), 18.0 + progress * (118.0 if effect["kind"] == "ultimate" else 48.0), 0.0, TAU_VALUE, 44, Color(color, alpha), 2.5 if effect["kind"] == "ultimate" else 1.7, true)
			"boss_banner":
				draw_line(Vector2(390, 94), Vector2(530, 94), Color(color, alpha), 1.0, true); draw_line(Vector2(750, 94), Vector2(890, 94), Color(color, alpha), 1.0, true)

func _draw_particles() -> void:
	for particle in particles:
		var alpha := clampf(float(particle["life"]) / float(particle["max_life"]), 0.0, 1.0)
		var color: Color = particle["color"]
		draw_circle(particle["position"], float(particle["size"]), Color(color, alpha))

func _draw_floating_texts() -> void:
	for text in floating_texts:
		var alpha := clampf(float(text["life"]) / float(text["max_life"]), 0.0, 1.0)
		_draw_text(text["position"], str(text["text"]), 11, Color(text["color"], alpha), HORIZONTAL_ALIGNMENT_CENTER, 180.0)

func _draw_text(position: Vector2, text: String, size: int, color: Color, alignment: int = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, position, text, alignment, width, size, color)

func _emit_hud() -> void:
	if not active: return
	var current_world: Dictionary = worlds[int(stage["world"])]
	var current_preview := _preview_types(wave) if wave_active else _preview_types(wave + 1)
	var hero_definition: Dictionary = hero_defs.get(hero.get("id", selected_hero_id), hero_defs["kael"])
	hud_changed.emit({
		"base_hp": base_hp, "base_max": base_max, "wave": wave, "max_waves": max_waves, "wave_active": wave_active,
		"intermission": intermission, "remaining": spawn_queue.size() + enemies.size(), "preview": current_preview,
		"gold": gold, "speed": game_speed, "world_name": current_world["name"], "stage_name": stage["name"], "weather": current_world["weather"],
		"boss_name": boss.get("name", ""), "boss_hp": boss.get("hp", 0.0), "boss_max_hp": boss.get("max_hp", 0.0), "boss_phase": boss.get("boss_phase", 0),
		"hero": {"id": hero.get("id", "kael"), "name": hero_definition["name"], "role": hero_definition["role"], "rarity": hero_definition["rarity"], "color": hero_definition["color"], "sigil": hero_definition["sigil"], "level": hero.get("level", 1), "hp": hero.get("hp", 0.0), "max_hp": hero.get("max_hp", 1.0), "xp": hero.get("xp", 0.0), "next_xp": hero.get("next_xp", 100.0), "ultimate": hero.get("ultimate", 0.0), "skills": hero_definition["skills"], "cooldowns": hero.get("skill_cooldowns", []), "ultimate_name": hero_definition["ultimate"], "respawn": hero.get("respawn", 0.0)},
		"globals": global_cooldowns.duplicate(), "selected_tower": _selected_tower_payload(), "build_type": build_type, "tutorial": tutorial, "tutorial_step": tutorial_step, "ended": ended, "result": result
	})

func _selected_tower_payload() -> Dictionary:
	var tower := _tower_by_id(selected_tower_id)
	if tower.is_empty(): return {}
	var definition: Dictionary = tower_defs[tower["type"]]
	var stats := _tower_stats(tower)
	var upgrade_cost := int(round(float(definition["cost"]) * (0.7 + int(tower["level"]) * 0.52))) if int(tower["level"]) < 3 else 0
	return {"id": tower["id"], "type": tower["type"], "name": definition["name"], "role": definition["role"], "color": definition["color"], "level": tower["level"], "spec": tower.get("spec", ""), "damage": stats["damage"], "cooldown": stats["cooldown"], "range": stats["range"], "invested": tower["invested"], "sell": int(round(int(tower["invested"]) * 0.68)), "upgrade_cost": upgrade_cost, "can_upgrade": int(tower["level"]) < 3 and gold >= upgrade_cost, "disabled": float(tower["disabled_until"]) > game_time, "branches": definition["branches"]}
