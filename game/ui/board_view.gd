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

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	mouse_default_cursor_shape = CURSOR_POINTING_HAND
	clip_contents = true

func geometry() -> void:
	if session == null:
		return
	tile_size = floorf(minf((size.x-64)/session.board.width,(size.y-50)/session.board.height))
	tile_size = minf(tile_size,61)
	grid_origin = (size-Vector2(session.board.width,session.board.height)*tile_size)/2

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
		drone_positions.append(Vector2(24+drone_positions.size()*28,25))
		drone_targets.append(Vector2(24+drone_targets.size()*28,25))

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
	draw_style_box(Palette.box(Palette.PANEL.darkened(0.12),16,Palette.EDGE),Rect2(Vector2.ZERO,size))
	# Technical registration marks and coordinates frame the tactile tiles.
	for side in [Vector2(14,14),Vector2(size.x-14,14),Vector2(14,size.y-14),size-Vector2(14,14)]:
		draw_line(side-Vector2(4,0),side+Vector2(4,0),Palette.MUTED.darkened(0.6),1)
		draw_line(side-Vector2(0,4),side+Vector2(0,4),Palette.MUTED.darkened(0.6),1)
	var selected := keyboard_cell if keyboard_cell >= 0 else hover
	var neighbours: Array[int] = []
	var targets: Array[int] = []
	if selected >= 0:
		if session.has("lens") and b.cells[selected] == MineBoard.OPEN:
			neighbours = b.neighbours(selected)
		if active_tool != "":
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
		var hovered := i == selected and not blocked
		var fill := Color("1c3a44")
		var border := Color("30515a")
		if visible_open:
			fill = Color("10242c") if not high_contrast else Color("08171d")
			border = Color("1c353d")
			if opening:
				fill = fill.lerp(accent.darkened(0.6),maxf(0,1-age*3))
		elif cell == MineBoard.HIT:
			fill = Color("4b3032")
			border = Palette.CORAL.darkened(0.3)
		elif cell == MineBoard.FLAG:
			fill = Color("234743")
			border = accent.darkened(0.55)
		if hovered or neighbours.has(i) or targets.has(i):
			fill = fill.lightened(0.07 if not hovered else 0.13)
			border = accent if hovered or targets.has(i) else accent.darkened(0.45)
		if not visible_open and cell != MineBoard.HIT:
			draw_style_box(Palette.box(Color("07151c"),6),Rect2(rect.position+Vector2(0,3),rect.size))
		draw_style_box(Palette.box(fill,6,border,1),rect)
		if not visible_open and cell == MineBoard.HIDDEN:
			draw_line(rect.position+Vector2(7,1),rect.position+Vector2(rect.size.x-7,1),Color("42616a"),1,true)
			var dot_color := Color("49626a")
			draw_circle(rect.get_center(),1.2,dot_color)
		elif visible_open:
			var clue: int = b.clues[i]
			if clue > 0:
				var text := str(clue)
				var font_size := int(tile_size*0.46)
				var text_size := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
				draw_string(font,rect.get_center()+Vector2(-text_size.x/2,font_size*0.36),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color.WHITE if high_contrast else Palette.CLUES[clue])
			elif b.pockets[i] == 0:
				draw_circle(rect.get_center(),1,Color("345052"))
			if b.pockets[i] == 1:
				Palette.star(self,rect.position+Vector2(rect.size.x-8,8),4,accent)
		elif cell == MineBoard.FLAG:
			Palette.icon(self,"flag",rect.get_center(),tile_size*0.35,accent)
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
