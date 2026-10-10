class_name BoardView
extends Control

signal cell_pressed(index: int, right: bool)
signal cell_hovered(index: int)
signal zoom_changed(value: float)

var changed_clues: Dictionary = {}
var session: GameSession
var hover: int = -1
var keyboard_cell: int = -1
var active_tool: String = ""
var blocked: bool = false
var high_contrast: bool = false
var motion: float = 1
var animations: Dictionary = {}
var tile_size: float = 48
var zoom: float = 1
var visible_columns: int = 1
var visible_rows: int = 1
var view_offset := Vector2i.ZERO
var panning: bool = false
var pan_start := Vector2.ZERO
var pan_offset := Vector2i.ZERO
var grid_origin: Vector2
var time: float = 0
var shake: float = 0
var complete_wave: float = -1
var rejected_cell: int = -1
var reject_age: float = 0
var strike_age: float = 0
var drone_positions: Array[Vector2] = []
var drone_targets: Array[Vector2] = []
var drone_hold: Array[float] = []
var next_drone: int = 0
var font: Font = ThemeDB.fallback_font
var tile_style := Palette.box(Color.WHITE,6,Palette.EDGE)
var shadow_style := Palette.box(Color("07151c"),6)
var tile_textures: Dictionary = {}
var frame_style := Palette.box(Palette.PANEL.darkened(0.12),16,Palette.EDGE)

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	mouse_default_cursor_shape = CURSOR_POINTING_HAND
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_exited.connect(func():
		hover=-1
		cell_hovered.emit(-1)
		queue_redraw()
	)

func geometry() -> void:
	if session == null:
		return
	var fit := floorf(minf((size.x-64)/session.board.width,(size.y-176)/session.board.height))
	tile_size = minf(floorf(fit*zoom),90 if zoom>1 else 70)
	visible_columns=mini(session.board.width,maxi(1,int((size.x-64)/tile_size)))
	visible_rows=mini(session.board.height,maxi(1,int((size.y-176)/tile_size)))
	view_offset=view_offset.clamp(Vector2i.ZERO,Vector2i(session.board.width-visible_columns,session.board.height-visible_rows))
	grid_origin=Vector2((size.x-visible_columns*tile_size)/2,108+(size.y-176-visible_rows*tile_size)/2)

func cell_position(i: int) -> Vector2:
	geometry()
	return grid_origin + (Vector2(i % session.board.width + 0.5,i / session.board.width + 0.5)-Vector2(view_offset))*tile_size

func visible_cell(i: int) -> bool:
	geometry()
	return i>=0 and i%session.board.width>=view_offset.x and i%session.board.width<view_offset.x+visible_columns and i/session.board.width>=view_offset.y and i/session.board.width<view_offset.y+visible_rows

func set_zoom(value: float, anchor: int = -1, pointer: Vector2 = Vector2.INF) -> void:
	geometry()
	if anchor<0:
		anchor=(view_offset.y+visible_rows/2)*session.board.width+view_offset.x+visible_columns/2
	zoom=clampf(value,1,2.5)
	geometry()
	view_offset=Vector2i(anchor%session.board.width-visible_columns/2,anchor/session.board.width-visible_rows/2)
	geometry()
	reproject_pointer(get_local_mouse_position() if pointer==Vector2.INF else pointer)
	reset_drone_positions()
	zoom_changed.emit(zoom)
	queue_redraw()

func reproject_pointer(pointer: Vector2) -> void:
	keyboard_cell=-1
	hover=index_at(pointer)
	cell_hovered.emit(hover)
	queue_redraw()

func ensure_cell_visible(i: int) -> void:
	geometry()
	var cell := Vector2i(i%session.board.width,i/session.board.width)
	view_offset.x=clampi(view_offset.x,cell.x-visible_columns+1,cell.x)
	view_offset.y=clampi(view_offset.y,cell.y-visible_rows+1,cell.y)
	geometry()

func reset_drone_positions() -> void:
	for i in range(drone_positions.size()):
		drone_hold[i]=0
		drone_targets[i]=Vector2(size.x-200-i*22,80)
		drone_positions[i]=drone_targets[i]

