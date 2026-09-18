class_name MainUI
extends Control
func _art_image(parent: Node, key: String, location: Vector2, dimensions: Vector2) -> void :
	var artwork: = TextureRect.new()
	artwork.position = location
	artwork.size = dimensions
	artwork.texture = load("res://art/" + key + ".png")
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(artwork)


signal start_requested(stage_id: int, difficulty_key: String, hero_id: String)

const VIEW_SIZE := Vector2(1280.0, 720.0)
const BG := Color("#07101d")
const PANEL := Color("#0b1728e8")
const PANEL_SOFT := Color("#10243acc")
const PANEL_DEEP := Color("#050914ee")
const TEXT := Color("#f1f5ff")
const MUTED := Color("#93a8c4")
const CYAN := Color("#75e5ef")
const GREEN := Color("#72e4b3")
const GOLD := Color("#f2bd6b")
const RED := Color("#ff7187")
const PURPLE := Color("#b196ff")

var app: Node
var battle: BattleController
var backdrop: AetherfallBackdrop
var current_screen := "home"
var selected_world := 0
var selected_stage := 1
var selected_difficulty := "normal"
var selected_hero := "kael"
var overlay_kind := ""

var screen_root: Control
var home_screen: Control
var map_screen: Control
var library_screen: Control
var shop_screen: Control
var missions_screen: Control
var achievements_screen: Control
var settings_screen: Control
var battle_screen: Control
var overlay: Control
var toast_layer: Control

var home_gold_label: Label
var home_crystal_label: Label
var home_progress_label: Label
var map_gold_label: Label
var map_crystal_label: Label
var shop_gold_label: Label
var shop_crystal_label: Label
var battle_refs: Dictionary = {}
var tower_buttons: Dictionary = {}
var hero_skill_buttons: Array = []
var global_skill_buttons: Dictionary = {}
var current_shop_category := "heroes"

func setup(owner: Node, controller: BattleController, scene_backdrop: AetherfallBackdrop) -> void:
	app = owner
	battle = controller
	backdrop = scene_backdrop
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_shell()

func _build_shell() -> void:
	screen_root = Control.new()
	screen_root.name = "Screens"
	screen_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen_root)

	home_screen = _new_screen("Home")
	map_screen = _new_screen("CampaignMap")
	library_screen = _new_screen("Library")
	shop_screen = _new_screen("Shop")
	missions_screen = _new_screen("Missions")
	achievements_screen = _new_screen("Achievements")
	settings_screen = _new_screen("Settings")
	battle_screen = _new_screen("Battle")

	overlay = Control.new()
	overlay.name = "ModalOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	add_child(overlay)

	toast_layer = Control.new()
	toast_layer.name = "ToastLayer"
	toast_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	toast_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast_layer)

func _new_screen(screen_name: String) -> Control:
	var screen := Control.new()
	screen.name = screen_name
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.visible = false
	screen_root.add_child(screen)
	return screen

func show_home() -> void:
	current_screen = "home"
	overlay.visible = false
	_set_screen(home_screen)
	_clear(home_screen)
	_build_home()
	backdrop.set_scene("home", 0)

func show_map() -> void:
	current_screen = "map"
	overlay.visible = false
	_set_screen(map_screen)
	_clear(map_screen)
	_build_map()
	backdrop.set_scene("map", selected_world)

func show_battle() -> void:
	current_screen = "battle"
	overlay.visible = false
	_set_screen(battle_screen)
	_clear(battle_screen)
	_build_battle()

func show_library() -> void:
	current_screen = "library"
	_set_screen(library_screen)
	_clear(library_screen)
	_build_library()
	backdrop.set_scene("home", 0)

func show_shop() -> void:
	current_screen = "shop"
	_set_screen(shop_screen)
	_clear(shop_screen)
	_build_shop()
	backdrop.set_scene("home", 0)

func show_missions() -> void:
	current_screen = "missions"
	_set_screen(missions_screen)
	_clear(missions_screen)
	_build_missions()
	backdrop.set_scene("home", 0)

func show_achievements() -> void:
	current_screen = "achievements"
	_set_screen(achievements_screen)
	_clear(achievements_screen)
	_build_achievements()
	backdrop.set_scene("home", 0)

func show_settings() -> void:
	current_screen = "settings"
	_set_screen(settings_screen)
	_clear(settings_screen)
	_build_settings()
	backdrop.set_scene("home", 0)

func _set_screen(target: Control) -> void:
	for child in screen_root.get_children():
		child.visible = child == target

func _clear(parent: Node) -> void:
	for child in parent.get_children():
		child.free()

