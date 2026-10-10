class_name FieldStatus
extends Control

var session: GameSession

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_PASS

func _get_tooltip(at_position: Vector2) -> String:
	if at_position.x<96:
		return "Hull: %d / 2\nStrike: lose half your cargo, energy and chain.\nTwo hull hits: attempt lost. Banked upgrades stay safe." % (2-session.damage)
	if at_position.x<218:
		if session.finished:
			return "Field cleared: %d light banked." % session.board_earned
		return "Field cargo: %d light\nBanked when you clear this field. At risk on a strike." % session.board_earned
	return "Clear reward: +%d research cores\nEvery field is one board." % reward_cores()

func reward_cores() -> int:
	return int(session.last_reward.cores) if session.finished else session.core_reward()

func _draw() -> void:
	if session==null:
		return
	var font := ThemeDB.fallback_font
	Palette.icon(self,"shield",Vector2(13,16),23,Palette.CORAL if session.damage else Palette.MINT)
	for i in range(2):
		var intact := i<2-session.damage
		Palette.bevel(self,Rect2(32+i*24,5,19,22),Palette.MINT if intact else Palette.GLASS,2,intact)
		if not intact:
			draw_line(Vector2(36+i*24,22),Vector2(47+i*24,10),Palette.CORAL,2,true)
	if session.has("shield") and session.strikes==0:
		draw_arc(Vector2(13,16),16,-PI*0.8,PI*0.8,24,Palette.GOLD,2,true)
	draw_line(Vector2(91,4),Vector2(91,28),Palette.EDGE)
	Palette.crystal(self,Vector2(111,16),21)
	var cargo := "%d" % (0 if session.finished else session.board_earned)
	if session.board_earned>=10000 and not session.finished:
		cargo="%.1fk" % (session.board_earned/1000.0)
	draw_string(font,Vector2(129,23),cargo,HORIZONTAL_ALIGNMENT_LEFT,78,18,Palette.GOLD)
	draw_line(Vector2(213,4),Vector2(213,28),Palette.EDGE)
	Palette.icon(self,"core",Vector2(232,16),21,Palette.MINT)
	draw_string(font,Vector2(251,23),"+%d" % reward_cores(),HORIZONTAL_ALIGNMENT_LEFT,48,18,Palette.MINT)
