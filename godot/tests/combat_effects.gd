extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.start_battle(1,"normal","kael")
	var b = app.battle
	b.set_process(false)
	var enemy: Dictionary = b._spawn_enemy("tank")
	enemy.progress = 0.5
	b._update_enemies(0.1)
	assert(enemy.walk_clock > 0)
	var clock: float = enemy.walk_clock
	enemy.stun = 2
	b._update_enemies(0.1)
	assert(enemy.walk_clock == clock, "Frozen enemies must stop walking")
	b.cast_target = Vector2(enemy.x,enemy.y)
	var hp: float = enemy.hp
	b.use_global_skill("meteor",true)
	b._update_effects(0.30)
	assert(enemy.hp == hp, "Meteor must not hit before impact")
	b._update_effects(0.051)
	assert(enemy.hp < hp, "Meteor damage must coincide with impact")
	var after: float = enemy.hp
	b._update_effects(0.1)
	assert(enemy.hp == after, "One meteor has one damage event")
	b.effects.clear()
	b._kill_enemy(enemy)
	assert(b.effects.any(func(e): return e.kind == "enemy_fall"))
	b._update_effects(0.4)
	assert(not b.effects.any(func(e): return e.kind == "enemy_fall"), "Death snapshots expire")
	print("COMBAT EFFECTS PASS")
	app.queue_free()
	await process_frame
	quit()
