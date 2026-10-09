class_name Glyph
extends Control

var kind: String = "prism"
var color: Color = Palette.MINT
var icon_size: float = 22
var recharge: float = -1
var mounted: bool = false
var armed: bool = false
var motion: float = 1
var hover_amount: float = 0
var time: float = 0
var pulse: float = 0

func _process(delta: float) -> void:
	if not mounted:
		return
	var parent := get_parent() as Button
	var hovered := parent!=null and parent.is_hovered() and not parent.disabled
	hover_amount=move_toward(hover_amount,1.0 if hovered else 0.0,delta*8) if motion>0 else 0.0
	time+=delta*motion
	pulse=maxf(0,pulse-delta*3)
	queue_redraw()

func symbol(at: Vector2, ink: Color) -> void:
	if kind.begins_with("upgrade:"):
		UpgradeIcons.draw(self,kind.trim_prefix("upgrade:"),at,icon_size,ink)
	else:
		Palette.icon(self,kind,at,icon_size,ink)

func _draw() -> void:
	var at := size/2
	var ink := color
	if mounted:
		var parent := get_parent() as Button
		var disabled := parent!=null and parent.disabled
		ink=(Palette.EDGE if disabled else color).lerp(Palette.WHITE,pulse*0.45)
		var r := icon_size*0.62
		draw_circle(at+Vector2(0,2),r+2,Palette.INK)
		draw_circle(at,r,Palette.GLASS)
		draw_arc(at,r,PI,TAU,24,Palette.EDGE,1.4,true)
		draw_arc(at,r,0,PI,24,Palette.INK,2,true)
		if armed or hover_amount>0:
			draw_circle(at,r-2,Color(ink,0.08+0.08*hover_amount))
			if armed:
				draw_arc(at,r+2,-PI/2,TAU-PI/2,48,Color(ink,0.65),2,true)
				if motion>0:
					draw_arc(at,r+2,time*2,time*2+0.65,12,Palette.WHITE,2,true)
		if pulse>0:
			draw_arc(at,r+2+(1-pulse)*3*motion,0,TAU,48,Color(ink,pulse*0.8),2,true)
		at.y-=hover_amount*2
		if parent!=null and parent.is_pressed():
			at.y+=2
		# A cast edge gives the symbol body; movement stays inside its own well.
		symbol(at+Vector2(0,2),Palette.INK)
		symbol(at+Vector2(0,-0.7),ink.lightened(0.45))
	symbol(at,ink)
	if recharge>=0 and recharge<1:
		var r := icon_size*0.66
		draw_arc(size/2,r,-PI/2,TAU-PI/2,40,Palette.EDGE,2,true)
		if recharge>0:
			draw_arc(size/2,r,-PI/2,TAU*recharge-PI/2,40,Palette.MINT,2,true)
