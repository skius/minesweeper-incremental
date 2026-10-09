class_name Glyph
extends Control

var kind: String = "prism"
var color: Color = Palette.MINT
var icon_size: float = 22
var recharge: float = -1

func _draw() -> void:
	if kind.begins_with("upgrade:"):
		UpgradeIcons.draw(self,kind.trim_prefix("upgrade:"),size/2,icon_size,color)
	else:
		Palette.icon(self, kind, size/2, icon_size, color)
	if recharge>=0 and recharge<1:
		draw_arc(size/2,icon_size*0.6,-PI/2,TAU-PI/2,40,Palette.EDGE,2,true)
		if recharge>0:
			draw_arc(size/2,icon_size*0.6,-PI/2,TAU*recharge-PI/2,40,Palette.MINT,2,true)
