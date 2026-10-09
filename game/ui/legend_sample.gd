class_name LegendSample
extends Control

var kind: String = "clue"
var pulse_symbol: String = "pulse"
var covered_crystal: bool = false
var motion: float = 1
var time: float = 0

func _ready() -> void:
	mouse_filter=MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	time+=delta*motion
	queue_redraw()

func _draw() -> void:
	var center := size/2
	var tile := Rect2(center-Vector2.ONE*30,Vector2.ONE*60)
	if kind in ["clue","flag","crystal","plating","start"]:
		var opened := kind=="clue" or (kind=="crystal" and not covered_crystal)
		Palette.bevel(self,tile,Palette.GLASS if opened else Palette.TILE,3,not opened)
	match kind:
		"clue":
			draw_string(ThemeDB.fallback_font,center+Vector2(-11,13),"3",HORIZONTAL_ALIGNMENT_LEFT,-1,36,Palette.CLUES[3])
		"flag":
			Palette.icon(self,"flag",center,34,Palette.FLAG)
		"crystal":
			var gem := tile.position+Vector2(49,11)
			if not covered_crystal:
				draw_string(ThemeDB.fallback_font,center+Vector2(-11,13),"1",HORIZONTAL_ALIGNMENT_LEFT,-1,36,Palette.CLUES[1])
			Palette.crystal(self,gem,18)
			if motion>0:
				Palette.star(self,gem+Vector2(6,-6),1.5+sin(time*2)*0.8,Palette.WHITE)
		"plating":
			Palette.plating(self,center,60,3 if fmod(time,4)<2.5 else 2,Color("42556f"))
		"start":
			Palette.star(self,center,12,Palette.GOLD)
		"counter":
			Palette.bevel(self,Rect2(center-Vector2(38,21),Vector2(76,42)),Palette.GLASS,2,false)
			Palette.digits(self,"012",center-Vector2(30,12),0.95,Palette.MINT)
		"energy":
			Palette.icon(self,"energy",center+Vector2(0,-10),30,Palette.GOLD)
			for i in range(5):
				draw_rect(Rect2(center+Vector2(-26+i*11,19),Vector2(8,10)),Palette.MINT if i<3 else Palette.EDGE)
		"pulse":
			draw_circle(center,26,Palette.GLASS)
			if pulse_symbol.begins_with("upgrade:"):
				UpgradeIcons.draw(self,pulse_symbol.trim_prefix("upgrade:"),center,36,Palette.MINT)
			else:
				Palette.icon(self,pulse_symbol,center,36,Palette.MINT)
			draw_arc(center,29,-PI/2,-PI/2+TAU*(0.7 if motion==0 else fmod(time*0.2,1)),36,Palette.MINT,2,true)
		"drone":
			var p := center+Vector2(0,sin(time*2)*3)
			draw_circle(center+Vector2(0,13),15,Color(0,0,0,0.2))
			Palette.icon(self,"drone",p,40,Palette.MINT)
