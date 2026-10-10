class_name UpgradeIcons
extends RefCounted

# A shared 24-unit drawing grid. Related mechanics share their silhouette;
# changes in shape, count, direction or material identify the individual node.
# Colour is deliberately not used to distinguish discoveries.
static func draw(c: CanvasItem, id: String, p: Vector2, size: float, color: Color) -> void:
	var s := size/24.0
	match id:
		"lens":
			circle(c,p,Vector2(-2,-2),7,s,color)
			line(c,p,[[3,3],[10,10]],s,color,2.5)
			line(c,p,[[-5,-2],[1,-2]],s,color)
			line(c,p,[[-2,-5],[-2,1]],s,color)
		"probe2", "pulse2_focus", "pulse3", "pulse3_focus":
			var positions: Array=[-7,0,7] if id.begins_with("pulse3") else [-5,5]
			for x in positions:
				circle(c,p,Vector2(x,0),3.4 if positions.size()==3 else 5,s,color)
				circle(c,p,Vector2(x,0),1.5,s,color,true)
			if id.ends_with("focus"):
				for side in [-1,1]:
					line(c,p,[[side*7,-9],[side*11,-9],[side*11,-5]],s,color)
					line(c,p,[[side*7,9],[side*11,9],[side*11,5]],s,color)
		"focus":
			for x in [-1,1]:
				for y in [-1,1]:
					line(c,p,[[x*5,y*10],[x*10,y*10],[x*10,y*5]],s,color)
			circle(c,p,Vector2.ZERO,4,s,color)
			circle(c,p,Vector2.ZERO,1.3,s,color,true)
		"reservoir":
			for x in [-6,6]:
				line(c,p,[[x-4,-8],[x+4,-8],[x+4,9],[x-4,9],[x-4,-8]],s,color)
				circle(c,p,Vector2(x,3),2,s,color,true)
				line(c,p,[[x-2,-11],[x+2,-11]],s,color)
		"cross", "diagonal":
			var rays := 8 if id=="diagonal" else 4
			for i in range(rays):
				var d := Vector2.from_angle(i*TAU/rays)
				c.draw_line(p+d*4*s,p+d*10*s,color,maxf(1.2,1.8*s),true)
			circle(c,p,Vector2.ZERO,1.7,s,color,true)
		"line", "vertical":
			line(c,p,[[-11,0],[11,0]],s,color,2)
			for x in [-10,10]:
				line(c,p,[[x,-4],[x,4]],s,color)
			if id=="vertical":
				line(c,p,[[0,-11],[0,11]],s,color,2)
				for y in [-10,10]:
					line(c,p,[[-4,y],[4,y]],s,color)
		"perforator":
			line(c,p,[[-11,0],[10,0]],s,color,2.5)
			for x in [-3,2,7]:
				line(c,p,[[x,-10],[x,-4]],s,color)
				line(c,p,[[x,4],[x,10]],s,color)
		"nova", "aftershock":
			var extent := 7 if id=="nova" else 11
			box(c,p,Rect2(-extent,-extent,extent*2,extent*2),s,color)
			if id=="aftershock":
				box(c,p,Rect2(-7,-7,14,14),s,color)
			for d in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
				c.draw_line(p+d*2*s,p+d*5*s,color,maxf(1.2,1.7*s),true)
		"drone":
			drone(c,p,s,color)
		"pair":
			if size<24:
				unit(c,p+Vector2(-5,-5)*s,s*0.8,color)
				unit(c,p+Vector2(5,5)*s,s*0.8,color)
			else:
				drone(c,p+Vector2(-4,-5)*s,s*0.62,color)
				drone(c,p+Vector2(4,6)*s,s*0.62,color)
		"fleet", "swarm":
			if id=="fleet":
				for x in [-6,6]:
					for y in [-6,6]:
						unit(c,p+Vector2(x,y)*s,s*0.56,color)
			else:
				for i in range(8):
					var point := p+Vector2.from_angle(i*TAU/8)*9*s
					c.draw_rect(Rect2(point-Vector2.ONE*1.5*s,Vector2.ONE*3*s),color)
				circle(c,p,Vector2.ZERO,3,s,color)
		"flagger":
			drone(c,p+Vector2(0,5)*s,s*0.78,color)
			line(c,p,[[0,-1],[0,-11],[7,-8],[0,-5]],s,color)
		"logic":
			unit(c,p+Vector2(0,8)*s,s*0.62,color)
			box(c,p,Rect2(-9,-11,11,10),s,color)
			box(c,p,Rect2(-2,-7,11,10),s,color)
		"oracle":
			drone(c,p+Vector2(0,7)*s,s*0.67,color)
			line(c,p,[[-9,-5],[-4,-9],[4,-9],[9,-5],[4,-1],[-4,-1],[-9,-5]],s,color)
			circle(c,p,Vector2(0,-5),2,s,color,true)
		"excavator":
			drone(c,p+Vector2(0,-4)*s,s*0.9,color)
			line(c,p,[[-5,3],[5,3],[0,11],[-5,3]],s,color)
			line(c,p,[[-3,6],[3,6]],s,color)
		"synchrony":
			unit(c,p+Vector2(6,4)*s,s*0.7,color)
			box(c,p,Rect2(-10,-8,7,7),s,color)
			line(c,p,[[1,-5],[8,-5],[5,-8]],s,color)
			line(c,p,[[-1,5],[-8,5],[-5,8]],s,color)
		"overdrive":
			bolt(c,p,s,color)
			for side in [-1,1]:
				line(c,p,[[side*6,-5],[side*11,-5],[side*9,0]],s,color)
		"battery":
			cell(c,p,s,color,2)
		"supercap":
			cell(c,p+Vector2(3,0)*s,s*0.9,color,4)
			line(c,p,[[-7,-7],[-10,-7],[-10,10],[3,10]],s,color)
		"capacitor":
			loop(c,p,s,color)
			line(c,p,[[-3,-5],[-3,5]],s,color,2)
			line(c,p,[[3,-5],[3,5]],s,color,2)
		"flywheel":
			loop(c,p,s,color)
			for a in range(4):
				var d := Vector2.from_angle(a*TAU/4)
				c.draw_line(p+d*2*s,p+d*6*s,color,maxf(1.2,1.5*s),true)
		"kinetic":
			line(c,p,[[-10,-9],[-3,-2],[-7,2],[-11,-5]],s,color)
			bolt(c,p+Vector2(5,3)*s,s*0.7,color)
		"resonance":
			loop(c,p,s,color)
			line(c,p,[[-5,2],[-2,-3],[1,3],[5,-2]],s,color)
		"recycler":
			loop(c,p,s,color)
			box(c,p,Rect2(-5,-5,10,10),s,color)
		"chain":
			for x in [-7,0,7]:
				circle(c,p,Vector2(x,0),4,s,color)
		"drill":
			line(c,p,[[-5,-10],[5,-10],[5,1],[0,11],[-5,1],[-5,-10]],s,color)
			for y in [-6,-1,4]:
				line(c,p,[[-4,y+2],[4,y-2]],s,color)
		"fracture":
			line(c,p,[[-3,-10],[-10,-10],[-10,10],[-2,10]],s,color)
			line(c,p,[[3,-10],[10,-10],[10,10],[3,10]],s,color)
			line(c,p,[[1,-10],[-2,-3],[3,1],[-1,10]],s,color,2)
		"seismic":
			line(c,p,[[-11,4],[-6,4],[-3,-7],[1,8],[5,-3],[7,4],[11,4]],s,color,1.8)
			for x in [-8,0,8]:
				line(c,p,[[x,-10],[x,-8]],s,color)
		"chord":
			for point in [Vector2(-7,-7),Vector2.ZERO,Vector2(7,7)]:
				box(c,p,Rect2(point-Vector2.ONE*3,Vector2.ONE*6),s,color)
			line(c,p,[[-4,-7],[7,-7],[7,4]],s,color)
			line(c,p,[[-7,-4],[-7,7],[4,7]],s,color)
		"conductor":
			for x in [-8,0,8]:
				box(c,p,Rect2(x-3,3,6,6),s,color)
			line(c,p,[[-9,-5],[9,-9]],s,color,2.5)
			line(c,p,[[0,-6],[0,0]],s,color)
		"prism":
			line(c,p,[[-6,-8],[-6,8],[5,0],[-6,-8]],s,color)
			for y in [-8,0,8]:
				line(c,p,[[5,0],[11,y]],s,color)
		"compass":
			circle(c,p,Vector2.ZERO,10,s,color)
			line(c,p,[[0,-7],[4,0],[0,7],[-4,0],[0,-7]],s,color)
			line(c,p,[[0,-7],[0,7]],s,color)
		"cartogram":
			line(c,p,[[-10,-8],[-3,-11],[4,-8],[10,-11],[10,8],[4,11],[-3,8],[-10,11],[-10,-8]],s,color)
			line(c,p,[[-3,-11],[-3,8]],s,color)
			line(c,p,[[4,-8],[4,11]],s,color)
			circle(c,p,Vector2(3,-1),3,s,color)
		"relay":
			line(c,p,[[0,-7],[0,6]],s,color)
			line(c,p,[[-9,8],[0,2],[9,8]],s,color)
			circle(c,p,Vector2(0,-7),3,s,color)
			for x in [-9,9]:
				box(c,p,Rect2(x-2,6,4,4),s,color)
		"launchpad":
			drone(c,p+Vector2(0,-5)*s,s*0.65,color)
			line(c,p,[[-10,4],[-10,10],[10,10],[10,4]],s,color)
			line(c,p,[[0,7],[0,1]],s,color)
		"autodescent":
			drone(c,p+Vector2(0,-7)*s,s*0.55,color)
			for x in [-9,0,9]:
				line(c,p,[[0,-2],[x,5]],s,color)
				circle(c,p,Vector2(x,9),2.5,s,color)
		"aurora":
			line(c,p,[[-11,9],[11,9]],s,color)
			c.draw_arc(p+Vector2(0,8)*s,7*s,PI,TAU,20,color,maxf(1.2,1.7*s),true)
			for i in range(5):
				var d := Vector2.from_angle(PI+i*PI/4)
				c.draw_line(p+Vector2(0,8)*s+d*10*s,p+Vector2(0,8)*s+d*15*s,color,maxf(1.2,1.5*s),true)
		"legacy":
			for y in [3,7,11]:
				line(c,p,[[-10,y],[10,y]],s,color)
			circle(c,p,Vector2(-4,-5),4,s,color)
			circle(c,p,Vector2(4,-5),4,s,color)
		"salvage":
			line(c,p,[[-7,10],[-7,-10],[1,-7],[-7,-3]],s,color)
			line(c,p,[[6,0],[11,5],[6,10],[1,5],[6,0]],s,color)
		"shield", "sentry":
			var offset := Vector2(-2,2) if id=="sentry" else Vector2.ZERO
			line(c,p+offset*s,[[-8,-7],[0,-10],[8,-7],[6,4],[0,10],[-6,4],[-8,-7]],s*(0.8 if id=="sentry" else 1),color)
			if id=="sentry":
				for d in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
					c.draw_line(p+Vector2(7,-7)*s+d*2*s,p+Vector2(7,-7)*s+d*5*s,color,maxf(1.2,1.6*s),true)
		"harvester":
			line(c,p,[[-11,7],[11,7]],s,color,2)
			for x in [-7,5]:
				line(c,p,[[x,5],[x,-9],[x+6,-6],[x,-3]],s,color)
		"echochamber":
			box(c,p,Rect2(-5,-5,10,10),s,color)
			for side in [-1,1]:
				line(c,p,[[side*8,-8],[side*11,-5],[side*11,5],[side*8,8]],s,color)
		"crucible":
			line(c,p,[[-10,-2],[-7,10],[7,10],[10,-2]],s,color,2)
			line(c,p,[[-4,-10],[0,-6],[-2,-2],[3,2],[5,-4]],s,color)
		"bounty":
			line(c,p,[[-10,-4],[-7,-9],[7,-9],[10,-4],[10,9],[-10,9],[-10,-4],[10,-4]],s,color)
			box(c,p,Rect2(-2,-2,4,5),s,color)
		"magnet":
			line(c,p,[[-9,-9],[-9,2],[-5,9],[5,9],[9,2],[9,-9],[4,-9],[4,1],[2,4],[-2,4],[-4,1],[-4,-9],[-9,-9]],s,color)
			for x in [-2,2]:
				circle(c,p,Vector2(x,-6),1,s,color,true)
		_:
			Palette.icon(c,id,p,size,color)

