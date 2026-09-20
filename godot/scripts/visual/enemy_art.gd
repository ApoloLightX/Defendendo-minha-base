class_name EnemyArt
extends RefCounted

## Articulação visual independente de atributos e colisão.
## Pontos em coordenadas locais; nenhuma textura externa necessária.
static func polygon(canvas: Node2D, origin: Vector2, points: Array, color: Color, scale_value: float = 1.0, facing: float = 1.0) -> void:
	var vertices := PackedVector2Array()
	for point in points:
		vertices.append(origin + Vector2(point[0] * facing, point[1]) * scale_value)
	canvas.draw_colored_polygon(vertices, color)

static func draw_unit(canvas: Node2D, enemy: Dictionary, position: Vector2, world: int, opacity: float = 1.0) -> void:
	var kind: String = enemy["type"]
	var clock: float = float(enemy.get("walk_clock", 0.0))
	var facing: float = float(enemy.get("facing", 1.0))
	var stride := sin(clock * 9.0)
	var size := float(enemy["radius"]) / 12.0
	var ink := Color("#18232b", opacity)
	var steel := Color("#758d96", opacity)
	var skin := Color("#b6b593", opacity)
	var accent: Color = Color(enemy["color"], opacity)
	if float(enemy["hit_flash"]) > 0.0: accent = Color(1, 0.94, 0.8, opacity)
	var cloak := Color(accent.darkened(0.55), opacity)
	var foot := position + Vector2(0, 7 * size)
	canvas.draw_line(foot + Vector2(-9, 1) * size, foot + Vector2(10, 1) * size, Color(0.02, 0.04, 0.06, 0.25 * opacity), 7 * size, true)
	if kind == "boss":
		draw_boss(canvas, position, world, clock, accent, ink, opacity)
		return
	var body := position + Vector2(0, -absf(stride) * 1.6 * size)
	if kind == "flying":
		var flap := sin(clock * 12.0) * 9.0
		for side in [-1.0, 1.0]:
			polygon(canvas, body, [[3, -7], [29, -20 + flap], [22, 0], [13, -3], [6, 7]], cloak, size, side)
			canvas.draw_line(body + Vector2(4 * side, -6) * size, body + Vector2(27 * side, -18 + flap) * size, accent, 2, true)
		polygon(canvas, body, [[0,-15],[8,-3],[5,9],[0,13],[-5,9],[-8,-3]], ink, size)
		polygon(canvas, body, [[0,-12],[5,-4],[0,2],[-5,-4]], accent, size)
		return
	if kind == "runner":
		for leg in range(4):
			var offset := sin(clock * 16 + leg * PI * 0.7) * 5
			var start := body + Vector2(-10 + leg * 6, 3) * size
			canvas.draw_line(start, start + Vector2(offset, 10) * size, ink, 4 * size, true)
		polygon(canvas, body, [[-18,-2],[-11,-10],[9,-10],[18,-17],[24,-5],[14,3],[-9,6]], cloak, size, facing)
		polygon(canvas, body, [[-15,-7],[-10,-16],[-4,-11],[1,-19],[7,-11],[11,-15],[15,-7]], accent, size, facing)
		canvas.draw_line(body + Vector2(14 * facing,-8)*size,body + Vector2(19 * facing,-8)*size, Color("#fff1b8",opacity), 2, true)
		return
	for side in [-1.0, 1.0]:
		var hip := body + Vector2(side * 5, 3) * size
		var ankle := foot + Vector2(side * 5 + stride * side * 4, 0) * size
		canvas.draw_line(hip, ankle, ink, 5 * size, true)
		canvas.draw_line(ankle, ankle + Vector2(4 * facing, 0) * size, steel, 3 * size, true)
	var robed := kind in ["healer", "summoner", "teleporter"]
	if robed:
		polygon(canvas, body, [[-6,-19],[6,-19],[9,-5],[13,8],[3,5],[-5,9],[-12,6],[-8,-7]], cloak, size)
		polygon(canvas, body, [[0,-16],[5,-10],[6,4],[0,7],[-3,-5]], accent, size)
	else:
		polygon(canvas, body, [[-9,-15],[8,-15],[11,-6],[7,4],[-7,4],[-11,-5]], cloak, size)
		polygon(canvas, body, [[-7,-14],[7,-14],[7,-7],[0,-3],[-7,-7]], steel if kind in ["armored","tank"] else accent, size)
		canvas.draw_line(body + Vector2(-8,1)*size,body+Vector2(8,1)*size, ink, 3*size, true)
	# Cabeça e visor permanecem identificáveis quando unidades se agrupam.
	polygon(canvas, body, [[-6,-25],[4,-26],[8,-20],[4,-14],[-5,-14],[-8,-20]], ink, size, facing)
	polygon(canvas, body, [[-4,-22],[5,-22],[5,-17],[-4,-17]], skin, size, facing)
	canvas.draw_line(body+Vector2(-1*facing,-20)*size,body+Vector2(5*facing,-20)*size, ink, 2*size, true)
	match kind:
		"armored", "tank":
			for side in [-1.0,1.0]:
				polygon(canvas, body, [[7,-16],[14,-17],[17,-9],[9,-6]], steel, size, side)
			polygon(canvas, body, [[-8,-26],[0,-30],[8,-25],[7,-20],[-8,-20]], steel, size)
			canvas.draw_line(body+Vector2(13,-4)*size,body+Vector2(18,7)*size,ink,5*size,true)
			polygon(canvas,body,[[12,2],[22,0],[24,8],[15,10]],accent,size)
		"shielded":
			var shield := accent if float(enemy["shield"]) > 0 else steel.darkened(0.35)
			polygon(canvas,body,[[6,-15],[19,-12],[18,2],[12,7],[6,1]],ink,size,facing)
			polygon(canvas,body,[[8,-12],[17,-10],[16,1],[12,4],[8,0]],shield,size,facing)
		"healer", "summoner":
			canvas.draw_line(body+Vector2(14,6)*size,body+Vector2(14,-29)*size,Color("#a68a62",opacity),3*size,true)
			if kind == "healer":
				polygon(canvas,body,[[14,-33],[19,-26],[14,-20],[9,-26]],accent,size)
			else:
				polygon(canvas,body,[[8,-31],[20,-31],[20,-21],[8,-21]],accent,size)
				canvas.draw_line(body+Vector2(14,-30)*size,body+Vector2(14,-22)*size,ink,2,true)
		"saboteur":
			polygon(canvas,body,[[-15,-16],[-8,-16],[-8,-3],[-17,-3]],Color("#815448",opacity),size)
			canvas.draw_line(body+Vector2(10,-7)*size,body+Vector2(19,-15)*size,steel,4*size,true)
			polygon(canvas,body,[[17,-18],[24,-19],[25,-13],[19,-10]],accent,size)
		"teleporter":
			polygon(canvas,body,[[-8,-23],[0,-34],[9,-23],[5,-20],[0,-26],[-5,-20]],accent,size)
			if float(enemy["teleport_charge"]) > 0:
				for side in [-1.0,1.0]:
					canvas.draw_line(body+Vector2(side*20,-30)*size,body+Vector2(side*20,10)*size,accent,3,true)
		_:
			canvas.draw_line(body+Vector2(11,3)*size,body+Vector2(14,-17)*size,steel,3*size,true)
			polygon(canvas,body,[[11,-17],[15,-24],[18,-16]],steel,size)

