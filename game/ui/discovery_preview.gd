class_name DiscoveryPreview
extends Control

var item: Dictionary
var time: float = 0
var motion: float = 1
var font: Font = ThemeDB.fallback_font

func _ready() -> void:
	mouse_filter=MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	time+=delta if motion>0 else 0
	queue_redraw()

func _draw() -> void:
	if item.is_empty():
		return
	var color := Palette.MINT if item.branch<0 else Color(Content.BRANCH_COLORS[item.branch])
	var phase := fmod(time,4.8)
	if motion==0:
		phase=2.8
	var origin := Vector2(40,13)
	var unit := 29.0
	var changed: Array[int]=[]
	var charge := 6
	match item.id:
		"cross","diagonal","perforator","seismic":
			changed.assign([17,15,16,18,19,3,10,24,31])
			if item.id=="diagonal":
				changed.append_array([1,5,9,11,23,25,29,33])
		"line","vertical":
			changed.assign([14,15,16,17,18,19,20])
			if item.id=="vertical":
				changed.append_array([3,10,24,31])
		"nova","aftershock":
			for y in range(5):
				for x in range(7):
					if item.id=="aftershock" or x in [1,2,3,4,5]:
						changed.append(y*7+x)
		"lens","focus","compass","cartogram":
			changed.assign([9,10,11,16,17,18,23,24,25])
		_:
			changed.assign([17,18,24,23,16,10,9,2,1,8,15,22,29,30,31])
	var progress := clampf((phase-0.9)/1.7,0,1)
	for i in range(35):
		var p := origin+Vector2(i%7,i/7)*unit
		var rect := Rect2(p,Vector2.ONE*(unit-3))
		var order := changed.find(i)
		var open := order>=0 and progress>float(order)/changed.size()
		if item.id=="lens":
			open=i==17
		if open:
			draw_rect(rect,Color("1b2934"))
			draw_string(font,p+Vector2(9,18),str((i*7/3)%3+1),HORIZONTAL_ALIGNMENT_LEFT,-1,14,color)
			if item.id in ["lens","focus","compass"]:
				draw_rect(rect,color,false,1.5)
		else:
			Palette.bevel(self,rect,Color("75859b"),2)
			if item.id in ["drill","fracture","excavator","perforator","legacy","crucible","kinetic"]:
				for j in range(3):
					draw_line(p+Vector2(9+j*4,6),p+Vector2(9+j*4,20),Color("3c536e"),1.5)
		if item.id=="lens" and order>=0 and phase>0.9:
			draw_rect(rect,color,false,1.5)
		if i==charge and item.id in ["flagger","harvester","salvage","sentry","shield"] and phase>1.2:
			Palette.icon(self,"flag",rect.get_center(),18,Color("633c6b"))
	if item.branch==1 or item.id in ["launchpad","autodescent"]:
		var count := 4 if item.id in ["swarm","fleet","overdrive"] else (2 if item.id in ["pair","synchrony"] else 1)
		for j in range(count):
			var p := origin+Vector2(90+sin(time*1.4+j)*70,60+cos(time*1.7+j)*40)
			draw_circle(p+Vector2(2,7),12,Color(0,0,0,0.25))
			draw_circle(p,11,Palette.INK)
			Palette.icon(self,"drone",p,18,color)
	elif item.branch==0 and phase>0.8 and phase<2.5:
		for cell in changed:
			var end := origin+Vector2(cell%7+0.5,cell/7+0.5)*unit
			draw_line(origin+Vector2(3.5,2.5)*unit,end,Color(color,0.17),5,true)
			draw_circle(origin+Vector2(3.5,2.5)*unit,8,color)
	if item.branch==2:
		for i in range(10):
			draw_rect(Rect2(40+i*20,177,15,6),color if i<progress*10 else Palette.EDGE)
	else:
		draw_line(Vector2(40,180),Vector2(235,180),Palette.EDGE,1)
		draw_circle(Vector2(40+progress*195,180),3,color)
