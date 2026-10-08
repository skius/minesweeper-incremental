class_name InputCue
extends Control

# A small input/result diagram. Descriptions are available on demand, never
# spread across the playfield as a permanent sentence.
var mode: String = "reveal"
var motion: float = 1.0
var keyboard: bool = false
var time: float = 0.0

func _ready() -> void:
	mouse_filter=MOUSE_FILTER_PASS

func _process(delta: float) -> void:
	time+=delta*motion
	queue_redraw()

func _draw() -> void:
	var center := size/2
	var color := Palette.MUTED
	if mode=="tree":
		Palette.mouse(self,center+Vector2(-104,0),1,color)
		Palette.icon(self,"arrow",center+Vector2(-72,0),12,color)
		Palette.icon(self,"tree",center+Vector2(-45,0),23,color)
		Palette.mouse(self,center+Vector2(5,0),3,color)
		draw_circle(center+Vector2(39,-2),7,color,false,1.5,true)
		draw_line(center+Vector2(43,4),center+Vector2(49,10),color,1.5,true)
		Palette.keycap(self,"↵",Rect2(center+Vector2(77,-14),Vector2(30,28)),color)
		return
	var flag := mode=="flag"
	var aiming := mode=="aim"
	if keyboard:
		Palette.keycap(self,"F" if flag else "↵",Rect2(center+Vector2(-63,-15),Vector2(32,30)),color)
	else:
		Palette.mouse(self,center+Vector2(-47,0),2 if flag else 1,color)
	Palette.icon(self,"arrow",center+Vector2(-17,0),12,color)
	var tile := Rect2(center+Vector2(2,-15),Vector2(30,30))
	Palette.bevel(self,tile,Palette.TILE if flag else Palette.GLASS,2,flag)
	if flag:
		Palette.icon(self,"flag",tile.get_center(),18,Palette.FLAG)
	elif aiming:
		Palette.icon(self,"pulse",tile.get_center(),20,Palette.MINT)
	else:
		draw_string(ThemeDB.fallback_font,tile.position+Vector2(10,22),"1",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Palette.CLUES[1])
	if aiming:
		Palette.keycap(self,"Esc",Rect2(center+Vector2(50,-15),Vector2(37,30)),color)