static func line(c: CanvasItem, p: Vector2, points: Array, s: float, color: Color, weight: float = 1.6) -> void:
	var path := PackedVector2Array()
	for point in points:
		path.append(p+Vector2(point[0],point[1])*s)
	c.draw_polyline(path,color,maxf(1.15,weight*s),true)

static func circle(c: CanvasItem, p: Vector2, offset: Vector2, radius: float, s: float, color: Color, filled: bool = false) -> void:
	if filled:
		c.draw_circle(p+offset*s,radius*s,color)
	else:
		c.draw_arc(p+offset*s,radius*s,0,TAU,24,color,maxf(1.15,1.6*s),true)

static func box(c: CanvasItem, p: Vector2, rect: Rect2, s: float, color: Color) -> void:
	c.draw_rect(Rect2(p+rect.position*s,rect.size*s),color,false,maxf(1.15,1.6*s))

static func drone(c: CanvasItem, p: Vector2, s: float, color: Color) -> void:
	line(c,p,[[0,-5],[4,0],[0,5],[-4,0],[0,-5]],s,color)
	for side in [-1,1]:
		circle(c,p,Vector2(side*8,0),3,s,color)
		line(c,p,[[side*4,0],[side*6,0]],s,color)

static func unit(c: CanvasItem, p: Vector2, s: float, color: Color) -> void:
	line(c,p,[[0,-5],[4,0],[0,5],[-4,0],[0,-5]],s,color)
	line(c,p,[[-7,0],[-4,0]],s,color)
	line(c,p,[[4,0],[7,0]],s,color)

static func cell(c: CanvasItem, p: Vector2, s: float, color: Color, bars: int) -> void:
	box(c,p,Rect2(-7,-8,14,18),s,color)
	line(c,p,[[-3,-11],[3,-11]],s,color)
	for i in range(bars):
		line(c,p,[[-3,6-i*3],[3,6-i*3]],s,color,1.8)

static func loop(c: CanvasItem, p: Vector2, s: float, color: Color) -> void:
	c.draw_arc(p,10*s,-PI*0.3,PI*1.35,32,color,maxf(1.15,1.6*s),true)
	line(c,p,[[-8,-4],[-4,-9],[-10,-9]],s,color)

static func bolt(c: CanvasItem, p: Vector2, s: float, color: Color) -> void:
	line(c,p,[[2,-11],[-5,1],[0,1],[-2,11],[6,-2],[1,-2],[2,-11]],s,color,1.8)