func minimap_rect() -> Rect2:
	return Rect2(size.x-232,size.y-56,80,32)

func index_at(p: Vector2) -> int:
	geometry()
	var local := p-grid_origin
	if local.x < 0 or local.y < 0:
		return -1
	var x := int(local.x/tile_size)
	var y := int(local.y/tile_size)
	return (y+view_offset.y)*session.board.width+x+view_offset.x if x<visible_columns and y<visible_rows else -1

func _gui_input(event: InputEvent) -> void:
	if blocked or session == null:
		return
	if event is InputEventMouseMotion:
		if panning:
			view_offset=pan_offset+Vector2i((pan_start-event.position)/tile_size)
			geometry()
			reset_drone_positions()
			reproject_pointer(event.position)
			accept_event()
			return
		reproject_pointer(event.position)
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_MIDDLE:
			panning=event.pressed
			pan_start=event.position
			pan_offset=view_offset
			reproject_pointer(event.position)
			accept_event()
			return
		if not event.pressed:
			return
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			set_zoom(zoom+(0.25 if event.button_index==MOUSE_BUTTON_WHEEL_UP else -0.25),index_at(event.position),event.position)
			accept_event()
			return
		if zoom>1 and minimap_rect().has_point(event.position):
			var relative: Vector2=(event.position-minimap_rect().position)/minimap_rect().size
			view_offset=Vector2i(relative*Vector2(session.board.width,session.board.height))-Vector2i(visible_columns/2,visible_rows/2)
			geometry()
			reset_drone_positions()
			reproject_pointer(event.position)
			accept_event()
			return
		var i := index_at(event.position)
		if i >= 0 and event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]:
			reproject_pointer(event.position)
			cell_pressed.emit(i,event.button_index == MOUSE_BUTTON_RIGHT)
			accept_event()

func animate_cells(cells: Array, source: String) -> void:
	for j in range(cells.size()):
		animations[cells[j]] = -minf(j*0.015,0.5)

func visit_drone(cell: int) -> void:
	var count := session.drone_count()
	if count<=0 or not visible_cell(cell):
		return
	ensure_drones(count)
	var worker := next_drone%count
	drone_targets[worker] = cell_position(cell)-Vector2.ONE*tile_size*0.31
	drone_hold[worker] = 0.9
	next_drone+=1

func ensure_drones(count: int) -> void:
	while drone_positions.size() < count:
		drone_positions.append(Vector2(size.x-200-drone_positions.size()*22,80))
		drone_targets.append(Vector2(size.x-200-drone_targets.size()*22,80))
		drone_hold.append(0.0)

func _process(delta: float) -> void:
	for cell in changed_clues.keys():
		changed_clues[cell]-=delta
		if changed_clues[cell]<=0:
			changed_clues.erase(cell)
	if blocked or (panning and not Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)):
		panning=false
	time += delta
	for i in animations.keys():
		animations[i] += delta * (1 if motion > 0 else 8)
		if animations[i] > 0.5:
			animations.erase(i)
	shake = maxf(0,shake-delta*18)
	reject_age=maxf(0,reject_age-delta)
	strike_age=maxf(0,strike_age-delta)
	if complete_wave >= 0:
		complete_wave += delta
		if complete_wave > 2:
			complete_wave = -1
	for i in range(drone_positions.size()):
		drone_hold[i]=maxf(0,drone_hold[i]-delta)
		if drone_hold[i]<=0:
			drone_targets[i]=Vector2(size.x-200-i*22,80)
		drone_positions[i] = drone_positions[i].lerp(drone_targets[i],minf(1,delta*8)) if motion>0 else drone_targets[i]
	queue_redraw()