static func draw_boss(canvas: Node2D, p: Vector2, world: int, clock: float, accent: Color, ink: Color, opacity: float) -> void:
	var stone := Color("#68757b",opacity)
	var step := sin(clock * 5) * 3
	for side in [-1.0,1.0]:
		polygon(canvas,p,[[side*8,-1],[side*23,-1],[side*24,21+side*step],[side*7,21+side*step]],ink)
	polygon(canvas,p,[[-25,-36],[22,-36],[30,-16],[19,9],[-18,9],[-30,-14]],accent.darkened(0.6))
	polygon(canvas,p,[[-17,-33],[15,-33],[18,-15],[0,0],[-18,-15]],stone)
	polygon(canvas,p,[[-12,-54],[10,-54],[15,-42],[9,-30],[-10,-30],[-16,-43]],ink)
	canvas.draw_line(p+Vector2(-8,-42),p+Vector2(9,-42),accent,4,true)
	match world:
		0:
			for side in [-1.0,1.0]:
				canvas.draw_polyline(PackedVector2Array([p+Vector2(side*10,-48),p+Vector2(side*24,-65),p+Vector2(side*30,-61),p+Vector2(side*34,-75)]),Color("#a2ad78",opacity),5,true)
			polygon(canvas,p,[[-32,-39],[-47,-26],[-39,-13],[-25,-19]],accent.darkened(0.3))
		1:
			polygon(canvas,p,[[-20,-50],[0,-69],[21,-49],[14,-43],[-14,-43]],Color("#b28c5e",opacity))
			for side in [-1.0,1.0]: polygon(canvas,p,[[23,-34],[39,-25],[42,2],[25,4]],stone,1,side)
		2:
			for side in [-1.0,1.0]:
				polygon(canvas,p,[[21,-38],[43,-38],[43,-16],[21,-16]],stone,1,side)
				canvas.draw_line(p+Vector2(side*26,-27),p+Vector2(side*47,-27),ink,8,true)
			polygon(canvas,p,[[-7,-24],[7,-24],[7,-10],[-7,-10]],accent)
		3:
			polygon(canvas,p,[[-16,-51],[-20,-69],[-6,-60],[0,-78],[7,-60],[21,-69],[16,-51]],accent)
			polygon(canvas,p,[[24,-35],[45,-52],[37,-20],[26,-11]],accent.lightened(0.2))
		4:
			for side in [-1.0,1.0]: polygon(canvas,p,[[18,-44],[42,-61],[32,-23],[47,12],[22,1]],accent.darkened(0.35),1,side)
			polygon(canvas,p,[[-10,-56],[0,-73],[11,-56]],accent)
