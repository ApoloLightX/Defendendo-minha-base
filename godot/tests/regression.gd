extends SceneTree

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	var b = app.battle
	for world in range(5):
		app.start_battle(1 + world * 5, "normal", "kael")
		b.set_process(false)
		b.gold = 10000
		for spot in b.tower_spots:
			b.select_build_type("archer")
			var screen_point = b.FIELD_ORIGIN + Vector2(spot.x, spot.y) * b.FIELD_SCALE
			b._handle_pointer(screen_point)
		check(b.towers.size() == b.tower_spots.size(), "All build sites accessible in world %d" % world)
		for point in b.path_points:
			check(point.x < 1280 and point.y < 720, "Route fits logical map")
		b.start_next_wave()
		for frame in range(180): b._process(1.0 / 60.0)
	app.start_battle(1, "normal", "kael")
	b.set_process(false)
	b.use_hero_skill(0)
	check(b.hero.skill_cooldowns[0] == 0, "Empty melee attack is not charged")
	b._spawn_enemy("tank")
	var enemy: Dictionary = b.enemies[0]
	enemy.x = b.hero.x
	enemy.y = b.hero.y
	var hp: float = enemy.hp
	b._update_hero(0.1)
	check(enemy.hp < hp, "Hero attacks with definition range")
	b.use_hero_skill(2)
	check(b.hero.x == b.hero.target_x and b.hero.y == b.hero.target_y, "Dash replaces movement order")
	b.use_global_skill("meteor")
	check(b.pending_skill == "meteor" and b.global_cooldowns.meteor == 0, "Aiming consumes no cooldown")
	b.cancel_command()
	check(b.pending_skill == "" and b.global_cooldowns.meteor == 0, "Cancel is free")
	b.use_global_skill("meteor")
	b._handle_pointer(b.FIELD_ORIGIN + Vector2(400, 350) * b.FIELD_SCALE)
	check(b.pending_skill == "" and b.global_cooldowns.meteor > 0, "Tap commits cast")
	check(b.effects[-1].x == 400 and is_equal_approx(b.effects[-1].y, 350), "Meteor uses chosen location")
	app.start_battle(1, "normal", "lyra")
	b.set_process(false)
	b.hero.ultimate = 100
	b.use_hero_ultimate()
	b.paused = true
	b._process(0.05)
	check(b.scheduled_arrows.size() == 9, "Pause freezes ultimate")
	app.start_battle(2, "normal", "kael")
	b.set_process(false)
	check(b.scheduled_arrows.is_empty(), "Delayed hits never cross battles")
	b.wave = 1
	b.wave_active = false
	b.intermission = 0.01
	b._update_wave(0.02)
	check(b.wave == 2 and b.wave_active, "Intermission starts next wave")
	await process_frame
	for key in ["hero_xp_bar", "boss_bar"]:
		print(key, " size=", app.ui.battle_refs[key].size)
		check(app.ui.battle_refs[key].size.y <= 10, "Progress bar respects requested height")
	var buttons: Array = []
	for key in ["start_wave", "pause", "leave", "speed_1", "speed_2", "speed_3"]:
		buttons.append(app.ui.battle_refs[key])
	for i in range(buttons.size()):
		check(buttons[i].get_global_rect().end.x <= 1264, "HUD inside viewport")
		for j in range(i + 1, buttons.size()):
			check(not buttons[i].get_global_rect().intersects(buttons[j].get_global_rect()), "HUD buttons do not overlap")
	print("REGRESSION FAILURES: ", failures)
	app.queue_free()
	await process_frame
	quit(1 if failures else 0)
