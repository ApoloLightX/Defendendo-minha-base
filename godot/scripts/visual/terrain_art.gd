class_name TerrainArt
extends RefCounted


var props: Array[Dictionary] = []
var palette: Array[Color] = []

func prepare(world: int, path: Array[Vector2], spots: Array) -> void :
	var palettes: = [
		[Color("#193f38"), Color("#25564a"), Color("#47765b"), Color("#9fbd7a")], 
		[Color("#653d39"), Color("#98604a"), Color("#c58b60"), Color("#e2bd85")], 
		[Color("#202f42"), Color("#354957"), Color("#59727a"), Color("#9ec4c6")], 
		[Color("#254757"), Color("#46717e"), Color("#83a7b2"), Color("#dbedf0")], 
		[Color("#231e3c"), Color("#45365b"), Color("#78618c"), Color("#c9b0d5")]
	]
	palette.assign(palettes[world])
	props.clear()
	var random: = RandomNumberGenerator.new()
	random.seed = 8103 + world * 193
	for i in range(190):
		var point: = Vector2(random.randf_range(10, 1270), random.randf_range(45, 670))
		var clear: = true
		for j in range(path.size() - 1):
			if Geometry2D.get_closest_point_to_segment(point, path[j], path[j + 1]).distance_to(point) < 62.0:
				clear = false
				break
		for spot in spots:
			if point.distance_to(Vector2(spot["x"], spot["y"])) < 55.0: clear = false
		if clear: props.append({"point": point, "size": random.randf_range(12, 30), "variant": i % 4})
	props.sort_custom( func(a, b): return a["point"].y < b["point"].y)

func draw_ground(canvas: Node2D, world: int) -> void :
	canvas.draw_rect(Rect2(0, 0, 1280, 720), palette[0])
	for i in range(140):
		var p: = Vector2((i * 173) % 1280, (i * 89) % 720)
		canvas.draw_circle(p, 24.0 + i % 43, Color(palette[1], 0.22))
	for prop in props:
		var p: Vector2 = prop["point"]
		var s: float = prop["size"]
		var variant: int = prop["variant"]
		canvas.draw_circle(p + Vector2(7, 7), s, Color("#08121c55"))
		if world == 0:
			canvas.draw_line(p, p + Vector2(0, - s), Color("#6b5844"), 6)
			for tier in range(3):
				var top: = p + Vector2(0, - s * 1.7 - tier * 10)
				var w: = s * (1.0 - tier * 0.18)
				canvas.draw_colored_polygon(PackedVector2Array([top, top + Vector2(w, s * 1.5), top + Vector2( - w, s * 1.5)]), palette[1].lightened(tier * 0.065))
				canvas.draw_line(top, top + Vector2( - w, s * 1.5), palette[2], 1, true)
		elif world == 2:
			canvas.draw_rect(Rect2(p - Vector2(s, s * 1.5), Vector2(s * 2, s * 2)), palette[1])
			canvas.draw_rect(Rect2(p - Vector2(s, s * 1.5), Vector2(s * 2, s * 0.5)), palette[2])
			for window in range(3):
				canvas.draw_rect(Rect2(p + Vector2( - s + 4 + window * s * 0.55, - s * 0.65), Vector2(3, 6)), palette[3])
		else:
			var top: = p + Vector2( - s * 0.15, - s * (2.0 if world >= 3 else 0.9))
			canvas.draw_colored_polygon(PackedVector2Array([p + Vector2( - s, 0), top, p + Vector2(s, - s * 0.3), p + Vector2(s * 0.6, s * 0.5)]), palette[2])
			canvas.draw_colored_polygon(PackedVector2Array([top, p + Vector2(s, - s * 0.3), p + Vector2(s * 0.6, s * 0.5), p]), palette[1])
			canvas.draw_line(top, p + Vector2( - s, 0), palette[3], 2, true)
			if world == 1 and variant == 0:
				canvas.draw_line(p, p + Vector2(0, - s * 1.6), Color("#667255"), 5)
				canvas.draw_line(p + Vector2(0, - s * 0.6), p + Vector2(9, - s), Color("#82916a"), 4)

func draw_route(canvas: Node2D, points: PackedVector2Array) -> void :
	canvas.draw_polyline(points, palette[0].darkened(0.3), 44, true)
	canvas.draw_polyline(points, palette[2].darkened(0.28), 36, true)
	canvas.draw_polyline(points, palette[2].darkened(0.16), 27, true)
	for i in range(points.size() - 1):
		var length: = points[i].distance_to(points[i + 1])
		var direction: = points[i].direction_to(points[i + 1])
		for step in range(12, int(length), 22):
			var p: = points[i] + direction * step
			canvas.draw_line(p - direction.orthogonal() * 11, p + direction.orthogonal() * 11, Color(palette[0], 0.22), 1, true)
