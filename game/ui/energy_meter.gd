class_name EnergyMeter
extends Control

var available: float = 10
var capacity: float = 10
var cost: float = 0
var motion: float = 1
var shown: float = -1
var flash: float = 0
var font: Font = ThemeDB.fallback_font

func _ready() -> void:
	mouse_filter=MOUSE_FILTER_PASS
	tooltip_text="Tool energy · safe manual work and crystals refill it\nRecharges while you play · Pulse is free"

func _process(delta: float) -> void:
	if shown<0 or motion==0:
		shown=available
	else:
		shown=move_toward(shown,available,delta*30)
	flash=maxf(0,flash-delta*2)
	queue_redraw()

func _draw() -> void:
	var ink := Palette.CORAL if cost>available else Palette.GOLD
	draw_style_box(Palette.surface(Palette.INK,false),Rect2(Vector2.ZERO,size))
	Palette.icon(self,"energy",Vector2(18,size.y/2),17,ink)
	var bar := Rect2(37,9,size.x-132,size.y-18)
	draw_rect(bar,Palette.PANEL)
	var unit := bar.size.x/capacity
	for i in range(ceili(capacity)):
		var part := clampf(shown-i,0,1)
		if part<=0:
			continue
		var color := Palette.MINT
		if cost>0 and i>=available-cost:
			color=ink
		var rect := Rect2(bar.position+Vector2(i*unit,0),Vector2(maxf(1,unit-2)*part,bar.size.y))
		draw_rect(rect,color.lerp(Palette.WHITE,flash*0.4))
	var value := "%d / %d" % [floori(available),capacity]
	if cost>0:
		value="−%s" % (str(int(cost)) if is_equal_approx(cost,roundf(cost)) else "%.1f" % cost)
	draw_string(font,Vector2(size.x-83,size.y/2+6),value,HORIZONTAL_ALIGNMENT_LEFT,78,17,ink if cost>0 else Palette.WHITE)