func _draw() -> void:
	if session == null:
		return
	geometry()
	var b := session.board
	var accent := Color(Content.REGIONS[session.region()].color)
	# A floating field terminal: physical chrome, recessed glass and LED readouts.
	draw_rect(Rect2(Vector2(9,13),size-Vector2(12,16)),Color(0,0,0,0.35))
	Palette.bevel(self,Rect2(Vector2(0,0),size-Vector2(6,7)),Color("637084"),3)
	Palette.bevel(self,Rect2(Vector2(7,7),size-Vector2(20,21)),Color("2c3447"),2,false)
	var bar := Rect2(Vector2(8,8),Vector2(size.x-22,44))
	draw_rect(bar,Color("526e9b"))
	for x in range(int(bar.size.x)):
		draw_line(bar.position+Vector2(x,0),bar.position+Vector2(x,bar.size.y),Color("91b2db",float(x)/bar.size.x*0.18))
	Palette.icon(self,"prism",Vector2(28,30),19,Palette.GOLD)
	var caption := "FIELD_%03d" % (session.index+1) if session.trial<0 else "TRIAL_%02d / %s" % [session.trial+1,"SURVEY" if session.trial%2==0 else "FLEET"]
	if Content.strata_for(session.index,session.trial)>1:
		caption += "  ·  %02d/%02d" % [session.stratum+1,Content.strata_for(session.index,session.trial)]
	draw_string(font,Vector2(48,36),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Palette.WHITE)
	var grid_rect := Rect2(grid_origin-Vector2(4,4),Vector2(visible_columns,visible_rows)*tile_size+Vector2(8,8))
	Palette.bevel(self,grid_rect,Color("171e2d"),3,false)
	Palette.bevel(self,Rect2(Vector2(24,size.y-56),Vector2(88,32)),Color("17202a"),2,false)
	Palette.digits(self,"%03d" % b.open_count(),Vector2(34,size.y-50),1.02,accent)
	draw_string(font,Vector2(124,size.y-34),"/ %03d" % (b.width*b.height-b.mine_count),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Palette.MUTED)
	var selected := keyboard_cell if keyboard_cell >= 0 else hover
	var neighbours: Array[int] = []
	var targets: Array[int] = []
	var target_color := Palette.MINT
	if selected >= 0:
		if session.has("lens") and b.cells[selected] == MineBoard.OPEN:
			neighbours = b.neighbours(selected)
		if active_tool != "":
			if active_tool=="probe":
				targets.assign([selected])
			else:
				targets = session.tool_cells(active_tool,selected)
			if session.energy<session.effective_tool_cost(active_tool,selected):
				target_color=Palette.CORAL
	var offset := Vector2(sin(time*83),cos(time*71))*shake*motion
	for i in range(b.cells.size()):
		if not visible_cell(i):
			continue
		var p := cell_position(i)-Vector2.ONE*tile_size/2+offset
		var rect := Rect2(p+Vector2(2,2),Vector2.ONE*(tile_size-4))
		var cell: int = b.cells[i]
		var age: float = animations.get(i,1.0)
		var opening := age < 0.5 and cell == MineBoard.OPEN
		var visible_open := cell == MineBoard.OPEN and age >= 0
		if opening and age >= 0:
			var bounce := sin(minf(1,age/0.5)*PI)*3.5*motion
			rect.position.y -= bounce
		if not visible_open and age>=0 and age<0.35:
			rect.position.y += sin(age/0.35*PI)*3*motion
		var hovered := i == selected and not blocked
		var fill := Color("8493a5")
		if hovered:
			fill = fill.lightened(0.12)
		if neighbours.has(i):
			fill = fill.lerp(Palette.MINT,0.48)
		if targets.has(i):
			fill=fill.lerp(target_color,0.48)
		if visible_open:
			fill = Color("283246") if not high_contrast else Color("101626")
			if opening:
				fill = fill.lerp(accent.darkened(0.5),maxf(0,1-age*3))
			draw_rect(rect,fill)
			draw_line(rect.position,rect.position+Vector2(rect.size.x,0),Color("172130"),1)
		elif cell==MineBoard.HIT:
			Palette.bevel(self,rect,Palette.CORAL.darkened(0.52),2,false)
		else:
			var depressed := Vector2(0,2) if hovered else Vector2.ZERO
			draw_texture_rect(tile_texture(fill),Rect2(rect.position+depressed,rect.size+Vector2(0,3)),false)
		if not visible_open and cell == MineBoard.HIDDEN:
			if b.plates[i]>0:
				Palette.plating(self,rect.get_center(),tile_size,b.plates[i],Color("42556f"))
			if session.has("compass") and b.pockets[i]==1:
				Palette.crystal(self,rect.position+Vector2(rect.size.x-6,6),maxf(8,tile_size*0.25))
			if not b.generated and i == (b.height/2)*b.width+b.width/2:
				Palette.star(self,rect.get_center(),tile_size*0.14,Color("fff0b8"))
		elif visible_open:
			var clue: int = b.clues[i]
			if clue > 0:
				var text := str(clue)
				var font_size := int(tile_size*0.6)
				var text_size := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
				draw_string(font,rect.get_center()+Vector2(-text_size.x/2,font_size*0.36),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color.WHITE if high_contrast else Palette.CLUES[clue])
			elif b.pockets[i] == 0:
				draw_circle(rect.get_center(),1,Color("345052"))
			if b.pockets[i] == 1:
				Palette.crystal(self,rect.position+Vector2(rect.size.x-7,7),maxf(8,tile_size*0.25))
		elif cell == MineBoard.FLAG:
			var pop := 1.0 + (sin(age*PI/0.18)*0.25*(1-age*2)*motion if age >= 0 and age < 0.5 else 0.0)
			Palette.icon(self,"flag",rect.get_center(),tile_size*0.4*pop,Palette.FLAG)
		elif cell == MineBoard.HIT:
			Palette.icon(self,"nova",rect.get_center(),tile_size*0.38,Palette.CORAL)
		if (session.failed or session.finished or session.layer_ready) and b.mines[i] == 1 and cell == MineBoard.HIDDEN:
			Palette.icon(self,"mine",rect.get_center(),tile_size*0.32,Palette.INK)
		if session.drift.enabled:
			if changed_clues.has(i):
				draw_rect(rect,Color(Palette.MINT,minf(0.7,changed_clues[i])),false,2)
			if session.drift.anchors[i]>0 and cell==MineBoard.HIDDEN:
				draw_line(rect.position+Vector2(4,8),rect.position+Vector2(4,4),Palette.INK,2)
				draw_line(rect.position+Vector2(4,4),rect.position+Vector2(8,4),Palette.INK,2)
			if session.drift.traces[i]>0 and cell==MineBoard.HIDDEN:
				var center := rect.get_center()
				draw_polyline(PackedVector2Array([center+Vector2(0,-5),center+Vector2(5,0),center+Vector2(0,5),center+Vector2(-5,0),center+Vector2(0,-5)]),Palette.INK,2,true)
		if i==selected and not blocked:
			draw_rect(rect.grow(1),Palette.WHITE if keyboard_cell>=0 else Color(Palette.WHITE,0.65),false,2 if keyboard_cell>=0 else 1)
		if i==rejected_cell and reject_age>0:
			draw_rect(rect.grow(1),Color(Palette.CORAL,minf(1,reject_age*2)),false,2)
	draw_shelter()
	draw_readout(selected)
	if zoom>1:
		var map := minimap_rect()
		draw_rect(map,Palette.INK)
		for i in range(b.cells.size()):
			if b.cells[i] in [MineBoard.OPEN,MineBoard.FLAG]:
				var at := map.position+Vector2(float(i%b.width)/b.width,float(i/b.width)/b.height)*map.size
				draw_rect(Rect2(at,map.size/Vector2(b.width,b.height)),Palette.EDGE if b.cells[i]==MineBoard.OPEN else Palette.GOLD)
		var viewport_rect := Rect2(map.position+Vector2(view_offset)/Vector2(b.width,b.height)*map.size,Vector2(visible_columns,visible_rows)/Vector2(b.width,b.height)*map.size)
		draw_rect(viewport_rect,Palette.MINT,false,1.5)
	if complete_wave >= 0 and motion > 0:
		var radius := complete_wave*size.x*0.7
		draw_arc(size/2,radius,0,TAU,100,Color(accent,maxf(0,0.55-complete_wave*0.3)),3,true)
	if session.has("drone"):
		ensure_drones(session.drone_count())
		for i in range(session.drone_count()):
			var p := drone_positions[i]
			p.y += sin(time*2.5+i)*3*motion
			draw_circle(p+Vector2(0,4),7,Color(0,0,0,0.2))
			draw_circle(p,7,Palette.INK)
			Palette.icon(self,"drone",p,12,Palette.GOLD if session.livery == 1 else (Palette.CORAL if session.livery == 2 else Palette.MINT))

