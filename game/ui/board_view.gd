class_name BoardView
extends Control

signal cell_pressed(index: int, right: bool)
signal cell_hovered(index: int)

var session: GameSession
var hover: int = -1
var keyboard_cell: int = -1
var active_tool: String = ""
var blocked: bool = false
var high_contrast: bool = false
var motion: float = 1
var animations: Dictionary = {}
var tile_size: float = 48
var grid_origin: Vector2
var time: float = 0
var shake: float = 0
var complete_wave: float = -1
var drone_positions: Array[Vector2] = []
var drone_targets: Array[Vector2] = []
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

func geometry() -> void:
	if session == null:
		return
	tile_size = floorf(minf((size.x-64)/session.board.width,(size.y-126)/session.board.height))
	tile_size = minf(tile_size,70)
	grid_origin = (size-Vector2(session.board.width,session.board.height)*tile_size)/2 + Vector2(0,4)

func cell_position(i: int) -> Vector2:
	geometry()
	return grid_origin + Vector2(i % session.board.width + 0.5,i / session.board.width + 0.5)*tile_size

func index_at(p: Vector2) -> int:
	geometry()
	var local := p-grid_origin
	if local.x < 0 or local.y < 0:
		return -1
	var x := int(local.x/tile_size)
	var y := int(local.y/tile_size)
	return y*session.board.width+x if x<session.board.width and y<session.board.height else -1

func _gui_input(event: InputEvent) -> void:
	if blocked or session == null:
		return
	if event is InputEventMouseMotion:
		var next := index_at(event.position)
		if next != hover:
			hover = next
			keyboard_cell = -1
			cell_hovered.emit(hover)
		queue_redraw()
	if event is InputEventMouseButton and event.pressed:
		var i := index_at(event.position)
		if i >= 0 and event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT,MOUSE_BUTTON_MIDDLE]:
			cell_pressed.emit(i,event.button_index == MOUSE_BUTTON_RIGHT)
			accept_event()

func animate_cells(cells: Array, source: String) -> void:
	for j in range(cells.size()):
		animations[cells[j]] = -minf(j*0.015,0.5)
	if source == "drone" and not cells.is_empty():
		var count := maxi(1,session.drone_count())
		ensure_drones(count)
		drone_targets[int(time*7)%count] = cell_position(cells[0])

func ensure_drones(count: int) -> void:
	while drone_positions.size() < count:
		drone_positions.append(Vector2(28+drone_positions.size()*28,58))
		drone_targets.append(Vector2(28+drone_targets.size()*28,58))

