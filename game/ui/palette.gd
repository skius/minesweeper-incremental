class_name Palette
extends RefCounted

const INK = Color("141727")
const PANEL = Color("252b3b")
const PANEL_LIGHT = Color("343e51")
const EDGE = Color("586479")
const WHITE = Color("f5f0df")
const MUTED = Color("aeb8c8")
const MINT = Color("9ae4be")
const GOLD = Color("f5ca7a")
const CORAL = Color("f4988f")
const FRAME = Color("67758a")
const TITLE = Color("536f98")
const TILE = Color("8493a5")
const GLASS = Color("202a3b")
const FLAG = Color("583c54")
static var surface_cache: Dictionary = {}
static var control_cache: Dictionary = {}
const CLUES = [Color("779797"),Color("83c9ed"),Color("92dbb0"),Color("efad7b"),Color("bfa8eb"),Color("ed9bb7"),Color("e1d08b"),Color("eeeecc"),Color("ffffff")]

static func plating(canvas: CanvasItem, center: Vector2, tile: float, layers: int, color: Color) -> void:
	# Six separate laminations: every drilling hit removes a visible layer.
	var pitch := maxf(2,floorf(tile*0.085))
	var width := maxf(8,floorf(tile*0.35))
	var thickness := maxf(1,floorf(pitch*0.55))
	for layer in range(clampi(layers,0,6)):
		var at := (center+Vector2(-width/2,pitch*2.5-layer*pitch)).round()
		canvas.draw_rect(Rect2(at,Vector2(width,thickness)),color)
		if tile>=32:
			canvas.draw_line(at+Vector2(0,thickness),at+Vector2(width,thickness),color.lightened(0.3),1)

