class_name UpgradeTree
extends Control

signal selected(id: String)
signal activate(id: String)
var session: GameSession
var zoom: float = 0.76
var pan := Vector2.ZERO
var hovered: String = ""
var chosen: String = "lens"
var time: float = 0
var dragging: bool = false
var motion: float = 1
var font: Font = ThemeDB.fallback_font
var burst_id: String = ""
var burst_age: float = 9

func _ready() -> void:
	clip_contents = true
	mouse_filter = MOUSE_FILTER_STOP
	focus_mode = FOCUS_ALL
	mouse_default_cursor_shape = CURSOR_POINTING_HAND

func center_for(id: String) -> Vector2:
	return size/2 + pan + Content.tree_position(Content.upgrade(id))*zoom

func visible_node(item: Dictionary) -> bool:
	if item.id == "lens" or session.has(item.id):
		return true
	if item.rank > session.index + 8:
		return false
	if session.has(item.pre):
		return true
	var parent := Content.upgrade(item.pre)
	return not parent.is_empty() and session.has(parent.pre)

func node_at(p: Vector2) -> String:
	for item in Content.UPGRADES:
		if visible_node(item) and p.distance_to(center_for(item.id)) < 26*zoom+6:
			return item.id
	return ""

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if dragging:
			pan += event.relative
			pan = pan.clamp(Vector2(-510,-510),Vector2(510,510))
		var next := node_at(event.position)
		if next != hovered:
			hovered = next
			if hovered != "":
				selected.emit(hovered)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom = minf(1.4,zoom+0.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom = maxf(0.44,zoom-0.1)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				grab_focus()
				var id := node_at(event.position)
				if id != "":
					chosen = id
					selected.emit(id)
					if event.double_click:
						activate.emit(id)
				else:
					dragging = true
			else:
				dragging = false
	if event is InputEventKey and event.pressed:
		if event.keycode in [KEY_ENTER,KEY_SPACE]:
			activate.emit(chosen)
		elif event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:
			var direction: Vector2 = {KEY_LEFT:Vector2.LEFT,KEY_RIGHT:Vector2.RIGHT,KEY_UP:Vector2.UP,KEY_DOWN:Vector2.DOWN}[event.keycode]
			var best := 100000.0
			var next := chosen
			for item in Content.UPGRADES:
				if not visible_node(item) or item.id == chosen:
					continue
				var delta := center_for(item.id)-center_for(chosen)
				var dot := delta.normalized().dot(direction)
				if dot > 0.3 and delta.length()/dot < best:
					best = delta.length()/dot
					next = item.id
			chosen = next
			selected.emit(chosen)
			pan = -Content.tree_position(Content.upgrade(chosen))*zoom*0.6
		accept_event()
	queue_redraw()

func _process(delta: float) -> void:
	time += delta*motion
	burst_age += delta
	queue_redraw()

func _draw() -> void:
	if session == null:
		return
	var origin := size/2+pan
	for radius in [130,245,355,475,590]:
		draw_arc(origin,radius*zoom,0,TAU,120,Color(Palette.MUTED,0.04),1,true)
	for i in range(100):
		var point := Vector2(fmod(i*137.4,size.x),fmod(i*263.9,size.y))
		draw_circle(point,0.75,Color(Palette.MUTED,0.08))
	for item in Content.UPGRADES:
		if item.id == "lens" or not visible_node(item):
			continue
		var color := Palette.MUTED
		var a := center_for(item.pre)
		var b := center_for(item.id)
		var owned := session.has(item.id)
		var curve := Curve2D.new()
		var delta := b-a
		curve.add_point(a,Vector2.ZERO,delta.rotated(-0.16)*0.34)
		curve.add_point(b,-delta.rotated(0.16)*0.34,Vector2.ZERO)
		var points := curve.get_baked_points()
		var highlighted: bool = item.id==chosen or item.id==hovered
		draw_polyline(points,Color(Palette.INK,0.8),4.5*zoom,true)
		draw_polyline(points,Color(Palette.MINT if highlighted else color,0.2 if not owned else 0.58),1.6*zoom,true)
		if owned and highlighted and motion>0:
			var spark := curve.sample_baked(fmod(time*30+item.rank*11,curve.get_baked_length()))
			draw_circle(spark,2.5*zoom,Palette.WHITE)
	for item in Content.UPGRADES:
		if not visible_node(item):
			continue
		var p := center_for(item.id)
		var owned := session.has(item.id)
		var ready := session.unlock_reason(item) == "READY TO INSTALL"
		var lit: bool = hovered == item.id or chosen == item.id
		var color := Palette.MINT if lit else (Palette.WHITE if owned else Palette.MUTED)
		var radius := (33 if item.id=="lens" else 25)*zoom
		var rect := Rect2(p-Vector2.ONE*radius,Vector2.ONE*radius*2)
		draw_rect(Rect2(rect.position+Vector2(2,4),rect.size),Color(0,0,0,0.25))
		draw_style_box(Palette.surface(Palette.PANEL_LIGHT if owned or lit else Palette.PANEL,not owned),rect)
		if lit:
			draw_rect(rect.grow(3),Palette.MINT,false,1.5)
		Palette.icon(self,item.icon,p,maxf(15,26*zoom),color if owned or ready or lit else color.darkened(0.3))
		if owned:
			draw_rect(Rect2(p+Vector2(radius-4,radius-4),Vector2(4,4)),Palette.MINT)
		elif ready:
			draw_circle(p+Vector2(radius-2,-radius+2),3,Palette.GOLD)
		if lit:
			var text_width := font.get_string_size(item.name,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x
			draw_string_outline(font,p+Vector2(-text_width/2,radius+25),item.name,HORIZONTAL_ALIGNMENT_LEFT,-1,15,5,Palette.INK)
			draw_string(font,p+Vector2(-text_width/2,radius+25),item.name,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Palette.WHITE)
	if burst_age < 1.3 and burst_id != "" and motion>0:
		var p := center_for(burst_id)
		draw_arc(p,30+burst_age*95,0,TAU,64,Color(Palette.GOLD,1-burst_age/1.3),3,true)