func _process(delta: float) -> void:
	time += delta
	for i in animations.keys():
		animations[i] += delta * (1 if motion > 0 else 8)
		if animations[i] > 0.5:
			animations.erase(i)
	shake = maxf(0,shake-delta*18)
	if complete_wave >= 0:
		complete_wave += delta
		if complete_wave > 2:
			complete_wave = -1
	for i in range(drone_positions.size()):
		drone_positions[i] = drone_positions[i].lerp(drone_targets[i],minf(1,delta*4))
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
	var bar := Rect2(Vector2(8,8),Vector2(size.x-22,34))
	draw_rect(bar,Color("526e9b"))
	for x in range(int(bar.size.x)):
		draw_line(bar.position+Vector2(x,0),bar.position+Vector2(x,bar.size.y),Color("91b2db",float(x)/bar.size.x*0.18))
	Palette.icon(self,"prism",Vector2(26,25),17,Palette.GOLD)
	var caption := "FIELD_%03d" % (session.index+1)
	if Content.strata_for(session.index,session.trial)>1:
		caption += "  /  STRATUM %02d" % (session.stratum+1)
	draw_string(font,Vector2(43,31),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Palette.WHITE)
	for x in range(int(size.x)-110,int(size.x)-31,5):
		draw_line(Vector2(x,18),Vector2(x,31),Color(0.75,0.84,0.97,0.18),2)
	var grid_rect := Rect2(grid_origin-Vector2(4,4),Vector2(b.width,b.height)*tile_size+Vector2(8,8))
	Palette.bevel(self,grid_rect,Color("171e2d"),3,false)
	Palette.bevel(self,Rect2(Vector2(20,size.y-50),Vector2(90,31)),Color("17202a"),2,false)
	Palette.digits(self,"%03d" % b.open_count(),Vector2(31,size.y-45),1.02,accent)
	draw_string(font,Vector2(125,size.y-28),"/ %03d" % (b.width*b.height-b.mine_count),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Palette.MUTED)
	var face := Vector2(size.x-42,size.y-35)
	draw_circle(face,10,Palette.GOLD)
	draw_circle(face+Vector2(-3,-2),1.4,Palette.INK)
	draw_circle(face+Vector2(3,-2),1.4,Palette.INK)
	draw_arc(face+Vector2(0,1),4,0,PI,10,Palette.INK,1.3,true)
	var selected := keyboard_cell if keyboard_cell >= 0 else hover
	var neighbours: Array[int] = []
	var targets: Array[int] = []
	if selected >= 0:
		if session.has("lens") and b.cells[selected] == MineBoard.OPEN:
			neighbours = b.neighbours(selected)
		if active_tool != "":
			if active_tool=="probe":
				targets.assign([selected])
			else:
				targets = session.tool_cells(active_tool,selected)
	var offset := Vector2(sin(time*83),cos(time*71))*shake*motion
	for i in range(b.cells.size()):
		var p := grid_origin + Vector2(i%b.width,i/b.width)*tile_size + offset
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
		if neighbours.has(i) or targets.has(i):
			fill = fill.lerp(accent,0.48)
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
				var stripe := Color("42556f")
				for j in range(mini(b.plates[i],3)):
					var offset_x := (j-(mini(b.plates[i],3)-1)*0.5)*4
					draw_line(rect.get_center()+Vector2(offset_x,-tile_size*0.21),rect.get_center()+Vector2(offset_x,tile_size*0.21),stripe,2)
				for sign_value in [-1,1]:
					draw_circle(rect.get_center()+Vector2(sign_value*tile_size*0.29,0),1.5,Color("d1d9df"))
			elif session.has("compass") and b.pockets[i]==1:
				Palette.icon(self,"prism",rect.get_center(),tile_size*0.35,Color("485d69"))
			if not b.generated and i == (b.height/2)*b.width+b.width/2:
				Palette.star(self,rect.get_center(),tile_size*0.14,Color("fff0b8"))
		elif visible_open:
			var clue: int = b.clues[i]
			if clue > 0:
				var text := str(clue)
				var font_size := int(tile_size*0.48)
				var text_size := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
				draw_string(font,rect.get_center()+Vector2(-text_size.x/2,font_size*0.36),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color.WHITE if high_contrast else Palette.CLUES[clue])
			elif b.pockets[i] == 0:
				draw_circle(rect.get_center(),1,Color("345052"))
			if b.pockets[i] == 1:
				Palette.star(self,rect.position+Vector2(rect.size.x-8,8),4,accent)
		elif cell == MineBoard.FLAG:
			var pop := 1.0 + (sin(age*PI/0.18)*0.25*(1-age*2)*motion if age >= 0 and age < 0.5 else 0.0)
			Palette.icon(self,"flag",rect.get_center(),tile_size*0.4*pop,Color("633c6b"))
		elif cell == MineBoard.HIT:
			Palette.icon(self,"nova",rect.get_center(),tile_size*0.38,Palette.CORAL)
		if session.finished and b.mines[i] == 1 and cell == MineBoard.HIDDEN:
			Palette.icon(self,"prism",rect.get_center(),tile_size*0.25,accent.darkened(0.25))
	if complete_wave >= 0 and motion > 0:
		var radius := complete_wave*size.x*0.7
		draw_arc(size/2,radius,0,TAU,100,Color(accent,maxf(0,0.55-complete_wave*0.3)),3,true)
	if session.has("drone"):
		ensure_drones(session.drone_count())
		for i in range(session.drone_count()):
			var p := drone_positions[i]
			p.y += sin(time*2.5+i)*3*motion
			draw_circle(p+Vector2(0,7),12,Color(0,0,0,0.2))
			draw_circle(p,13,Palette.INK)
			Palette.icon(self,"drone",p,16,Palette.GOLD if session.livery == 1 else (Palette.CORAL if session.livery == 2 else accent))

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
