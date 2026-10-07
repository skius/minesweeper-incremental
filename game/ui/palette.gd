class_name Palette
extends RefCounted

const INK = Color("091820")
const PANEL = Color("102630")
const PANEL_LIGHT = Color("17343d")
const EDGE = Color("294750")
const WHITE = Color("f3eedf")
const MUTED = Color("9aafb1")
const MINT = Color("78dfbd")
const GOLD = Color("f2cf81")
const CORAL = Color("ef947e")
const CLUES = [Color("779797"),Color("83c9ed"),Color("92dbb0"),Color("efad7b"),Color("bfa8eb"),Color("ed9bb7"),Color("e1d08b"),Color("eeeecc"),Color("ffffff")]

static func box(color: Color, radius: int = 12, border: Color = Color.TRANSPARENT, border_width: int = 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.border_color = border
	s.set_border_width_all(border_width)
	return s

static func icon(canvas: CanvasItem, kind: String, center: Vector2, size_value: float, color: Color) -> void:
	var r := size_value * 0.5
	match kind:
		"flag":
			canvas.draw_line(center + Vector2(-r * 0.3, r), center + Vector2(-r * 0.3, -r), color, 2, true)
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(-r*0.3,-r), center + Vector2(r*0.8,-r*0.55), center + Vector2(-r*0.3,0)]), color)
			canvas.draw_line(center + Vector2(-r * 0.65,r), center + Vector2(r*0.35,r), color, 2, true)
		"lens", "pulse":
			canvas.draw_arc(center, r*0.68, 0, TAU, 32, color, 1.8, true)
			canvas.draw_circle(center, r*0.20, color)
			for angle in [0, PI/2, PI, 3*PI/2]:
				var dir := Vector2.from_angle(angle)
				canvas.draw_line(center + dir*r*0.82, center+dir*r*1.1, color, 1.5, true)
		"drone", "fleet":
			canvas.draw_colored_polygon(PackedVector2Array([center+Vector2(0,-r*0.6), center+Vector2(r*0.5,0),center+Vector2(0,r*0.6),center+Vector2(-r*0.5,0)]),color)
			for side in [-1,1]:
				var p := center + Vector2(side*r*0.85,0)
				canvas.draw_arc(p,r*0.32,0,TAU,16,color,1.8,true)
				canvas.draw_line(p,center,color,1.5,true)
		"cross", "nova":
			for angle in [0,PI/2,PI,3*PI/2]:
				var dir := Vector2.from_angle(angle)
				canvas.draw_line(center+dir*r*0.32,center+dir*r,color,2.8,true)
			canvas.draw_circle(center,r*0.2,color)
			if kind == "nova":
				canvas.draw_arc(center,r*0.8,0,TAU,32,Color(color,0.45),1,true)
		"line":
			canvas.draw_line(center+Vector2(-r,0),center+Vector2(r,0),color,3,true)
			canvas.draw_line(center+Vector2(-r,-r*0.5),center+Vector2(-r,r*0.5),color,1.6,true)
			canvas.draw_line(center+Vector2(r,-r*0.5),center+Vector2(r,r*0.5),color,1.6,true)
		"shield":
			canvas.draw_polyline(PackedVector2Array([center+Vector2(-r,-r*0.7),center+Vector2(0,-r),center+Vector2(r,-r*0.7),center+Vector2(r*0.7,r*0.35),center+Vector2(0,r),center+Vector2(-r*0.7,r*0.35),center+Vector2(-r,-r*0.7)]),color,2,true)
		"battery":
			canvas.draw_rect(Rect2(center-Vector2(r*0.6,r),Vector2(r*1.2,r*2)),color,false,1.8)
			canvas.draw_line(center+Vector2(-r*0.3,0),center+Vector2(r*0.3,0),color,2,true)
			canvas.draw_line(center+Vector2(0,-r*0.3),center+Vector2(0,r*0.3),color,2,true)
		_:
			canvas.draw_polyline(PackedVector2Array([center+Vector2(0,-r),center+Vector2(r,0),center+Vector2(0,r),center+Vector2(-r,0),center+Vector2(0,-r)]),color,2,true)
			canvas.draw_line(center+Vector2(-r,0),center+Vector2(r,0),Color(color,0.45),1,true)

static func star(canvas: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(8):
		points.append(center + Vector2.from_angle(i * TAU / 8 - PI/2) * (radius if i % 2 == 0 else radius * 0.26))
	canvas.draw_colored_polygon(points, color)