func _style(color: Color, radius: int = 12, border: Color = Color(0, 0, 0, 0), border_width: int = 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	box.border_width_left = border_width
	box.border_width_right = border_width
	box.border_width_top = border_width
	box.border_width_bottom = border_width
	box.border_color = border
	box.content_margin_left = 14.0
	box.content_margin_right = 14.0
	box.content_margin_top = 10.0
	box.content_margin_bottom = 10.0
	return box

func _panel(parent: Node, position: Vector2, size: Vector2, color: Color = PANEL, border: Color = Color(0, 0, 0, 0)) -> Panel:
	var panel := Panel.new()
	panel.position = position
	panel.size = size
	panel.add_theme_stylebox_override("panel", _style(color, 14, border, 1 if border.a > 0.0 else 0))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel

func _label(parent: Node, value: String, position: Vector2, size: Vector2, font_size: int = 16, color: Color = TEXT, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = value
	label.position = position
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(parent: Node, value: String, position: Vector2, size: Vector2, callback: Callable = Callable(), accent: Color = CYAN) -> Button:
	var button := Button.new()
	button.text = value
	button.position = position
	button.size = size
	button.custom_minimum_size = Vector2(maxf(size.x, 48.0), maxf(size.y, 48.0))
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", TEXT)
	button.add_theme_stylebox_override("normal", _style(Color("#102138e8"), 10, Color("#26415c"), 1))
	button.add_theme_stylebox_override("hover", _style(Color(accent, 0.24), 10, accent, 1))
	button.add_theme_stylebox_override("pressed", _style(Color(accent, 0.38), 10, accent, 1))
	button.add_theme_stylebox_override("disabled", _style(Color("#09111dde"), 10, Color("#1b2b3c"), 1))
	button.pressed.connect(_button_dispatch.bind(callback))
	parent.add_child(button)
	return button

func _button_dispatch(callback: Callable) -> void:
	AudioManager.ui()
	if callback.is_valid():
		callback.call()

func _title(parent: Node, heading: String, subheading: String = "", show_back: bool = true) -> void:
	if show_back:
		_button(parent, "‹  VOLTAR", Vector2(28, 22), Vector2(118, 48), _on_back, CYAN)
	_label(parent, heading, Vector2(166 if show_back else 36, 22), Vector2(620, 44), 26, TEXT)
	if subheading != "":
		_label(parent, subheading, Vector2(168 if show_back else 38, 62), Vector2(680, 24), 11, MUTED)
	_add_resource_pills(parent, Vector2(1010, 22))

func _add_resource_pills(parent: Node, position: Vector2) -> void:
	var gold_panel := _panel(parent, position, Vector2(112, 42), Color("#101f31e6"), Color("#f2bd6b66"))
	var crystal_panel := _panel(parent, position + Vector2(120, 0), Vector2(112, 42), Color("#101f31e6"), Color("#75e5ef66"))
	var gold_label := _label(gold_panel, "◆ %d" % int(SaveManager.data.get("gold", 0)), Vector2(8, 0), Vector2(96, 42), 14, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	var crystal_label := _label(crystal_panel, "◇ %d" % int(SaveManager.data.get("crystals", 0)), Vector2(8, 0), Vector2(96, 42), 14, CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	if parent == home_screen:
		home_gold_label = gold_label
		home_crystal_label = crystal_label
	elif parent == map_screen:
		map_gold_label = gold_label
		map_crystal_label = crystal_label
	elif parent == shop_screen:
		shop_gold_label = gold_label
		shop_crystal_label = crystal_label
	_update_resource_labels()

func _update_resource_labels() -> void:
	var gold_value := int(SaveManager.data.get("gold", 0))
	var crystal_value := int(SaveManager.data.get("crystals", 0))
	if is_instance_valid(home_gold_label): home_gold_label.text = "◆  %d" % gold_value
	if is_instance_valid(home_crystal_label): home_crystal_label.text = "◇  %d" % crystal_value
	if is_instance_valid(map_gold_label): map_gold_label.text = "◆  %d" % gold_value
	if is_instance_valid(map_crystal_label): map_crystal_label.text = "◇  %d" % crystal_value
	if is_instance_valid(shop_gold_label): shop_gold_label.text = "◆  %d" % gold_value
	if is_instance_valid(shop_crystal_label): shop_crystal_label.text = "◇  %d" % crystal_value

func _build_home() -> void:
	var veil := ColorRect.new()
	veil.color = Color("#05091466")
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	home_screen.add_child(veil)
	_label(home_screen, "AETHERFALL", Vector2(42, 34), Vector2(390, 54), 31, TEXT)
	_label(home_screen, "DEFENSE PROTOCOL", Vector2(45, 82), Vector2(330, 22), 11, CYAN)
	_label(home_screen, "A última luz não se guarda sozinha.", Vector2(42, 154), Vector2(520, 58), 30, TEXT)
	_label(home_screen, "Erga uma linha de defesa. Leia a rota. Faça o impossível durar mais uma onda.", Vector2(45, 218), Vector2(490, 52), 14, MUTED)
	_button(home_screen, "INICIAR DEFESA", Vector2(44, 302), Vector2(238, 58), _on_play, GREEN)
	_button(home_screen, "CONTINUAR CAMPANHA", Vector2(294, 302), Vector2(238, 58), _on_play, CYAN)

	var brief := _panel(home_screen, Vector2(792, 124), Vector2(402, 302), Color("#081524de"), Color("#75e5ef38"))
	_label(brief, "RELATÓRIO DE FRONTEIRA", Vector2(24, 20), Vector2(340, 26), 11, CYAN)
	_label(brief, "SINAL AETHER", Vector2(24, 60), Vector2(180, 24), 12, MUTED)
	_label(brief, "ATIVO", Vector2(220, 60), Vector2(130, 24), 13, GREEN, HORIZONTAL_ALIGNMENT_RIGHT)
	_label(brief, "PRÓXIMA REGIÃO", Vector2(24, 100), Vector2(180, 24), 12, MUTED)
	_label(brief, "FLORESTA ESQUECIDA", Vector2(180, 100), Vector2(170, 24), 12, TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	_label(brief, "COORDENADAS", Vector2(24, 140), Vector2(180, 24), 12, MUTED)
	_label(brief, "N 01° 24' // E 08° 17'", Vector2(160, 140), Vector2(190, 24), 12, TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	var progress := SaveManager.total_stars()
	home_progress_label = _label(brief, "%02d / 75  ESTRELAS DE ROTA" % progress, Vector2(24, 206), Vector2(340, 26), 15, GOLD)
	var progress_bar := ProgressBar.new()
	progress_bar.position = Vector2(24, 246)
	progress_bar.size = Vector2(342, 8)
	progress_bar.max_value = 75
	progress_bar.value = progress
	progress_bar.show_percentage = false
	progress_bar.add_theme_stylebox_override("background", _style(Color("#142437"), 4))
	progress_bar.add_theme_stylebox_override("fill", _style(Color("#f2bd6b"), 4))
	brief.add_child(progress_bar)

	var nav := _panel(home_screen, Vector2(38, 560), Vector2(1204, 104), Color("#07121fe8"), Color("#23415c"))
	_label(nav, "CENTRAL DE COMANDO", Vector2(22, 8), Vector2(220, 22), 10, MUTED)
	var entries := [
		["MAPA", _on_play, CYAN], ["HERÓIS", _on_library, PURPLE], ["TORRES", _on_library, GOLD],
		["LOJA", _on_shop, GOLD], ["MISSÕES", _on_missions, GREEN], ["CONQUISTAS", _on_achievements, PURPLE], ["CONFIG", _on_settings, MUTED]
	]
	for index in range(entries.size()):
		var entry: Array = entries[index]
		_button(nav, str(entry[0]), Vector2(18 + index * 164, 42), Vector2(146, 48), entry[1], entry[2])
	_add_resource_pills(home_screen, Vector2(996, 38))

func _build_map() -> void:
	_title(map_screen, "CARTA DE CAMPANHA", "Cinco regiões. Vinte e cinco decisões. Cada estrela abre uma rota.")
	var worlds := GameData.worlds()
	for index in range(worlds.size()):
		var world: Dictionary = worlds[index]
		var color := Color("#" + str(world["accent"]))
		var tab := _button(map_screen, str(world["short"]), Vector2(34 + index * 158, 105), Vector2(144, 44), _on_world_tab.bind(index), color)
		if index == selected_world:
			tab.add_theme_stylebox_override("normal", _style(Color(color, 0.26), 10, color, 1))

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(28, 174)
	scroll.size = Vector2(1224, 326)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	map_screen.add_child(scroll)
	var row := HBoxContainer.new()
	row.position = Vector2(10, 0)
	row.add_theme_constant_override("separation", 14)
	row.custom_minimum_size = Vector2(1190, 300)
	scroll.add_child(row)
	var world_entry: Dictionary = worlds[selected_world]
	for local_index in range(5):
		var stage_id := selected_world * 5 + local_index + 1
		_add_stage_card(row, stage_id, world_entry, local_index)

	var info := _panel(map_screen, Vector2(32, 526), Vector2(760, 132), Color("#081524e8"), Color("#" + str(world_entry["accent"]) + "55"))
	_label(info, str(world_entry["name"]).to_upper(), Vector2(20, 14), Vector2(350, 28), 17, Color("#" + str(world_entry["accent"])))
	_label(info, str(world_entry["subtitle"]), Vector2(20, 47), Vector2(370, 24), 12, MUTED)
	_label(info, "BOSS // " + str(world_entry["boss"]).to_upper(), Vector2(20, 84), Vector2(350, 22), 11, RED)
	_label(info, str(world_entry["coords"]), Vector2(412, 22), Vector2(310, 24), 12, TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	_label(info, "ESTRELAS NO SETOR  %d / 15" % SaveManager.world_stars(selected_world), Vector2(392, 78), Vector2(330, 24), 12, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)

	var difficulty_panel := _panel(map_screen, Vector2(814, 526), Vector2(438, 132), Color("#081524e8"), Color("#b196ff55"))
	_label(difficulty_panel, "NÍVEL DE AMEAÇA", Vector2(20, 14), Vector2(220, 24), 11, PURPLE)
	_label(difficulty_panel, "Composição e habilidades mudam com a dificuldade.", Vector2(20, 39), Vector2(390, 24), 11, MUTED)
	var keys := ["normal", "hard", "nightmare"]
	for index in range(keys.size()):
		var key: String = keys[index]
		var button := _button(difficulty_panel, str(GameData.difficulties()[key]["label"]), Vector2(20 + index * 134, 76), Vector2(124, 42), _on_difficulty.bind(key), PURPLE)
		if key == selected_difficulty:
			button.add_theme_stylebox_override("normal", _style(Color(PURPLE, 0.25), 10, PURPLE, 1))

func _add_stage_card(parent: Node, stage_id: int, world: Dictionary, local_index: int) -> void:
	var unlocked := SaveManager.is_stage_unlocked(stage_id)
	var stars := int(SaveManager.data["stage_stars"].get(str(stage_id), 0))
	var color := Color("#" + str(world["accent"]))
	var card := _panel(parent, Vector2.ZERO, Vector2(226, 292), Color("#091624e8"), Color(color, 0.38))
	card.custom_minimum_size = Vector2(226, 292)
	var eyebrow := "BOSS // FASE %02d" % stage_id if local_index == 4 else "SETOR %02d" % stage_id
	_label(card, eyebrow, Vector2(16, 14), Vector2(195, 22), 10, RED if local_index == 4 else color)
	_label(card, str(world["stages"][local_index]), Vector2(16, 40), Vector2(195, 52), 16, TEXT)
	_label(card, str(world["stage_subtitles"][local_index]), Vector2(16, 96), Vector2(195, 34), 11, MUTED)
	var stars_text := "★".repeat(stars) + "☆".repeat(3 - stars)
	_label(card, stars_text, Vector2(16, 142), Vector2(190, 28), 19, GOLD)
	_label(card, "12–20 ONDAS" if local_index < 4 else "15 ONDAS · CHEFE", Vector2(16, 180), Vector2(190, 24), 10, MUTED)
	var button_text := "ABRIR ROTA" if unlocked else "BLOQUEADA"
	var button := _button(card, button_text, Vector2(16, 226), Vector2(194, 48), _on_stage_pressed.bind(stage_id), color)
	button.disabled = not unlocked
	if not unlocked:
		var requirement := "10 ESTRELAS NO SETOR ANTERIOR" if local_index == 0 else "CONCLUA A FASE %02d" % (stage_id - 1)
		_label(card, requirement, Vector2(16, 205), Vector2(194, 22), 8, RED)

func _build_library() -> void:
	_title(library_screen, "ARSENAL VIVO", "Heróis e torres não são números: cada escolha muda o modo de ler a rota.")
	var scroll := _scroll(library_screen, Vector2(28, 112), Vector2(1224, 548))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	column.custom_minimum_size = Vector2(1180, 900)
	scroll.add_child(column)
	_label(column, "HERÓIS // COMANDO DE CAMPO", Vector2.ZERO, Vector2(600, 30), 13, CYAN)
	var hero_row := HBoxContainer.new()
	hero_row.add_theme_constant_override("separation", 12)
	hero_row.custom_minimum_size = Vector2(1180, 188)
	column.add_child(hero_row)
	for hero_id in GameData.hero_defs().keys():
		_add_hero_card(hero_row, str(hero_id))
	_label(column, "TORRES // PLATAFORMA DE DEFESA", Vector2.ZERO, Vector2(600, 30), 13, GOLD)
	var tower_row := HBoxContainer.new()
	tower_row.add_theme_constant_override("separation", 12)
	tower_row.custom_minimum_size = Vector2(1180, 190)
	column.add_child(tower_row)
	for tower_id in GameData.tower_defs().keys():
		_add_tower_card(tower_row, str(tower_id))

func _add_hero_card(parent: Node, hero_id: String) -> void :
	var definition: Dictionary = GameData.hero_defs()[hero_id]
	var color: = Color("#" + str(definition["color"]))
	var owned: = SaveManager.has_hero(hero_id)
	var card: = _panel(parent, Vector2.ZERO, Vector2(218, 166), Color("#091624e8"), Color(color, 0.5))
	card.custom_minimum_size = Vector2(218, 166)
	_label(card, str(definition["rarity"]), Vector2(14, 10), Vector2(180, 20), 9, color)
	_art_image(card, "heroes/" + hero_id, Vector2(10, 30), Vector2(50, 58))
	_label(card, str(definition["name"]), Vector2(62, 38), Vector2(140, 26), 18, TEXT)
	_label(card, str(definition["role"]), Vector2(62, 65), Vector2(140, 24), 10, MUTED)
	_label(card, str(definition["ultimate"]), Vector2(14, 93), Vector2(190, 22), 10, TEXT)
	_label(card, "DESBLOQUEADO" if owned else "NA LOJA", Vector2(14, 127), Vector2(190, 20), 10, GREEN if owned else RED)

func _add_tower_card(parent: Node, tower_id: String) -> void:
	var definition: Dictionary = GameData.tower_defs()[tower_id]
	var color := Color("#" + str(definition["color"]))
	var card := _panel(parent, Vector2.ZERO, Vector2(184, 168), Color("#091624e8"), Color(color, 0.46))
	card.custom_minimum_size = Vector2(184, 168)
	_label(card, str(definition["name"]).to_upper(), Vector2(12, 14), Vector2(160, 24), 14, color)
	_label(card, str(definition["role"]), Vector2(12, 42), Vector2(160, 24), 10, MUTED)
	_label(card, "◆ %d  ·  %s" % [int(definition["cost"]), str(definition["type"]).to_upper()], Vector2(12, 78), Vector2(160, 22), 11, TEXT)
	_label(card, "2 especializações no nível 3", Vector2(12, 110), Vector2(160, 28), 10, color)

func _build_shop() -> void:
	_title(shop_screen, "MERCADO DE AETHER", "Compre identidade, não apenas atributos. Toda aquisição deixa uma marca no campo.")
	var categories := [["heroes", "HERÓIS", PURPLE], ["skins", "SKINS", PURPLE], ["effects", "EFEITOS", CYAN], ["upgrades", "UPGRADES", GOLD], ["cosmetics", "COSMÉTICOS", GREEN]]
	for index in range(categories.size()):
		var category: Array = categories[index]
		var button := _button(shop_screen, str(category[1]), Vector2(28 + index * 152, 105), Vector2(138, 44), _on_shop_category.bind(str(category[0])), category[2])
		if current_shop_category == str(category[0]):
			button.add_theme_stylebox_override("normal", _style(Color(category[2], 0.24), 10, category[2], 1))
	var scroll := _scroll(shop_screen, Vector2(28, 166), Vector2(1224, 494))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.custom_minimum_size = Vector2(1180, 560)
	scroll.add_child(grid)
	for item in GameData.shop_items():
		if str(item["category"]) == current_shop_category:
			_add_shop_card(grid, item)

func _add_shop_card(parent: Node, item: Dictionary) -> void :
	var color: = Color("#" + str(item["color"]))
	var card: = _panel(parent, Vector2.ZERO, Vector2(382, 222), Color("#091624ee"), Color(color, 0.46))
	card.custom_minimum_size = Vector2(382, 222)
	_label(card, str(item["rarity"]), Vector2(18, 14), Vector2(180, 22), 10, color)
	var art_key: String = "heroes/" + str(item["target"]) if item["kind"] == "hero" else "towers/mage_default"
	if item["kind"] == "skin": art_key = "towers/mage_" + str(item["target"])
	if item["kind"] == "research": art_key = "towers/archer_default"
	_art_image(card, art_key, Vector2(14, 34), Vector2(64, 74))
	_label(card, str(item["title"]), Vector2(84, 46), Vector2(276, 28), 18, TEXT)
	_label(card, " · ".join(item["meta"]), Vector2(84, 75), Vector2(276, 22), 10, MUTED)
	_label(card, str(item["desc"]), Vector2(18, 108), Vector2(344, 42), 11, TEXT)
	var owned: = _shop_owned(item)
	var button_text: = "COMPRAR"
	if owned and (str(item["kind"]) == "skin" or str(item["kind"]) == "effect"):
		button_text = "EQUIPAR"
	elif owned:
		button_text = "ADQUIRIDO"
	elif str(item["currency"]) == "gold":
		button_text = "COMPRAR  ◆ %d" % int(item["price"])
	else:
		button_text = "COMPRAR  ◇ %d" % int(item["price"])
	var button: = _button(card, button_text, Vector2(18, 166), Vector2(344, 42), _on_shop_action.bind(str(item["id"])), color)
	button.disabled = owned and str(item["kind"]) != "skin" and str(item["kind"]) != "effect"

func _shop_owned(item: Dictionary) -> bool:
	var kind := str(item["kind"])
	var target := str(item["target"])
	if kind == "hero": return SaveManager.has_hero(target)
	if kind == "skin": return SaveManager.data["owned_skins"].has(target)
	if kind == "effect": return SaveManager.data["owned_effects"].has(target)
	if kind == "research": return int(SaveManager.data["research"].get(target, 0)) >= 1
	if kind == "core": return int(SaveManager.data.get("base_bonus", 0)) >= 2
	return false

func _build_missions() -> void:
	_title(missions_screen, "MISSÕES DE FRONTEIRA", "Objetivos curtos que recompensam domínio, curiosidade e repetição inteligente.")
	var scroll := _scroll(missions_screen, Vector2(28, 112), Vector2(1224, 548))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	column.custom_minimum_size = Vector2(1180, 720)
	scroll.add_child(column)
	for mission in GameData.missions():
		_add_mission_row(column, mission)

func _add_mission_row(parent: Node, mission: Dictionary) -> void:
	var stat: int = int(SaveManager.data["stats"].get(str(mission["stat"]), 0))
	var target := int(mission["target"])
	var progress := mini(stat, target)
	var claimed := SaveManager.mission_claimed(str(mission["id"]))
	var row := _panel(parent, Vector2.ZERO, Vector2(1180, 96), Color("#091624e8"), Color("#72e4b344"))
	row.custom_minimum_size = Vector2(1180, 96)
	_label(row, str(mission["title"]), Vector2(20, 12), Vector2(310, 24), 15, TEXT)
	_label(row, str(mission["desc"]), Vector2(20, 42), Vector2(430, 22), 11, MUTED)
	var progress_bar := ProgressBar.new()
	progress_bar.position = Vector2(500, 28)
	progress_bar.size = Vector2(300, 10)
	progress_bar.max_value = target
	progress_bar.value = progress
	progress_bar.show_percentage = false
	progress_bar.add_theme_stylebox_override("background", _style(Color("#142437"), 4))
	progress_bar.add_theme_stylebox_override("fill", _style(Color("#72e4b3"), 4))
	row.add_child(progress_bar)
	_label(row, "%d / %d" % [progress, target], Vector2(500, 45), Vector2(300, 20), 10, GREEN)
	_label(row, "+%d ◆  +%d ◇" % [int(mission["gold"]), int(mission["crystals"])], Vector2(830, 21), Vector2(140, 38), 11, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	var button := _button(row, "RESGATAR" if progress >= target and not claimed else ("RESGATADA" if claimed else "EM ANDAMENTO"), Vector2(1000, 24), Vector2(156, 46), _on_claim_mission.bind(str(mission["id"])), GREEN)
	button.disabled = claimed or progress < target

func _build_achievements() -> void:
	_title(achievements_screen, "ARQUIVO DE CONQUISTAS", "Marcos permanentes registrados pelo núcleo. Alguns abrem cristais e novos protocolos.")
	var scroll := _scroll(achievements_screen, Vector2(28, 112), Vector2(1224, 548))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.custom_minimum_size = Vector2(1180, 600)
	scroll.add_child(grid)
	for achievement in GameData.achievements():
		_add_achievement_card(grid, achievement)

func _add_achievement_card(parent: Node, achievement: Dictionary) -> void:
	var done: bool = SaveManager.data["achievements"].has(str(achievement["id"]))
	var value := int(SaveManager.data["stats"].get(str(achievement["stat"]), 0))
	var target := int(achievement["target"])
	var card := _panel(parent, Vector2.ZERO, Vector2(576, 132), Color("#091624e8"), GOLD if done else Color("#27415b"))
	card.custom_minimum_size = Vector2(576, 132)
	_label(card, "◆" if done else "◇", Vector2(20, 24), Vector2(44, 46), 28, GOLD if done else MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_label(card, str(achievement["title"]), Vector2(78, 18), Vector2(360, 28), 16, TEXT)
	_label(card, str(achievement["desc"]), Vector2(78, 48), Vector2(390, 24), 11, MUTED)
	_label(card, "%d / %d" % [mini(value, target), target], Vector2(78, 85), Vector2(170, 22), 11, GREEN if done else CYAN)
	_label(card, "CONCLUÍDA" if done else "EM PROGRESSO", Vector2(390, 85), Vector2(156, 22), 10, GOLD if done else MUTED, HORIZONTAL_ALIGNMENT_RIGHT)

func _build_settings() -> void:
	_title(settings_screen, "CONFIGURAÇÕES", "Ajuste o ritmo e a leitura sem perder a intenção do campo.")
	var panel := _panel(settings_screen, Vector2(36, 126), Vector2(720, 472), Color("#091624ee"), Color("#75e5ef44"))
	_label(panel, "MIXAGEM", Vector2(24, 20), Vector2(300, 26), 12, CYAN)
	_add_slider(panel, "MÚSICA", "music", 64)
	_add_slider(panel, "EFEITOS", "sfx", 132)
	_add_slider(panel, "AMBIENTE", "ambient", 200)
	_label(panel, "LEITURA", Vector2(24, 286), Vector2(300, 26), 12, GOLD)
	var motion := CheckButton.new()
	motion.text = "REDUZIR MOVIMENTO E PARTÍCULAS"
	motion.position = Vector2(22, 322)
	motion.size = Vector2(420, 48)
	motion.button_pressed = bool(SaveManager.setting("reduced_motion", false))
	motion.add_theme_font_size_override("font_size", 13)
	motion.toggled.connect(_on_toggle_setting.bind("reduced_motion"))
	panel.add_child(motion)
	var contrast := CheckButton.new()
	contrast.text = "CONTRASTE ALTO"
	contrast.position = Vector2(22, 374)
	contrast.size = Vector2(300, 48)
	contrast.button_pressed = bool(SaveManager.setting("high_contrast", false))
	contrast.add_theme_font_size_override("font_size", 13)
	contrast.toggled.connect(_on_toggle_setting.bind("high_contrast"))
	panel.add_child(contrast)
	_button(panel, "APAGAR PROGRESSO LOCAL", Vector2(22, 424), Vector2(270, 42), _open_reset_confirm, RED)
	var about := _panel(settings_screen, Vector2(788, 126), Vector2(454, 472), Color("#091624ee"), Color("#b196ff44"))
	_label(about, "SOBRE O PROTOCOLO", Vector2(24, 20), Vector2(300, 26), 12, PURPLE)
	_label(about, "Aetherfall Defense", Vector2(24, 66), Vector2(390, 30), 22, TEXT)
	_label(about, "Godot 4.5.1 · Android landscape\nCompatibility renderer · touch-first\n\nOs sinais são desenhados em tempo real para manter\nlegibilidade durante ondas grandes.", Vector2(24, 108), Vector2(390, 138), 13, MUTED)
	_label(about, "BUILD DE DESENVOLVIMENTO", Vector2(24, 288), Vector2(300, 22), 10, RED)
	if OS.is_debug_build() and "--dev-tools" in OS.get_cmdline_user_args():
		_label(about, "Ferramentas DEV disponíveis durante o combate.", Vector2(24, 316), Vector2(390, 26), 11, TEXT)
		_button(about, "DESBLOQUEAR CAMPANHA", Vector2(24, 370), Vector2(252, 46), _debug_unlock, RED)
	else:
		_label(about, "Ferramentas internas ocultas na versão final.", Vector2(24, 316), Vector2(390, 26), 11, MUTED)

func _add_slider(parent: Node, title: String, key: String, y: float) -> void:
	_label(parent, title, Vector2(24, y), Vector2(140, 32), 12, TEXT)
	var slider := HSlider.new()
	slider.position = Vector2(180, y + 7)
	slider.size = Vector2(360, 28)
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.value = float(SaveManager.setting(key, 0.5)) * 100.0
	slider.step = 1.0
	slider.value_changed.connect(_on_slider_changed.bind(key))
	parent.add_child(slider)
	var percentage := _label(parent, "%d%%" % int(slider.value), Vector2(560, y), Vector2(90, 32), 12, CYAN, HORIZONTAL_ALIGNMENT_RIGHT)
	slider.value_changed.connect(func(value: float): percentage.text = "%d%%" % int(value))

func _scroll(parent: Node, position: Vector2, size: Vector2) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.position = position
	scroll.size = size
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(scroll)
	return scroll

func _build_battle() -> void:
	battle_refs.clear()
	tower_buttons.clear()
	hero_skill_buttons.clear()
	global_skill_buttons.clear()
	var top := _panel(battle_screen, Vector2(18, 14), Vector2(1244, 90), Color("#050914e8"), Color("#75e5ef55"))
	battle_refs["base"] = _label(top, "NÚCLEO 20 / 20", Vector2(18, 12), Vector2(148, 25), 13, RED)
	battle_refs["gold"] = _label(top, "◆ 330", Vector2(18, 40), Vector2(148, 24), 13, GOLD)
	battle_refs["stage"] = _label(top, "FASE", Vector2(165, 8), Vector2(310, 36), 13, TEXT)
	battle_refs["weather"] = _label(top, "", Vector2(165, 48), Vector2(310, 24), 11, MUTED)
	battle_refs["wave"] = _label(top, "ONDA 0 / 15", Vector2(478, 10), Vector2(155, 26), 16, CYAN)
	battle_refs["remaining"] = _label(top, "0 INIMIGOS", Vector2(478, 45), Vector2(160, 24), 12, MUTED)
	battle_refs["next"] = _label(top, "", Vector2(645, 60), Vector2(235, 24), 11, MUTED)
	battle_refs["start_wave"] = _button(top, "INICIAR ONDA", Vector2(645, 8), Vector2(190, 48), _on_start_wave, GREEN)
	battle_refs["pause"] = _button(top, "PAUSA", Vector2(852, 8), Vector2(92, 48), toggle_pause_overlay, CYAN)
	battle_refs["leave"] = _button(top, "SAIR", Vector2(952, 8), Vector2(82, 48), _on_leave_battle, RED)
	battle_refs["speed_1"] = _button(top, "1X", Vector2(1042, 8), Vector2(56, 48), _on_speed_1, GOLD)
	battle_refs["speed_2"] = _button(top, "2X", Vector2(1106, 8), Vector2(56, 48), _on_speed_2, GOLD)
	battle_refs["speed_3"] = _button(top, "3X", Vector2(1170, 8), Vector2(56, 48), _on_speed_3, GOLD)

	battle_refs["tutorial"] = _panel(battle_screen, Vector2(28, 552), Vector2(620, 46), Color("#07121fe8"), Color("#72e4b366"))
	battle_refs["tutorial_label"] = _label(battle_refs["tutorial"], "", Vector2(14, 2), Vector2(590, 42), 11, TEXT)

	var right := _panel(battle_screen, Vector2(1016, 104), Vector2(248, 490), Color("#050914ec"), Color("#75e5ef55"))
	battle_refs["hero_panel"] = right
	battle_refs["hero_name"] = _label(right, "KAEL", Vector2(18, 14), Vector2(210, 28), 18, TEXT)
	battle_refs["hero_role"] = _label(right, "", Vector2(18, 42), Vector2(210, 22), 10, MUTED)
	battle_refs["hero_level"] = _label(right, "NÍVEL 1", Vector2(18, 70), Vector2(104, 20), 10, CYAN)
	battle_refs["hero_hp"] = _label(right, "HP 145 / 145", Vector2(122, 70), Vector2(104, 20), 10, RED, HORIZONTAL_ALIGNMENT_RIGHT)
	battle_refs["hero_xp"] = _label(right, "XP", Vector2(18, 94), Vector2(210, 18), 9, MUTED)
	battle_refs["hero_xp_bar"] = _progress(right, Vector2(18, 114), Vector2(210, 7), CYAN)
	battle_refs["hero_ultimate"] = _button(right, "ULTIMATE 0%", Vector2(18, 138), Vector2(210, 44), _on_ultimate, PURPLE)
	_label(right, "HABILIDADES", Vector2(18, 190), Vector2(210, 18), 9, MUTED)
	for index in range(3):
		var skill := _button(right, "HABILIDADE", Vector2(18, 200 + index * 56), Vector2(210, 48), _on_hero_skill.bind(index), CYAN)
		hero_skill_buttons.append(skill)
	_label(right, "PROTOCOLOS GLOBAIS", Vector2(18, 366), Vector2(210, 18), 9, MUTED)
	var global_ids := ["meteor", "freeze", "barrage", "reinforce"]
	var global_labels := ["METEORO", "CONGELAR", "BOMBARDEIO", "REFORÇO"]
	for index in range(global_ids.size()):
		var skill_button := _button(right, global_labels[index], Vector2(12 + (index % 2) * 116, 390 + int(index / 2) * 56), Vector2(108, 48), _on_global_skill.bind(global_ids[index]), GOLD)
		skill_button.add_theme_font_size_override("font_size", 11)
		global_skill_buttons[global_ids[index]] = skill_button

	var tray := _panel(battle_screen, Vector2(18, 604), Vector2(978, 98), Color("#050914f2"), Color("#f2bd6b55"))
	_label(tray, "DEFESAS", Vector2(18, 8), Vector2(100, 18), 9, MUTED)
	var tower_ids := ["archer", "mage", "cannon", "frost", "volt", "sentinel"]
	for index in range(tower_ids.size()):
		var tower_id: String = tower_ids[index]
		var definition: Dictionary = GameData.tower_defs()[tower_id]
		var tower_button := _button(tray, "%s\n◆ %d" % [str(definition["name"]).to_upper(), int(definition["cost"])], Vector2(16 + index * 158, 30), Vector2(146, 58), _on_tower_build.bind(tower_id), Color("#" + str(definition["color"])))
		tower_button.add_theme_font_size_override("font_size", 11)
		tower_buttons[tower_id] = tower_button

	battle_refs["selected_panel"] = _panel(battle_screen, Vector2(1016, 104), Vector2(248, 490), Color("#07121f"), Color("#75e5ef66"))
	battle_refs["selected_panel"].visible = false
	battle_refs["selected_name"] = _label(battle_refs["selected_panel"], "", Vector2(14, 8), Vector2(170, 22), 13, TEXT)
	battle_refs["selected_stats"] = _label(battle_refs["selected_panel"], "", Vector2(14, 44), Vector2(220, 58), 13, MUTED)
	battle_refs["selected_upgrade"] = _button(battle_refs["selected_panel"], "MELHORAR", Vector2(14, 118), Vector2(220, 52), _on_upgrade, GREEN)
	battle_refs["selected_sell"] = _button(battle_refs["selected_panel"], "VENDER", Vector2(14, 178), Vector2(220, 52), _on_sell, RED)
	battle_refs["selected_spec_a"] = _button(battle_refs["selected_panel"], "CAMINHO A", Vector2(14, 254), Vector2(220, 60), _on_specialize_slot.bind(0), PURPLE)
	battle_refs["selected_spec_b"] = _button(battle_refs["selected_panel"], "CAMINHO B", Vector2(14, 322), Vector2(220, 60), _on_specialize_slot.bind(1), PURPLE)
	_button(battle_refs["selected_panel"], "VOLTAR AO HERÓI", Vector2(14, 420), Vector2(220, 52), battle.cancel_command, CYAN)
	_button(battle_screen, "CANCELAR SELEÇÃO", Vector2(1016, 622), Vector2(248, 60), battle.cancel_command, CYAN)
	battle_refs["boss_panel"] = _panel(battle_screen, Vector2(344, 108), Vector2(350, 48), Color("#050914e8"), RED)
	battle_refs["boss_panel"].visible = false
	battle_refs["boss_name"] = _label(battle_refs["boss_panel"], "", Vector2(12, 0), Vector2(326, 18), 9, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	battle_refs["boss_bar"] = _progress(battle_refs["boss_panel"], Vector2(12, 24), Vector2(326, 9), RED)

	if OS.is_debug_build() and "--dev-tools" in OS.get_cmdline_user_args():
		var dev := _button(battle_screen, "DEV", Vector2(950, 100), Vector2(58, 32), _toggle_dev_panel, RED)
		battle_refs["dev_button"] = dev

func _progress(parent: Node, position: Vector2, size: Vector2, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = position
	bar.size = size
	bar.max_value = 100.0
	bar.value = 0.0
	bar.show_percentage = false
	bar.add_theme_font_size_override("font_size", 1)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", _style(Color("#142437"), 5))
	bar.add_theme_stylebox_override("fill", _style(color, 5))
	for style_name in ["background", "fill"]:
		var bar_style: StyleBoxFlat = bar.get_theme_stylebox(style_name)
		bar_style.content_margin_left = 0
		bar_style.content_margin_right = 0
		bar_style.content_margin_top = 0
		bar_style.content_margin_bottom = 0
	bar.size = size
	parent.add_child(bar)
	bar.set_deferred("size", size)
	return bar

func update_battle_hud(payload: Dictionary) -> void:
	if battle_refs.is_empty():
		return
	_set_text("base", "NÚCLEO %d / %d" % [int(ceil(float(payload.get("base_hp", 0)))), int(payload.get("base_max", 0))])
	_set_text("gold", "◆ %d" % int(payload.get("gold", 0)))
	_set_text("stage", "%s  ·  %s" % [str(payload.get("stage_name", "")), str(payload.get("world_name", "")).to_upper()])
	_set_text("weather", "CONDIÇÃO // %s" % str(payload.get("weather", "")))
	_set_text("wave", "ONDA %d / %d" % [int(payload.get("wave", 0)), int(payload.get("max_waves", 0))])
	_set_text("remaining", "%d HOSTIS EM ROTA" % int(payload.get("remaining", 0)))
	var preview_names: Array = []
	for enemy_id in payload.get("preview", []):
		var definition: Dictionary = GameData.enemy_defs().get(str(enemy_id), {})
		if not definition.is_empty(): preview_names.append(str(definition["name"]).to_upper())
	_set_text("next", "PRÓXIMA // " + ", ".join(preview_names))
	var wave_active := bool(payload.get("wave_active", false))
	var wave := int(payload.get("wave", 0))
	var max_waves := int(payload.get("max_waves", 0))
	var next_button: Button = battle_refs["start_wave"]
	next_button.disabled = wave_active or wave >= max_waves or bool(payload.get("ended", false))
	next_button.text = "ADIANTAR  +10" if wave > 0 and not wave_active and float(payload.get("intermission", 0.0)) > 0.2 else "INICIAR ONDA"
	var hero_data: Dictionary = payload.get("hero", {})
	_set_text("hero_name", "%s  ·  %s" % [str(hero_data.get("name", "")), str(hero_data.get("rarity", ""))])
	_set_text("hero_role", str(hero_data.get("role", "")).to_upper())
	_set_text("hero_level", "NÍVEL %d" % int(hero_data.get("level", 1)))
	_set_text("hero_hp", "HP %d / %d" % [int(hero_data.get("hp", 0)), int(hero_data.get("max_hp", 0))])
	_set_text("hero_xp", "XP %d / %d" % [int(hero_data.get("xp", 0)), int(hero_data.get("next_xp", 100))])
	var xp_bar: ProgressBar = battle_refs["hero_xp_bar"]
	xp_bar.value = 100.0 * float(hero_data.get("xp", 0)) / maxf(float(hero_data.get("next_xp", 100)), 1.0)
	var ultimate_value := float(hero_data.get("ultimate", 0.0))
	var ultimate_button: Button = battle_refs["hero_ultimate"]
	ultimate_button.text = "ULTIMATE %d%%" % int(ultimate_value)
	ultimate_button.disabled = ultimate_value < 100.0 or float(hero_data.get("respawn", 0.0)) > 0.0
	var skills: Array = hero_data.get("skills", [])
	var cooldowns: Array = hero_data.get("cooldowns", [])
	for index in range(hero_skill_buttons.size()):
		var skill_button: Button = hero_skill_buttons[index]
		if index < skills.size():
			var remaining := float(cooldowns[index]) if index < cooldowns.size() else 0.0
			skill_button.text = str(skills[index]["short"]) + ("  %ds" % int(ceil(remaining)) if remaining > 0.0 else "")
			skill_button.disabled = remaining > 0.0 or float(hero_data.get("respawn", 0.0)) > 0.0
	for skill_id in global_skill_buttons.keys():
		var cooldown := float(payload.get("globals", {}).get(skill_id, 0.0))
		var global_button: Button = global_skill_buttons[skill_id]
		global_button.disabled = cooldown > 0.0
		var names := {"meteor": "METEORO", "freeze": "GELO", "barrage": "BOMBAS", "reinforce": "REFORÇO"}
		global_button.text = "ESCOLHER ALVO" if battle.pending_skill == skill_id else names[skill_id] + (" %ds" % int(ceil(cooldown)) if cooldown > 0.0 else "")
	for tower_id in tower_buttons.keys():
		var definition: Dictionary = GameData.tower_defs()[tower_id]
		var tower_button: Button = tower_buttons[tower_id]
		tower_button.disabled = int(payload.get("gold", 0)) < int(definition["cost"])
	var selected: Dictionary = payload.get("selected_tower", {})
	var selected_panel: Panel = battle_refs["selected_panel"]
	selected_panel.visible = not selected.is_empty()
	battle_refs["hero_panel"].visible = selected.is_empty()
	if not selected.is_empty():
		_set_text("selected_name", "%s  ·  NV %d" % [str(selected["name"]).to_upper(), int(selected["level"])])
		_set_text("selected_stats", "DANO %.0f  ·  ALC %.0f\n%s" % [float(selected["damage"]), float(selected["range"]), str(selected["role"])])
		var upgrade_button: Button = battle_refs["selected_upgrade"]
		upgrade_button.text = "MELHORAR · %d" % int(selected["upgrade_cost"]) if int(selected["level"]) < 3 else "NÍVEL MÁXIMO"
		upgrade_button.disabled = not bool(selected.get("can_upgrade", false))
		var sell_button: Button = battle_refs["selected_sell"]
		sell_button.text = "VENDER  %d" % int(selected["sell"])
		var branches: Array = selected.get("branches", [])
		battle_refs["selected_branches"] = branches
		var spec_buttons: Array = [battle_refs["selected_spec_a"], battle_refs["selected_spec_b"]]
		for index in range(spec_buttons.size()):
			var spec_button: Button = spec_buttons[index]
			if index < branches.size():
				spec_button.text = str(branches[index]["short"]).to_upper()
				spec_button.tooltip_text = str(branches[index]["effect"])
				spec_button.disabled = int(selected["level"]) < 3
			else:
				spec_button.text = "CAMINHO %s" % ("A" if index == 0 else "B")
				spec_button.disabled = true
	var boss_panel: Panel = battle_refs["boss_panel"]
	var boss_hp := float(payload.get("boss_hp", 0.0))
	var boss_max := float(payload.get("boss_max_hp", 0.0))
	boss_panel.visible = boss_max > 0.0 and boss_hp > 0.0
	if boss_panel.visible:
		_set_text("boss_name", "%s  ·  FASE %d" % [str(payload.get("boss_name", "")).to_upper(), int(payload.get("boss_phase", 1))])
		var boss_bar: ProgressBar = battle_refs["boss_bar"]
		boss_bar.value = 100.0 * boss_hp / maxf(boss_max, 1.0)
	var tutorial_panel: Panel = battle_refs["tutorial"]
	tutorial_panel.visible = bool(payload.get("tutorial", false))
	if tutorial_panel.visible:
		var step := int(payload.get("tutorial_step", 1))
		var instruction := "1  ·  Escolha uma torre na barra e toque em um círculo de defesa." if step == 1 else ("2  ·  A rota está pronta. Inicie a primeira onda." if step == 2 else ("3  ·  Use ouro para elevar uma torre ao próximo nível." if step == 3 else "4  ·  Agora você comanda o campo. Boa leitura."))
		_set_text("tutorial_label", instruction)

func _set_text(key: String, value: String) -> void:
	if battle_refs.has(key) and is_instance_valid(battle_refs[key]):
		battle_refs[key].text = value

func show_battle_result(result: String, payload: Dictionary) -> void:
	overlay_kind = "result"
	battle.set_paused(true)
	overlay.visible = true
	_clear(overlay)
	var dim := ColorRect.new()
	dim.color = Color("#02050bd4")
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var color := GREEN if result == "victory" else RED
	var modal := _panel(overlay, Vector2(292, 72), Vector2(696, 576), Color("#07121ff7"), Color(color, 0.8))
	_label(modal, "VITÓRIA" if result == "victory" else "DERROTA", Vector2(30, 28), Vector2(636, 54), 32, color, HORIZONTAL_ALIGNMENT_CENTER)
	_label(modal, str(payload.get("stage_name", "")), Vector2(30, 82), Vector2(636, 28), 14, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	var stars := int(payload.get("stars", 0))
	_label(modal, "★".repeat(stars) + "☆".repeat(3 - stars) if result == "victory" else "ROTA INTERROMPIDA", Vector2(30, 122), Vector2(636, 48), 28, GOLD if result == "victory" else RED, HORIZONTAL_ALIGNMENT_CENTER)
	var stats := _panel(modal, Vector2(64, 194), Vector2(568, 150), Color("#0c1b2ce8"), Color("#27415b"))
	_label(stats, "TEMPO", Vector2(22, 22), Vector2(122, 22), 10, MUTED)
	_label(stats, _format_time(float(payload.get("time", 0.0))), Vector2(22, 48), Vector2(122, 28), 18, TEXT)
	_label(stats, "INIMIGOS", Vector2(166, 22), Vector2(122, 22), 10, MUTED)
	_label(stats, "%d" % int(payload.get("kills", 0)), Vector2(166, 48), Vector2(122, 28), 18, TEXT)
	_label(stats, "RECOMPENSA", Vector2(310, 22), Vector2(122, 22), 10, MUTED)
	_label(stats, "+%d ◆  +%d ◇" % [int(payload.get("gold", 0)), int(payload.get("crystals", 0))], Vector2(310, 48), Vector2(230, 28), 16, GOLD)
	_label(stats, "ONDA ALCANÇADA  %d", Vector2(22, 102), Vector2(250, 22), 10, MUTED)
	_label(stats, "%d" % int(payload.get("wave", 0)), Vector2(230, 96), Vector2(80, 28), 16, CYAN, HORIZONTAL_ALIGNMENT_RIGHT)
	_label(stats, "NÚCLEO  %d / %d" % [int(payload.get("base_hp", 0)), int(payload.get("base_max", 0))], Vector2(338, 102), Vector2(210, 22), 10, RED, HORIZONTAL_ALIGNMENT_RIGHT)
	var stage_id := int(payload.get("stage_id", 1))
	if result == "victory":
		var next_button := _button(modal, "PRÓXIMA FASE", Vector2(64, 376), Vector2(270, 52), _on_next_stage, GREEN)
		next_button.disabled = stage_id >= 25 or not SaveManager.is_stage_unlocked(stage_id + 1)
		_button(modal, "REPETIR", Vector2(356, 376), Vector2(240, 52), _on_repeat_stage, CYAN)
	else:
		_button(modal, "TENTAR NOVAMENTE", Vector2(64, 376), Vector2(270, 52), _on_repeat_stage, RED)
		_button(modal, "MUDAR HERÓI", Vector2(356, 376), Vector2(240, 52), _on_change_hero_after_fail, PURPLE)
	_button(modal, "VOLTAR AO MAPA", Vector2(64, 446), Vector2(532, 50), _on_leave_battle, MUTED)

func _format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d" % [int(total / 60), total % 60]

func toggle_pause_overlay() -> void:
	if current_screen != "battle" or battle.ended:
		return
	if overlay.visible and overlay_kind == "pause":
		overlay.visible = false
		battle.set_paused(false)
		return
	overlay_kind = "pause"
	battle.set_paused(true)
	overlay.visible = true
	_clear(overlay)
	var dim := ColorRect.new()
	dim.color = Color("#02050b99")
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var modal := _panel(overlay, Vector2(420, 172), Vector2(440, 338), Color("#07121ff7"), Color("#75e5ef88"))
	_label(modal, "CAMPO PAUSADO", Vector2(24, 26), Vector2(392, 38), 24, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_label(modal, "A rota espera o próximo comando.", Vector2(24, 68), Vector2(392, 24), 12, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_button(modal, "CONTINUAR", Vector2(48, 120), Vector2(344, 48), toggle_pause_overlay, GREEN)
	_button(modal, "VOLTAR AO MAPA", Vector2(48, 180), Vector2(344, 48), _on_leave_battle, RED)
	_label(modal, "Velocidade: 1X / 2X / 3X na barra superior", Vector2(24, 260), Vector2(392, 24), 10, MUTED, HORIZONTAL_ALIGNMENT_CENTER)

func _on_play() -> void:
	app.show_map()

func _on_back() -> void:
	if current_screen == "battle":
		_on_leave_battle()
	else:
		app.show_home()

func _on_library() -> void:
	show_library()

func _on_shop() -> void:
	show_shop()

func _on_missions() -> void:
	show_missions()

func _on_achievements() -> void:
	show_achievements()

func _on_settings() -> void:
	show_settings()

func _on_world_tab(world_index: int) -> void:
	selected_world = world_index
	app.set_map_world(world_index)
	show_map()

func _on_difficulty(key: String) -> void:
	selected_difficulty = key
	show_map()

func _on_stage_pressed(stage_id: int) -> void:
	if not SaveManager.is_stage_unlocked(stage_id):
		return
	selected_stage = stage_id
	_open_hero_select()

func _open_hero_select() -> void:
	overlay_kind = "hero_select"
	overlay.visible = true
	_clear(overlay)
	var dim := ColorRect.new()
	dim.color = Color("#02050bd4")
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var modal := _panel(overlay, Vector2(176, 54), Vector2(928, 612), Color("#07121ff8"), CYAN)
	_label(modal, "ESCOLHA O COMANDANTE", Vector2(28, 22), Vector2(872, 34), 24, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_label(modal, "Fase %02d · Cada herói abre um ritmo diferente para a mesma rota." % selected_stage, Vector2(28, 58), Vector2(872, 24), 12, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	var hero_row := HBoxContainer.new()
	hero_row.position = Vector2(28, 104)
	hero_row.add_theme_constant_override("separation", 12)
	hero_row.custom_minimum_size = Vector2(870, 196)
	modal.add_child(hero_row)
	for hero_id in GameData.hero_defs().keys():
		_add_selectable_hero(hero_row, str(hero_id))
	_label(modal, "DIFICULDADE", Vector2(28, 320), Vector2(240, 24), 11, PURPLE)
	var keys := ["normal", "hard", "nightmare"]
	for index in range(keys.size()):
		var key: String = keys[index]
		var difficulty_button := _button(modal, str(GameData.difficulties()[key]["label"]), Vector2(28 + index * 168, 350), Vector2(154, 46), _on_select_difficulty.bind(key), PURPLE)
		if key == selected_difficulty:
			difficulty_button.add_theme_stylebox_override("normal", _style(Color(PURPLE, 0.25), 10, PURPLE, 1))
	_label(modal, "Normal: leitura base · Difícil: rotas mais densas · Pesadelo: composição extrema", Vector2(28, 410), Vector2(870, 24), 10, MUTED)
	_button(modal, "ENTRAR NO CAMPO", Vector2(28, 488), Vector2(430, 54), _on_confirm_start, GREEN)
	_button(modal, "CANCELAR", Vector2(474, 488), Vector2(430, 54), _close_overlay, MUTED)

func _add_selectable_hero(parent: Node, hero_id: String) -> void:
	var definition: Dictionary = GameData.hero_defs()[hero_id]
	var color := Color("#" + str(definition["color"]))
	var owned := SaveManager.has_hero(hero_id)
	var card := _panel(parent, Vector2.ZERO, Vector2(164, 184), Color("#091624e8"), color if hero_id == selected_hero else Color("#27415b"))
	card.custom_minimum_size = Vector2(164, 184)
	var button := _button(card, str(definition["sigil"]), Vector2(46, 18), Vector2(72, 58), _on_select_hero.bind(hero_id), color)
	button.add_theme_font_size_override("font_size", 28)
	button.disabled = not owned
	_label(card, str(definition["name"]), Vector2(12, 82), Vector2(140, 25), 16, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_label(card, str(definition["rarity"]), Vector2(12, 109), Vector2(140, 18), 9, color, HORIZONTAL_ALIGNMENT_CENTER)
	_label(card, "DISPONÍVEL" if owned else "BLOQUEADO", Vector2(12, 140), Vector2(140, 18), 9, GREEN if owned else RED, HORIZONTAL_ALIGNMENT_CENTER)

func _on_select_hero(hero_id: String) -> void:
	selected_hero = hero_id
	_open_hero_select()

func _on_select_difficulty(key: String) -> void:
	selected_difficulty = key
	_open_hero_select()

func _on_confirm_start() -> void:
	if not SaveManager.has_hero(selected_hero):
		selected_hero = "kael"
	overlay.visible = false
	start_requested.emit(selected_stage, selected_difficulty, selected_hero)
	app.start_battle(selected_stage, selected_difficulty, selected_hero)

func _on_start_wave() -> void:
	battle.start_next_wave()

func _on_speed_1() -> void:
	battle.set_game_speed(1.0)

func _on_speed_2() -> void:
	battle.set_game_speed(2.0)

func _on_speed_3() -> void:
	battle.set_game_speed(3.0)

func _on_leave_battle() -> void:
	overlay.visible = false
	battle.set_paused(false)
	app.leave_battle()

func _on_tower_build(tower_id: String) -> void:
	battle.select_build_type(tower_id)

func _on_hero_skill(index: int) -> void:
	battle.use_hero_skill(index)

func _on_ultimate() -> void:
	battle.use_hero_ultimate()

func _on_global_skill(skill_id: String) -> void:
	battle.use_global_skill(skill_id)

func _on_upgrade() -> void:
	battle.upgrade_selected_tower()

func _on_sell() -> void:
	battle.sell_selected_tower()

func _on_specialize_slot(index: int) -> void:
	var branches: Array = battle_refs.get("selected_branches", [])
	if index >= 0 and index < branches.size():
		battle.specialize_selected_tower(str(branches[index]["id"]))

func _on_next_stage() -> void:
	var next_id: int = int(battle.stage_data().get("id", selected_stage)) + 1
	selected_stage = int(next_id)
	overlay.visible = false
	app.start_battle(selected_stage, selected_difficulty, selected_hero)

func _on_repeat_stage() -> void:
	overlay.visible = false
	app.start_battle(int(battle.stage_data().get("id", selected_stage)), selected_difficulty, selected_hero)

func _on_change_hero_after_fail() -> void:
	selected_stage = int(battle.stage_data().get("id", selected_stage))
	_close_overlay()
	_open_hero_select()

func _close_overlay() -> void:
	overlay.visible = false
	if current_screen == "battle" and not battle.ended:
		battle.set_paused(false)

func _on_shop_category(category: String) -> void:
	current_shop_category = category
	show_shop()

func _on_shop_action(item_id: String) -> void:
	for item in GameData.shop_items():
		if str(item["id"]) != item_id:
			continue
		if _shop_owned(item):
			if str(item["kind"]) == "skin":
				SaveManager.data["equipped_skin"] = str(item["target"])
			elif str(item["kind"]) == "effect":
				SaveManager.data["equipped_effect"] = str(item["target"])
			else:
				return
			SaveManager.commit()
			show_toast("Visual equipado", str(item["title"]), "success")
			return
		var currency := str(item["currency"])
		var price := int(item["price"])
		var balance := int(SaveManager.data.get(currency, 0))
		if balance < price:
			show_toast("Compra bloqueada", "Ainda faltam %d recursos." % (price - balance), "error")
			return
		SaveManager.data[currency] = balance - price
		var kind := str(item["kind"])
		var target := str(item["target"])
		if kind == "hero":
			SaveManager.unlock_hero(target)
		elif kind == "skin":
			SaveManager.data["owned_skins"].append(target)
		elif kind == "effect":
			SaveManager.data["owned_effects"].append(target)
		elif kind == "research":
			SaveManager.data["research"][target] = int(SaveManager.data["research"].get(target, 0)) + 1
		elif kind == "core":
			SaveManager.data["base_bonus"] = int(SaveManager.data.get("base_bonus", 0)) + 2
		SaveManager.commit()
		AudioManager.coin()
		show_toast("Aquisição confirmada", str(item["title"]) + " está pronta para uso.", "reward")
		show_shop()
		return

func _on_claim_mission(mission_id: String) -> void:
	for mission in GameData.missions():
		if str(mission["id"]) != mission_id or SaveManager.mission_claimed(mission_id):
			continue
		var stat := int(SaveManager.data["stats"].get(str(mission["stat"]), 0))
		if stat < int(mission["target"]):
			return
		SaveManager.claim_mission(mission_id)
		SaveManager.data["gold"] = int(SaveManager.data["gold"]) + int(mission["gold"])
		SaveManager.data["crystals"] = int(SaveManager.data["crystals"]) + int(mission["crystals"])
		SaveManager.commit()
		AudioManager.victory()
		show_toast("Recompensa recebida", "+%d ouro · +%d cristais" % [int(mission["gold"]), int(mission["crystals"])], "reward")
		show_missions()
		return

func _on_slider_changed(value: float, key: String) -> void:
	SaveManager.data["settings"][key] = value / 100.0
	AudioManager.set_mix(float(SaveManager.data["settings"]["music"]), float(SaveManager.data["settings"]["sfx"]), float(SaveManager.data["settings"]["ambient"]))
	SaveManager.commit()

func _on_toggle_setting(value: bool, key: String) -> void:
	SaveManager.data["settings"][key] = value
	SaveManager.commit()

func _open_reset_confirm() -> void:
	overlay_kind = "reset"
	overlay.visible = true
	_clear(overlay)
	var dim := ColorRect.new()
	dim.color = Color("#02050bd4")
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var modal := _panel(overlay, Vector2(390, 220), Vector2(500, 250), Color("#07121ff8"), RED)
	_label(modal, "APAGAR PROGRESSO?", Vector2(20, 24), Vector2(460, 32), 22, RED, HORIZONTAL_ALIGNMENT_CENTER)
	_label(modal, "Esta ação remove o save local deste dispositivo.", Vector2(20, 70), Vector2(460, 24), 12, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_button(modal, "APAGAR", Vector2(30, 138), Vector2(210, 48), _confirm_reset, RED)
	_button(modal, "CANCELAR", Vector2(260, 138), Vector2(210, 48), _close_overlay, MUTED)

func _confirm_reset() -> void:
	SaveManager.reset_progress()
	overlay.visible = false
	show_home()
	show_toast("Save reiniciado", "A primeira rota está pronta novamente.", "info")

func _toggle_dev_panel() -> void:
	if not OS.is_debug_build():
		return
	if battle_refs.has("dev_panel") and is_instance_valid(battle_refs["dev_panel"]):
		battle_refs["dev_panel"].queue_free()
		battle_refs.erase("dev_panel")
		return
	var panel := _panel(battle_screen, Vector2(790, 136), Vector2(208, 198), Color("#120a18f5"), RED)
	battle_refs["dev_panel"] = panel
	_label(panel, "DEV TOOLS", Vector2(12, 8), Vector2(184, 20), 10, RED, HORIZONTAL_ALIGNMENT_CENTER)
	_button(panel, "+1000 OURO", Vector2(12, 36), Vector2(184, 34), _debug_gold, GOLD)
	_button(panel, "PULAR ONDA", Vector2(12, 76), Vector2(184, 34), _debug_skip_wave, CYAN)
	_button(panel, "MATAR TODOS", Vector2(12, 116), Vector2(184, 34), _debug_kill, RED)
	_button(panel, "INVOCAR BOSS", Vector2(12, 156), Vector2(184, 34), _debug_boss, PURPLE)

func _debug_gold() -> void:
	battle.debug_add_gold()

func _debug_skip_wave() -> void:
	battle.debug_skip_wave()

func _debug_kill() -> void:
	battle.debug_kill_all()

func _debug_boss() -> void:
	battle.debug_spawn_boss()

func _debug_unlock() -> void:
	battle.debug_unlock_all()
	show_settings()

func refresh_all() -> void:
	_update_resource_labels()
	if current_screen == "home":
		_clear(home_screen)
		_build_home()
	elif current_screen == "map":
		_clear(map_screen)
		_build_map()
	elif current_screen == "shop":
		_clear(shop_screen)
		_build_shop()
	elif current_screen == "missions":
		_clear(missions_screen)
		_build_missions()
	elif current_screen == "achievements":
		_clear(achievements_screen)
		_build_achievements()

func show_toast(title: String, message: String, tone: String = "info") -> void:
	var color := CYAN
	if tone == "success" or tone == "reward": color = GREEN if tone == "success" else GOLD
	if tone == "error": color = RED
	var card := _panel(toast_layer, Vector2(418, 30), Vector2(444, 72), Color("#07121ff5"), color)
	card.pivot_offset = Vector2(222.0, 36.0)
	card.scale = Vector2(0.94, 0.94) if tone == "reward" else Vector2.ONE
	_label(card, title.to_upper(), Vector2(14, 6), Vector2(416, 24), 11, color, HORIZONTAL_ALIGNMENT_CENTER)
	_label(card, message, Vector2(14, 30), Vector2(416, 32), 11, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	var tween := create_tween()
	if tone == "reward":
		tween.tween_property(card, "scale", Vector2.ONE, 0.18)
	tween.tween_interval(2.6)
	tween.tween_property(card, "modulate", Color(1, 1, 1, 0), 0.25)
	tween.tween_callback(card.queue_free)
