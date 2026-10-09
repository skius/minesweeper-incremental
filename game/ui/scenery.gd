class_name Scenery
extends Control

var time: float = 0
var region: int = 0
var menu: bool = true
var motion: float = 1
var restored: float = 0.0
var sky_texture: GradientTexture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky_texture = GradientTexture2D.new()
	sky_texture.gradient = Gradient.new()
	sky_texture.gradient.set_color(0,Color("293453"))
	sky_texture.gradient.set_color(1,Color("10192b"))
	sky_texture.width = 4
	sky_texture.height = 900
	sky_texture.fill_from = Vector2.ZERO
	sky_texture.fill_to = Vector2(0,1)

func _process(delta: float) -> void:
	time += delta * motion
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("222b48"))
	var accent := Color(Content.REGIONS[region].color)
	# Procedural desktop wallpaper: evening bands, distant hills, sparse pixels.
	draw_texture_rect(sky_texture,Rect2(Vector2.ZERO,size),false)
	for layer in range(4):
		var poly := PackedVector2Array([Vector2(0,size.y)])
		for x in range(0,int(size.x)+40,40):
			var y := size.y-210+layer*49+sin(x*0.004+layer*1.5)*90+sin(x*0.011+layer)*21
			poly.append(Vector2(x,minf(y,size.y-24)))
		poly.append(Vector2(size.x,size.y))
		draw_colored_polygon(poly,Color("2c465a").darkened(layer*0.17))
	for i in range(76):
		var p := Vector2(fmod(i*317.7+17,size.x),fmod(i*149.3+31,size.y*0.67))
		draw_rect(Rect2(p,Vector2(2,2)),Color(accent,0.09+0.06*sin(i+time*0.3)))
	# Desktop rail, present as a quiet framing device rather than extra controls.
	Palette.bevel(self,Rect2(0,size.y-17,size.x,17),Color("536377"),1)
	draw_rect(Rect2(6,size.y-12,7,7),accent)
	draw_string(ThemeDB.fallback_font,Vector2(22,size.y-5),"AFTERLIGHT / FIELD OS",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Palette.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(size.x-112,size.y-5),"LOCAL · OFFLINE",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Palette.WHITE)
	if not menu:
		return
	# Orbital cartography: hand-built vector artwork, slowly breathing in place.
	var origin := Vector2(1030,453)+(size-Vector2(1440,900))/2
	for r in [160,222,279,336]:
		draw_arc(origin,r,0,TAU,120,Color(accent,0.13),1,true)
	draw_line(Vector2(687,446),Vector2(1390,446),Color(accent,0.16),1,true)
	draw_line(Vector2(1030,90),Vector2(1030,793),Color(accent,0.16),1,true)
	for i in range(60):
		var angle := i * TAU / 60
		var dir := Vector2.from_angle(angle)
		draw_line(origin+dir*329,origin+dir*(339 if i%5==0 else 334),Color(accent,0.28),1,true)
	# Tiled island: an isometric field whose lit seams suggest a waking world.
	for row in range(10):
		for col in range(10):
			var p := origin + Vector2((col-row)*27,(row+col)*14-130)
			var dist := Vector2(col-4.5,row-4.5).length()
			if dist > 5.1 or (row == 0 and col < 3):
				continue
			var wave := sin(col*0.8+row*0.7+time*0.35)
			var level := 12 + int(abs(sin(col*9.1+row*3.3))*35)
			var top := p - Vector2(0,level)
			var lit := (col+row)%4 == 0 or float(col+row)/18.0 < restored
			var base := Color("29484b") if not lit else accent.darkened(0.3 + dist*0.04)
			draw_colored_polygon(PackedVector2Array([top+Vector2(-25,0),top+Vector2(0,13),p+Vector2(0,30),p+Vector2(-25,17)]),base.darkened(0.48))
			draw_colored_polygon(PackedVector2Array([top+Vector2(0,13),top+Vector2(25,0),p+Vector2(25,17),p+Vector2(0,30)]),base.darkened(0.65))
			draw_colored_polygon(PackedVector2Array([top+Vector2(0,-13),top+Vector2(25,0),top+Vector2(0,13),top+Vector2(-25,0)]),base)
			draw_polyline(PackedVector2Array([top+Vector2(-25,0),top+Vector2(0,-13),top+Vector2(25,0)]),Color(accent,0.25),1,true)
			if lit:
				draw_circle(top,2+wave*0.5,Palette.WHITE)
				if (col+row)%6==0:
					draw_line(top,top-Vector2(0,28+wave*5),Color(accent,0.5),1.4,true)
	# Survey mast, halo and tiny orbiting companions.
	var mast := origin+Vector2(0,-100)
	draw_line(mast,mast-Vector2(0,172),accent,3,true)
	draw_line(mast+Vector2(-16,8),mast-Vector2(0,35),accent.darkened(0.3),2,true)
	draw_line(mast+Vector2(16,8),mast-Vector2(0,35),accent.darkened(0.3),2,true)
	for r in [18,30,44]:
		draw_arc(mast-Vector2(0,172),r,0,TAU,40,Color(accent,0.4-float(r)/150),1.5,true)
	Palette.star(self,mast-Vector2(0,172),12,Palette.WHITE)
	for i in range(3):
		var p := origin+Vector2(cos(time*0.12+i*2.1)*263,sin(time*0.12+i*2.1)*166)
		draw_circle(p,20,Palette.INK)
		draw_arc(p,20,0,TAU,28,Color(accent,0.35),1,true)
		Palette.icon(self,"drone",p,22,accent)
	draw_string(ThemeDB.fallback_font,origin+Vector2(-209,301),"RESTORE.   RESEARCH.   REPEAT.",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Palette.MUTED)