func draw_readout(selected: int) -> void:
	if selected<0 or blocked:
		return
	var b := session.board
	var center := Vector2(size.x/2,size.y-40)
	if b.cells[selected]==MineBoard.OPEN and b.clues[selected]>0:
		var flags := 0
		for n in b.neighbours(selected):
			flags+=1 if b.cells[n] in [MineBoard.FLAG,MineBoard.HIT] else 0
		Palette.icon(self,"mine",center+Vector2(-68,0),19,Palette.MUTED)
		draw_string(font,center+Vector2(-51,7),str(b.clues[selected]),HORIZONTAL_ALIGNMENT_LEFT,-1,20,Palette.WHITE)
		draw_line(center+Vector2(-20,-12),center+Vector2(-20,12),Palette.EDGE,1)
		Palette.icon(self,"flag",center+Vector2(1,0),18,Palette.MUTED)
		draw_string(font,center+Vector2(16,7),str(flags),HORIZONTAL_ALIGNMENT_LEFT,-1,20,Palette.MINT if flags==b.clues[selected] else Palette.WHITE)
		if flags==b.clues[selected] and session.can_chord():
			Palette.mouse(self,center+Vector2(61,0),1,Palette.MINT,0.85)
	elif b.cells[selected]==MineBoard.HIDDEN and b.plates[selected]>0:
		Palette.plating(self,center+Vector2(-80,0),30,b.plates[selected],Palette.MUTED)
		draw_string(font,center+Vector2(-54,6),"Plating · %d" % b.plates[selected],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Palette.WHITE)
	elif b.pockets[selected]>0 and (b.cells[selected]==MineBoard.OPEN or session.has("compass")):
		Palette.crystal(self,center+Vector2(-78,0),22)
		draw_string(font,center+Vector2(-54,6),"Crystal pocket",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Palette.GOLD)

