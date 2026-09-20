extends Node2D

var elapsed := 0.0
var units: Array = []

func _ready() -> void:
	for key in GameData.enemy_defs():
		var definition: Dictionary = GameData.enemy_defs()[key]
		units.append({"type":key,"radius":definition.radius,"color":Color("#"+definition.color),"hit_flash":0.0,"shield":definition.get("shield",0),"teleport_charge":0.5 if key == "teleporter" else 0.0})
	if "--capture" in OS.get_cmdline_user_args():
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("/tmp/aetherfall-combat-gallery.png")
		get_tree().quit()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0,0,1280,720),Color("#192f35"))
	draw_string(ThemeDB.fallback_font,Vector2(38,45),"AETHERFALL  /  LEITURA DE COMBATE",HORIZONTAL_ALIGNMENT_LEFT,-1,26,Color("#eee3c4"))
	for i in range(units.size()):
		var origin := Vector2(110+(i%5)*250,175+int(i/5)*150)
		units[i]["walk_clock"] = elapsed + i*0.2
		EnemyArt.draw_unit(self,units[i],origin,0)
		draw_string(ThemeDB.fallback_font,origin+Vector2(-60,40),GameData.enemy_defs()[units[i].type].name,HORIZONTAL_ALIGNMENT_CENTER,120,17,Color("#eee3c4"))
	for i in range(5):
		var enemy := {"type":"boss","radius":29,"color":Color("#"+GameData.boss_defs()[i].color),"walk_clock":elapsed,"hit_flash":0.0}
		EnemyArt.draw_unit(self,enemy,Vector2(110+i*250,495),i)
	SpellArt.meteor(self,Vector2(230,650),0.18)
	SpellArt.meteor(self,Vector2(580,640),0.55)
	SpellArt.freeze(self,Vector2(990,630),0.28)