static func box(color: Color, radius: int = 12, border: Color = Color.TRANSPARENT, border_width: int = 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(mini(radius,5))
	s.border_color = border
	s.set_border_width_all(border_width)
	if color.a > 0 and radius>0:
		s.border_color = border if border.a>0 else color.lightened(0.22)
		s.border_color = s.border_color.lightened(0.08)
		s.set_border_width_all(maxi(1,border_width))
		s.shadow_color = Color(0.025,0.035,0.06,0.45)
		s.shadow_size = 4
		s.shadow_offset = Vector2(0,4)
	return s

# One procedural nine-patch gives buttons and window panels the same physical edge.
# It stays crisp at different control sizes and is cached across the whole interface.
static func surface(face: Color, raised: bool = true) -> StyleBoxTexture:
	var key := face.to_html()+str(raised)
	if surface_cache.has(key):
		return surface_cache[key]
	var pixels := Image.create(12,12,false,Image.FORMAT_RGBA8)
	pixels.fill(face)
	var light := face.lightened(0.32)
	var shade := face.darkened(0.52)
	for y in range(12):
		for x in range(12):
			var c := face
			if x==0 or y==0 or x==11 or y==11:
				c=Color("141c2b")
			elif x<=2 or y<=2:
				c=light if raised else shade
			elif x>=9 or y>=9:
				c=shade if raised else light
			pixels.set_pixel(x,y,c)
	var style := StyleBoxTexture.new()
	style.texture=ImageTexture.create_from_image(pixels)
	style.set_texture_margin_all(4)
	style.set_content_margin_all(6)
	surface_cache[key]=style
	return style

static func mouse(canvas: CanvasItem, center: Vector2, button: int, color: Color, unit: float = 1.0) -> void:
	var outer := Rect2(center-Vector2(10,14)*unit,Vector2(20,28)*unit)
	canvas.draw_style_box(box(Color.TRANSPARENT,4,color,1),outer)
	canvas.draw_line(center+Vector2(0,-13)*unit,center+Vector2(0,-2)*unit,color,1.3,true)
	canvas.draw_line(center+Vector2(-9,-1)*unit,center+Vector2(9,-1)*unit,color,1.3,true)
	if button in [1,2]:
		canvas.draw_rect(Rect2(center+Vector2(-7 if button==1 else 2,-11)*unit,Vector2(5,8)*unit),color)
	elif button==3:
		canvas.draw_line(center+Vector2(0,-9)*unit,center+Vector2(0,-5)*unit,color,3,true)

static func keycap(canvas: CanvasItem, text: String, rect: Rect2, color: Color) -> void:
	canvas.draw_style_box(surface(PANEL_LIGHT),rect)
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
	canvas.draw_string(font,rect.get_center()+Vector2(-width/2,4),text,HORIZONTAL_ALIGNMENT_LEFT,-1,12,color)

static func control_texture(kind: String) -> ImageTexture:
	if control_cache.has(kind):
		return control_cache[kind]
	var image := Image.create(24,24,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var slider := kind=="slider"
	for y in range(2,22):
		for x in range(4 if slider else 2,20 if slider else 22):
			var shade := PANEL_LIGHT
			if x==(4 if slider else 2) or y==2:
				shade=EDGE.lightened(0.3) if slider else INK
			elif x==(19 if slider else 21) or y==21:
				shade=INK if slider else EDGE
			image.set_pixel(x,y,shade)
	if kind=="checked":
		raster_line(image,Vector2i(6,11),Vector2i(10,16),MINT)
		raster_line(image,Vector2i(10,16),Vector2i(18,7),MINT)
	elif slider:
		raster_line(image,Vector2i(10,7),Vector2i(10,17),MUTED)
		raster_line(image,Vector2i(14,7),Vector2i(14,17),MUTED)
	var texture := ImageTexture.create_from_image(image)
	control_cache[kind]=texture
	return texture

static func raster_line(image: Image, start: Vector2i, finish: Vector2i, color: Color) -> void:
	var count := maxi(absi(finish.x-start.x),absi(finish.y-start.y))
	for i in range(count+1):
		var p := Vector2i(Vector2(start).lerp(Vector2(finish),float(i)/maxi(1,count)).round())
		image.set_pixel(p.x,p.y,color)
		image.set_pixel(p.x+1,p.y,color)

static func icon(canvas: CanvasItem, kind: String, center: Vector2, size_value: float, color: Color) -> void:
	var r := size_value * 0.5
	match kind:
		"zoom_in","zoom_out","zoom_fit":
			if kind=="zoom_fit":
				for x in [-1,1]:
					for y in [-1,1]:
						var p := center+Vector2(x,y)*r*0.75
						canvas.draw_line(p,p-Vector2(x*r*0.45,0),color,1.6,true)
						canvas.draw_line(p,p-Vector2(0,y*r*0.45),color,1.6,true)
			else:
				canvas.draw_arc(center-Vector2.ONE*r*0.16,r*0.63,0,TAU,24,color,1.6,true)
				canvas.draw_line(center+Vector2.ONE*r*0.29,center+Vector2.ONE*r*0.8,color,2,true)
				canvas.draw_line(center+Vector2(-0.5,-0.16)*r,center+Vector2(0.18,-0.16)*r,color,1.4,true)
				if kind=="zoom_in":
					canvas.draw_line(center+Vector2(-0.16,-0.5)*r,center+Vector2(-0.16,0.18)*r,color,1.4,true)
		"pause":
			for side in [-1,1]:
				canvas.draw_rect(Rect2(center+Vector2(side*r*0.43-r*0.15,-r*0.7),Vector2(r*0.3,r*1.4)),color)
		"play":
			canvas.draw_colored_polygon(PackedVector2Array([center+Vector2(-r*0.6,-r*0.85),center+Vector2(r*0.8,0),center+Vector2(-r*0.6,r*0.85)]),color)
		"close":
			canvas.draw_line(center+Vector2(-r,-r)*0.65,center+Vector2(r,r)*0.65,color,2,true)
			canvas.draw_line(center+Vector2(-r,r)*0.65,center+Vector2(r,-r)*0.65,color,2,true)
		"arrow":
			canvas.draw_line(center+Vector2(-r,0),center+Vector2(r,0),color,1.5,true)
			canvas.draw_polyline(PackedVector2Array([center+Vector2(r*0.4,-r*0.6),center+Vector2(r,0),center+Vector2(r*0.4,r*0.6)]),color,1.5,true)
		"core":
			canvas.draw_rect(Rect2(center-Vector2.ONE*r*0.58,Vector2.ONE*r*1.16),color,false,1.8)
			canvas.draw_rect(Rect2(center-Vector2.ONE*r*0.22,Vector2.ONE*r*0.44),color)
			for side in [-1,1]:
				for offset in [-0.3,0.3]:
					canvas.draw_line(center+Vector2(side*r*0.6,offset*r),center+Vector2(side*r,offset*r),color,1.5,true)
					canvas.draw_line(center+Vector2(offset*r,side*r*0.6),center+Vector2(offset*r,side*r),color,1.5,true)
		"mine":
			canvas.draw_circle(center,r*0.55,color)
			for angle in range(8):
				var direction := Vector2.from_angle(angle*TAU/8)
				canvas.draw_line(center+direction*r*0.35,center+direction*r*0.9,color,1.4,true)
			canvas.draw_circle(center+Vector2(-r*0.18,-r*0.18),r*0.13,INK)
		"tree":
			for p in [Vector2(-0.65,-0.6),Vector2(0.65,-0.6),Vector2(0,0.7)]:
				canvas.draw_line(center,center+p*r,color,1.5,true)
				canvas.draw_rect(Rect2(center+p*r-Vector2.ONE*r*0.22,Vector2.ONE*r*0.44),color,false,1.5)
			canvas.draw_circle(center,r*0.17,color)
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
		"energy":
			canvas.draw_colored_polygon(PackedVector2Array([center+Vector2(0.2,-1)*r,center+Vector2(-0.64,0.16)*r,center+Vector2(-0.06,0.16)*r,center+Vector2(-0.24,1)*r,center+Vector2(0.66,-0.2)*r,center+Vector2(0.12,-0.2)*r]),color)
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

# A bevel uses explicit top light and bottom shade, like a physical keycap.
static func bevel(canvas: CanvasItem, rect: Rect2, face: Color, thickness: float = 3, raised: bool = true) -> void:
	canvas.draw_rect(rect,face)
	var light := face.lightened(0.35)
	var dark := face.darkened(0.55)
	if not raised:
		var swap := light
		light=dark
		dark=swap
	canvas.draw_colored_polygon(PackedVector2Array([rect.position,rect.position+Vector2(rect.size.x,0),rect.position+Vector2(rect.size.x-thickness,thickness),rect.position+Vector2(thickness,thickness),rect.position+Vector2(thickness,rect.size.y-thickness),rect.position+Vector2(0,rect.size.y)]),light)
	canvas.draw_colored_polygon(PackedVector2Array([rect.end,rect.position+Vector2(0,rect.size.y),rect.position+Vector2(thickness,rect.size.y-thickness),rect.end-Vector2(thickness,thickness),rect.position+Vector2(rect.size.x-thickness,thickness),rect.position+Vector2(rect.size.x,0)]),dark)

static func digits(canvas: CanvasItem, text_value: String, origin: Vector2, scale_value: float, color: Color) -> void:
	var masks := [63,6,91,79,102,109,125,7,127,111]
	var segments := [[Vector2(2,0),Vector2(9,0)],[Vector2(10,1),Vector2(10,8)],[Vector2(10,11),Vector2(10,18)],[Vector2(2,20),Vector2(9,20)],[Vector2(0,11),Vector2(0,18)],[Vector2(0,1),Vector2(0,8)],[Vector2(2,10),Vector2(9,10)]]
	for k in range(text_value.length()):
		var digit := int(text_value[k])
		for j in range(7):
			var c := color if int(masks[digit]) & (1<<j) else Color(color,0.07)
			canvas.draw_line(origin+Vector2(k*15,0)*scale_value+segments[j][0]*scale_value,origin+Vector2(k*15,0)*scale_value+segments[j][1]*scale_value,c,2*scale_value,true)
