class_name SpellArt
extends RefCounted

const METEOR_IMPACT := 0.35
const METEOR_RADIUS := 84.0
const FREEZE_RADIUS := 120.0

static func meteor(canvas: Node2D, point: Vector2, progress: float) -> void:
	if progress < METEOR_IMPACT:
		var approach := progress / METEOR_IMPACT
		# Marker shows the actual damage radius; rock lands on the damage frame.
		canvas.draw_arc(point, METEOR_RADIUS, 0, TAU, 48, Color(1,0.64,0.25,0.65), 2, true)
		for side in [-1,1]:
			canvas.draw_line(point+Vector2(side*12,0),point+Vector2(side*22,0),Color("#ffd49a"),3,true)
		var rock := point + Vector2(110,-170) * pow(1-approach,1.3)
		var direction := Vector2(110,-170).normalized()
		EnemyArt.polygon(canvas,rock,[[0,-7],[18,-44],[10,-8],[6,8],[-8,5]],Color("#f28a42"))
		canvas.draw_line(rock+direction*6,rock+direction*40,Color("#f8c46b"),5,true)
		EnemyArt.polygon(canvas,rock,[[-10,-4],[-4,-11],[7,-9],[12,1],[4,10],[-8,7]],Color("#694039"))
		EnemyArt.polygon(canvas,rock,[[-4,-8],[7,-6],[9,0],[1,2]],Color("#e6ac66"))
	else:
		var after := (progress-METEOR_IMPACT)/(1-METEOR_IMPACT)
		var alpha := 1-after
		canvas.draw_circle(point, 30+after*35, Color(0.12,0.07,0.05,alpha*0.6))
		for i in range(9):
			var direction := Vector2.RIGHT.rotated(i * TAU/9.0 + 0.2)
			var shard := point+direction*(14+after*65)+Vector2(0,-sin(after*PI)*18)
			canvas.draw_line(point+direction*10,point+direction*(25+after*24),Color(0.94,0.47,0.16,alpha*0.7),2,true)
			EnemyArt.polygon(canvas,shard,[[-4,-2],[1,-6],[5,2],[-1,4]],Color(0.9,0.56,0.3,alpha),1-after*0.6)
		if after < 0.18:
			canvas.draw_circle(point, 13+after*170, Color(1,0.9,0.63,(1-after/0.18)*0.75))

static func freeze(canvas: Node2D, point: Vector2, progress: float) -> void:
	var alpha := 1-progress
	var radius := FREEZE_RADIUS * minf(1, progress/0.18)
	canvas.draw_arc(point,radius,0,TAU,48,Color(0.68,0.9,1,alpha*0.6),2,true)
	for i in range(12):
		var angle := float(i)*TAU/12
		var direction := Vector2.RIGHT.rotated(angle)
		var tip := point+direction*radius
		canvas.draw_line(point+direction*18,tip,Color(0.57,0.82,0.95,alpha*0.5),2,true)
		var crystal := point+direction*(34+(i%3)*24)
		EnemyArt.polygon(canvas,crystal,[[0,-14],[5,-3],[2,5],[-4,3]],Color(0.75,0.93,1,alpha), minf(1,progress*8))