# Procedural keycaps are baked once per colour; hundreds of tiles can then batch.
func tile_texture(color: Color) -> ImageTexture:
	var key := color.to_html()
	if tile_textures.has(key):
		return tile_textures[key]
	var image := Image.create(64,68,false,Image.FORMAT_RGBA8)
	image.fill(Color("182132"))
	for y in range(64):
		for x in range(64):
			var c := color
			if (y<3 and x<64-y) or (x<3 and y<64-x):
				c=color.lightened(0.35)
			elif x>=61 or y>=61:
				c=color.darkened(0.55)
			image.set_pixel(x,y,c)
	var texture := ImageTexture.create_from_image(image)
	tile_textures[key]=texture
	return texture


func draw_shelter() -> void:
	if not session.drift.enabled or not session.board.generated or session.finished or session.failed:
		return
	var d := session.drift
	var b := session.board
	var cells := d.area(b,d.focus,d.radius)
	if d.stasis>0 or d.converged:
		cells.assign(range(b.cells.size()))
	# Only the outline is inked. The actual cells remain quiet and readable.
	for i in cells:
		if not visible_cell(i):
			continue
		var p := cell_position(i)-Vector2.ONE*tile_size/2
		var rect := Rect2(p+Vector2.ONE,Vector2.ONE*(tile_size-2))
		for side in range(4):
			var neighbour: int = [i-b.width,i+1,i+b.width,i-1][side]
			var outer: bool = [i/b.width==0,i%b.width==b.width-1,i/b.width==b.height-1,i%b.width==0][side]
			if not outer and cells.has(neighbour) and visible_cell(neighbour):
				continue
			var points := [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]
			draw_line(points[side],points[(side+1)%4],Palette.MINT,2,true)
