class_name FieldEffects
extends Control

var particles: Array[Dictionary] = []
var popups: Array[Dictionary] = []
var rings: Array[Dictionary] = []
var beams: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var motion: float = 1
var enabled: bool = true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rng.seed = 11027

func burst(origin: Vector2, color: Color, count: int = 12, target: Vector2 = Vector2(-1,-1)) -> void:
	if not enabled:
		return
	for i in range(mini(count,40)):
		particles.append({"p":origin,"v":Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(35,155),"age":0.0,"life":rng.randf_range(0.4,0.85),"color":color,"size":rng.randf_range(2,4),"target":target})
	while particles.size() > 320:
		particles.pop_front()

func popup(origin: Vector2, text: String, color: Color) -> void:
	for popup_item in popups:
		if popup_item.age<0.2 and popup_item.p.distance_to(origin)<95 and text.begins_with("+"):
			popup_item.text="+%d" % (int(popup_item.text.trim_prefix("+"))+int(text.trim_prefix("+")))
			return
	popups.append({"p":origin,"text":text,"color":color,"age":0.0})
	if popups.size() > 4:
		popups.pop_front()

func ring(origin: Vector2,color: Color) -> void:
	rings.append({"p":origin,"color":color,"age":0.0})

func beam(start: Vector2, end: Vector2, color: Color) -> void:
	beams.append({"start":start,"end":end,"color":color,"age":0.0})

func _process(delta: float) -> void:
	for i in range(particles.size()-1,-1,-1):
		var p := particles[i]
		p.age += delta
		if p.age > p.life:
			particles.remove_at(i)
			continue
		if p.target.x >= 0 and p.age > 0.15:
			p.v = p.v.lerp((p.target-p.p)*6,delta*7)
		else:
			p.v.y += delta*65
		p.p += p.v*delta*motion
	for i in range(popups.size()-1,-1,-1):
		popups[i].age += delta
		if popups[i].age > 1.4:
			popups.remove_at(i)
	for i in range(rings.size()-1,-1,-1):
		rings[i].age += delta
		if rings[i].age > 0.8:
			rings.remove_at(i)
	for i in range(beams.size()-1,-1,-1):
		beams[i].age += delta
		if beams[i].age > 0.55:
			beams.remove_at(i)
	queue_redraw()

func _draw() -> void:
	for p in particles:
		var color := Color(p.color,float(1-p.age/p.life))
		draw_rect(Rect2(p.p-Vector2.ONE*p.size/2,Vector2.ONE*p.size),color)
	for p in popups:
		var color := Color(p.color,minf(1,(1.4-p.age)*2))
		var origin: Vector2 = p.p+Vector2(0,-p.age*35*motion)
		var font := ThemeDB.fallback_font
		var text_size := font.get_string_size(p.text,HORIZONTAL_ALIGNMENT_LEFT,-1,18)
		draw_string_outline(font,origin-Vector2(text_size.x/2,0),p.text,HORIZONTAL_ALIGNMENT_LEFT,-1,18,5,Color(Palette.INK,color.a))
		draw_string(font,origin-Vector2(text_size.x/2,0),p.text,HORIZONTAL_ALIGNMENT_LEFT,-1,18,color)
	for r in rings:
		draw_arc(r.p,12+r.age*95*motion,0,TAU,50,Color(r.color,0.7*(1-r.age/0.8)),2,true)
	for b in beams:
		var alpha: float = 1-b.age/0.55
		var tip: Vector2 = b.start.lerp(b.end,minf(1,b.age*9))
		draw_line(b.start,tip,Color(b.color,alpha*0.15),12,true)
		draw_line(b.start,tip,Color(b.color,alpha*0.85),2,true)
