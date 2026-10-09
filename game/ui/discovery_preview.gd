class_name DiscoveryPreview
extends Control

var item: Dictionary
var time: float = 0
var motion: float = 1
var demo: UpgradeDemo
var font: Font = ThemeDB.fallback_font

func _ready() -> void:
	mouse_filter=MOUSE_FILTER_IGNORE
	if not item.is_empty():
		demo=UpgradeDemo.new(item.id)

func _process(delta: float) -> void:
	time+=delta if motion>0 else 0
	queue_redraw()

func _draw() -> void:
	if demo==null:
		return
	var phase := fmod(time,5.4)
	var progress := clampf((phase-1.1)/2.2,0,1) if motion>0 else 1.0
	var stage := mini(demo.frames.size()-1,int(ceilf(progress*(demo.frames.size()-1))))
	var frame: Dictionary=demo.frames[stage]
	var initial: Dictionary=demo.frames[0]
	var board: Dictionary=frame.board
	var unit := floorf(minf(180.0/board.width,175.0/board.height))
	var extent := Vector2(board.width,board.height)*unit
	var origin := Vector2(12,10)+(Vector2(180,175)-extent)/2
	var changed: Array[int]=[]
	if initial.board.cells.size()==board.cells.size():
		for i in range(board.cells.size()):
			if board.cells[i]!=initial.board.cells[i] or board.plates[i]!=initial.board.plates[i]:
				changed.append(i)
	var focus_color := Palette.MINT
	for i in range(board.cells.size()):
		var rect := Rect2(origin+Vector2(i%int(board.width),i/int(board.width))*unit,Vector2.ONE*(unit-2))
		var state: int=board.cells[i]
		var plates: int=board.plates[i]
		# Reveals stagger only within the recorded outcome. Mine locations and
		# clue numbers always come from the actual board behind that outcome.
		var order := changed.find(i)
		if demo.frames.size()==2 and order>=0 and progress<float(order+1)/maxi(1,changed.size()):
			state=initial.board.cells[i]
			plates=initial.board.plates[i]
		if state==MineBoard.OPEN:
			draw_rect(rect,Palette.GLASS)
			if board.clues[i]>0:
				var clue := str(int(board.clues[i]))
				var fs := int(unit*0.62)
				var tw := font.get_string_size(clue,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
				draw_string(font,rect.get_center()+Vector2(-tw/2,fs*0.36),clue,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,Palette.CLUES[board.clues[i]])
		elif state==MineBoard.HIT:
			Palette.bevel(self,rect,Palette.CORAL.darkened(0.5),1,false)
			Palette.icon(self,"mine",rect.get_center(),unit*0.53,Palette.CORAL)
		else:
			Palette.bevel(self,rect,Palette.TILE,1.5)
			if state==MineBoard.FLAG:
				Palette.icon(self,"flag",rect.get_center(),unit*0.58,Palette.FLAG)
			elif plates>0:
				Palette.plating(self,rect.get_center(),unit,plates,Color("42556f"))
		if board.pockets[i]>0 and (state==MineBoard.OPEN or (demo.id=="compass" and progress>0)):
			Palette.icon(self,"prism",rect.position+Vector2(rect.size.x-4,4),5,Palette.GOLD)
		if demo.marks.has(i) and progress>0:
			draw_rect(rect,Color(focus_color,0.6),false,1)
		if order>=0 and progress>0 and progress<0.9:
			draw_rect(rect,Color(focus_color,0.45),false,1)
	var center := Vector2(247,44)
	UpgradeIcons.draw(self,demo.id,center,31,Palette.MINT)
	if demo.action=="mouse":
		Palette.mouse(self,Vector2(247,91),1,Palette.MUTED,0.85)
	elif demo.action=="drone":
		for worker in range(demo.workers):
			var p := Vector2(217+(worker%4)*20,82+(worker/4)*19)
			Palette.icon(self,"drone",p,14,Palette.MUTED)
	else:
		Palette.icon(self,"pulse" if demo.action=="pulse" else ("lens" if demo.action=="lens" else "energy"),Vector2(247,91),20,Palette.MUTED)
	if demo.target<board.cells.size() and demo.action in ["mouse","pulse"] and progress>0 and progress<0.8:
		var p := origin+Vector2(demo.target%int(board.width)+0.5,demo.target/int(board.width)+0.5)*unit
		draw_arc(p,unit*0.56,0,TAU,24,Color(Palette.WHITE,0.8),1.5,true)
	if demo.action=="beam" and progress>0 and progress<0.9:
		var source := origin+Vector2(demo.target%int(board.width)+0.5,demo.target/int(board.width)+0.5)*unit
		for cell in demo.marks:
			var p := origin+Vector2(cell%int(board.width)+0.5,cell/int(board.width)+0.5)*unit
			draw_line(source,p,Color(Palette.MINT,0.25),2,true)
	if not demo.metric.is_empty():
		var metric_icon := demo.metric_icon()
		if metric_icon.begins_with("upgrade:"):
			UpgradeIcons.draw(self,metric_icon.trim_prefix("upgrade:"),Vector2(219,137),18,Palette.GOLD)
		else:
			Palette.icon(self,metric_icon,Vector2(219,137),18,Palette.GOLD)
		var value: float=frame[demo.metric]
		var old: float=initial[demo.metric]
		var display := number(old)+" → "+number(value)
		draw_string(font,Vector2(210,164),display,HORIZONTAL_ALIGNMENT_LEFT,88,15,Palette.WHITE)
	if demo.id=="overdrive":
		draw_string(font,Vector2(207,187),demo.note,HORIZONTAL_ALIGNMENT_LEFT,90,12,Palette.MUTED)
	for step in range(3):
		draw_circle(Vector2(132+step*11,195),2,Palette.MINT if step==mini(2,int(progress*3)) else Palette.EDGE)

func number(value: float) -> String:
	return str(int(value)) if is_equal_approx(value,roundf(value)) else "%.1f" % value
