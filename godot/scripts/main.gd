extends Node

var backdrop: AetherfallBackdrop
var battle: BattleController
var ui: MainUI

func _ready() -> void:
	backdrop = AetherfallBackdrop.new()
	backdrop.name = "CinematicBackdrop"
	add_child(backdrop)

	battle = BattleController.new()
	battle.name = "BattleController"
	add_child(battle)

	ui = MainUI.new()
	ui.name = "MainUI"
	add_child(ui)
	ui.setup(self, battle, backdrop)

	battle.hud_changed.connect(ui.update_battle_hud)
	battle.toast_requested.connect(ui.show_toast)
	battle.battle_finished.connect(ui.show_battle_result)
	SaveManager.data_changed.connect(ui.refresh_all)

	show_home()

func show_home() -> void:
	battle.stop_battle()
	backdrop.set_scene("home", 0)
	ui.show_home()

func show_map() -> void:
	battle.stop_battle()
	backdrop.set_scene("map", ui.selected_world)
	ui.show_map()

func start_battle(stage_id: int, difficulty_key: String, hero_id: String) -> void:
	backdrop.visible = false
	battle.start_battle(stage_id, difficulty_key, hero_id)
	ui.show_battle()

func leave_battle() -> void:
	battle.stop_battle()
	backdrop.set_scene("map", ui.selected_world)
	ui.show_map()

func set_map_world(world_index: int) -> void:
	ui.selected_world = clampi(world_index, 0, 4)
	backdrop.set_scene("map", ui.selected_world)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed() and event.keycode == KEY_ESCAPE and ui.current_screen == "battle":
		ui.toggle_pause_overlay()
