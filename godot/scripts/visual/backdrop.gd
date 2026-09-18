class_name AetherfallBackdrop
extends Node2D

const VIEW_SIZE: = Vector2(1280.0, 720.0)
const TAU_VALUE: = PI * 2.0

var mode: = "home"
var world_index: = 0
var time: = 0.0
var landscape: Texture2D = preload("res://art/menu_landscape.png")

func _ready() -> void :
	set_process(true)
	queue_redraw()

func set_scene(next_mode: String, next_world: int = 0) -> void :
	mode = next_mode
	world_index = clampi(next_world, 0, 4)
	visible = true
	queue_redraw()

func _process(delta: float) -> void :
	if not bool(SaveManager.setting("reduced_motion", false)):
		time += delta
	queue_redraw()

func _draw() -> void :
	var world: Dictionary = GameData.worlds()[world_index]
	var accent: = Color("#" + str(world["accent"]))
	var secondary: = Color("#" + str(world["secondary"]))
	var top: = Color("#0d1b31")
	var bottom: = Color("#050914")
	if mode == "map":
		top = accent.darkened(0.78)
		bottom = Color("#050914")
	_draw_gradient(top, bottom)
	if mode == "home":
		draw_texture_rect(landscape, Rect2(Vector2.ZERO, VIEW_SIZE), false)
		_draw_environment_particles(accent, 22)
	else:
		_draw_map_scene(accent, secondary)

func _draw_gradient(top: Color, bottom: Color) -> void :
	for y in range(0, 721, 12):
		var ratio: = float(y) / 720.0
		draw_rect(Rect2(0.0, y, 1280.0, 13.0), top.lerp(bottom, ratio))

func _draw_grid(accent: Color) -> void :
	for x in range(0, 1281, 48):
		draw_line(Vector2(x, 0), Vector2(x, 720), Color(accent, 0.045), 1.0)
	for y in range(0, 721, 48):
		draw_line(Vector2(0, y), Vector2(1280, y), Color(accent, 0.045), 1.0)

func _draw_home_scene(accent: Color, secondary: Color) -> void :
	var horizon: = 488.0
	for index in range(11):
		var radius: = 120.0 + index * 58.0 + sin(time * 0.25 + index) * 3.0
		draw_arc(Vector2(930, 330), radius, PI * 0.96, PI * 1.94, 72, Color(accent, 0.035), 1.0, true)
	for index in range(14):
		var x: = float((index * 103) % 1280)
		var height: = float(54 + (index % 4) * 22)
		draw_colored_polygon(
			PackedVector2Array([Vector2(x - 52, horizon), Vector2(x - 24, horizon - height), Vector2(x + 15, horizon - height * 0.72), Vector2(x + 58, horizon)]), 
			Color(secondary, 0.26)
		)
	_draw_distant_lights(accent, horizon)
	_draw_party(accent)
	_draw_environment_particles(accent, 22)
	draw_line(Vector2(0, horizon), Vector2(1280, horizon), Color(accent, 0.18), 1.0)
	draw_circle(Vector2(930, 330), 112.0 + sin(time * 1.4) * 5.0, Color(accent, 0.045))
	draw_arc(Vector2(930, 330), 112.0 + sin(time * 1.4) * 5.0, 0.0, TAU_VALUE, 80, Color(accent, 0.22), 1.0, true)

func _draw_map_scene(accent: Color, secondary: Color) -> void :
	var path: = PackedVector2Array([Vector2(72, 510), Vector2(252, 402), Vector2(424, 468), Vector2(608, 326), Vector2(814, 384), Vector2(1034, 238), Vector2(1224, 186)])
	draw_polyline(path, Color("#02050bb8"), 32.0, true)
	draw_polyline(path, Color(accent, 0.18), 18.0, true)
	draw_polyline(path, Color(accent, 0.62), 2.0, true)
	for index in range(path.size() - 1):
		var start: Vector2 = path[index]
		var finish: Vector2 = path[index + 1]
		var direction: = start.direction_to(finish)
		var distance: = start.distance_to(finish)
		var cursor: = fmod(time * 22.0 + index * 36.0, maxf(distance, 1.0))
		while cursor < distance:
			draw_line(start + direction * cursor, start + direction * minf(cursor + 9.0, distance), Color(accent, 0.85), 2.0, true)
			cursor += 26.0
	for index in range(5):
		var node: Vector2 = path[index + 1]
		var pulse: = 22.0 + sin(time * 2.0 + index * 0.9) * 2.0
		draw_circle(node, pulse + 8.0, Color(accent, 0.05))
		draw_arc(node, pulse, 0.0, TAU_VALUE, 36, Color(accent, 0.62), 1.5, true)
		draw_circle(node, 7.0, accent)
	_draw_environment_particles(secondary, 30)

func _draw_distant_lights(accent: Color, horizon: float) -> void :
	for index in range(8):
		var x: = fmod(float(index * 171) + time * (8.0 + index), 1360.0) - 40.0
		var y: = horizon - 22.0 - float((index % 3) * 16)
		draw_circle(Vector2(x, y), 2.0 + (index % 2), Color(accent, 0.7))

func _draw_party(accent: Color) -> void :
	var anchors: = [Vector2(364, 516), Vector2(450, 522), Vector2(548, 518), Vector2(645, 520)]
	for index in range(anchors.size()):
		var point: Vector2 = anchors[index]
		var body: = Color("#07101d")
		var glow: = Color(accent, 0.24 + index * 0.03)
		draw_circle(point + Vector2(0, -37), 13.0, Color(body, 0.98))
		draw_colored_polygon(
			PackedVector2Array([point + Vector2(-22, 31), point + Vector2(-15, -18), point + Vector2(0, -29), point + Vector2(15, -18), point + Vector2(24, 31)]), 
			body
		)
		draw_polyline(PackedVector2Array([point + Vector2(-22, 31), point + Vector2(-15, -18), point + Vector2(0, -29), point + Vector2(15, -18), point + Vector2(24, 31)]), glow, 1.4, true)
		draw_line(point + Vector2(-12, -6), point + Vector2(-28 - index * 2, 20), glow, 2.0, true)
		draw_line(point + Vector2(12, -6), point + Vector2(27 + index, 18), glow, 2.0, true)

func _draw_environment_particles(color: Color, count: int) -> void :
	for index in range(count):
		var x: = fmod(float(index * 117) + time * (4.0 + index % 4), 1320.0) - 20.0
		var y: = fmod(float(index * 53) + sin(time * 0.7 + index) * 18.0, 690.0) + 15.0
		draw_circle(Vector2(x, y), 1.0 + (index % 3) * 0.45, Color(color, 0.22 + (index % 3) * 0.08))
