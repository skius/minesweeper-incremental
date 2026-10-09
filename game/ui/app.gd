extends Control

var session: GameSession
var store := SaveStore.new()
var settings: Dictionary
var scenery: Scenery
var audio: GameAudio
var effects: FieldEffects
var ui: Control
var modal: Control
var toast_layer: Control
var board_view: BoardView
var screen: String = "menu"
var modal_kind: String = ""
var modal_history: Array[String] = []
var modal_return_focus: Control
var selected_tool: String = ""
var shop_group: int = 0
var shop_buttons: Dictionary = {}
var hud: Dictionary = {}
var tool_buttons: Dictionary = {}
var autosave_clock: float = 0
var hud_clock: float = 0
var save_pending: bool = false
var save_delay: float = 0
var save_status: String = "All progress saved"
var toast_time: float = 0
var finish_delay: float = -1
var visual_test: bool = false
var font_bold: FontVariation
var report_image: Image
var upgrade_tree: UpgradeTree
var tree_detail: Control
var tree_selected: String = "lens"
var ui_stage: int = -1

func _ready() -> void:
	get_tree().auto_accept_quit = false
	visual_test = OS.get_cmdline_user_args().has("--visual-test") or OS.get_cmdline_user_args().has("--manual-test") or OS.get_cmdline_user_args().has("--release-test")
	settings = store.load_settings()
	font_bold = FontVariation.new()
	font_bold.base_font = ThemeDB.fallback_font
	font_bold.variation_embolden = 0.65
	make_theme()
	scenery = Scenery.new()
	scenery.size = Vector2(1440,900)
	add_child(scenery)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ui)
	effects = FieldEffects.new()
	effects.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(effects)
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(modal)
	toast_layer = Control.new()
	toast_layer.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(toast_layer)
	audio = GameAudio.new()
	add_child(audio)
	apply_settings()
	session = store.load_session()
	show_menu()
	resized.connect(layout_ui)
	layout_ui()
	if store.notice != "":
		toast(store.notice,7)
	if OS.get_cmdline_user_args().has("--release-test"):
		call_deferred("release_smoke")
	elif visual_test:
		var runner = load("res://tests/manual_session.gd" if OS.get_cmdline_user_args().has("--manual-test") else "res://tests/visual_session.gd").new()
		add_child(runner)
		runner.call_deferred("run",self)

func make_theme() -> void:
	theme = Theme.new()
	theme.default_font = ThemeDB.fallback_font
	theme.default_font_size = 16
	theme.set_color("font_color","Label",Palette.WHITE)
	theme.set_color("font_color","Button",Palette.WHITE)
	theme.set_color("font_hover_color","Button",Color.WHITE)
	theme.set_color("font_pressed_color","Button",Palette.INK)
	theme.set_color("font_disabled_color","Button",Palette.MUTED.darkened(0.35))
	theme.set_stylebox("normal","Button",Palette.surface(Palette.PANEL_LIGHT))
	theme.set_stylebox("hover","Button",Palette.surface(Palette.PANEL_LIGHT.lightened(0.12)))
	theme.set_stylebox("pressed","Button",Palette.surface(Palette.MINT,false))
	theme.set_stylebox("focus","Button",Palette.box(Color.TRANSPARENT,0,Palette.GOLD,1))
	theme.set_stylebox("disabled","Button",Palette.surface(Palette.PANEL,false))
	for state in ["normal","pressed","disabled","hover_pressed"]:
		theme.set_stylebox(state,"CheckBox",StyleBoxEmpty.new())
	theme.set_stylebox("hover","CheckBox",Palette.box(Palette.PANEL_LIGHT,0))
	theme.set_color("font_pressed_color","CheckBox",Palette.WHITE)
	theme.set_color("font_hover_pressed_color","CheckBox",Palette.WHITE)
	theme.set_icon("checked","CheckBox",Palette.control_texture("checked"))
	theme.set_icon("unchecked","CheckBox",Palette.control_texture("unchecked"))
	theme.set_constant("h_separation","CheckBox",14)
	theme.set_icon("grabber","HSlider",Palette.control_texture("slider"))
	theme.set_icon("grabber_highlight","HSlider",Palette.control_texture("slider"))
	theme.set_stylebox("slider","HSlider",Palette.surface(Palette.INK,false))
	var tooltip_style := Palette.box(Palette.PANEL_LIGHT,8,Palette.EDGE)
	tooltip_style.content_margin_left = 12
	tooltip_style.content_margin_right = 12
	tooltip_style.content_margin_top = 8
	tooltip_style.content_margin_bottom = 8
	theme.set_stylebox("panel","TooltipPanel",tooltip_style)
	theme.set_color("font_color","TooltipLabel",Palette.WHITE)
	theme.set_font_size("font_size","TooltipLabel",16)
	theme.set_stylebox("normal","TextEdit",Palette.box(Palette.INK,8,Palette.EDGE))
	theme.set_color("font_color","TextEdit",Palette.WHITE)
	theme.set_stylebox("scroll","VScrollBar",Palette.box(Palette.PANEL,3))
	theme.set_stylebox("grabber","VScrollBar",Palette.box(Palette.EDGE,3))
	theme.set_stylebox("grabber_highlight","VScrollBar",Palette.box(Palette.MUTED,3))
	theme.set_stylebox("slider","HSlider",Palette.box(Palette.EDGE,3))
	theme.set_stylebox("grabber_area","HSlider",Palette.box(Palette.MINT,3))

# Layout expands with the logical viewport. Store the authored rectangles once,
# so repeated resizes never accumulate drift or recreate controls in use.
func layout_ui() -> void:
	if not is_instance_valid(ui):
		return
	var extra := size-Vector2(1440,900)
	scenery.size=size
	toast_layer.position=Vector2(extra.x/2,0)
	for child in ui.get_children():
		if not child is Control:
			continue
		if not child.has_meta("base_rect"):
			child.set_meta("base_rect",Rect2(child.position,child.size))
		var base: Rect2=child.get_meta("base_rect")
		var shift := extra/2
		if screen=="play":
			if base.position.x<180:
				shift.x=0
			elif base.position.x>=1230:
				shift.x=extra.x
			if base.position.y<110:
				shift.y=0
			elif base.position.y>=760:
				shift.y=extra.y
			if child==board_view and session.index>=3:
				shift=Vector2.ZERO
				child.size=base.size+extra
		child.position=base.position+shift
	if is_instance_valid(board_view) and hud.has("flag_mode"):
		hud.flag_mode.position=Vector2(board_view.size.x-73,48)
	for child in modal.get_children():
		if child is ColorRect:
			child.size=size
		elif child is Panel:
			child.position=(size-child.size)/2

func wipe(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func label_at(parent: Node, text_value: String, rect: Rect2, font_size: int = 16, color: Color = Palette.WHITE, bold: bool = false) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	if bold:
		label.add_theme_font_override("font",font_bold)
	label.mouse_filter = MOUSE_FILTER_IGNORE
	label.set_meta("layout_height",rect.size.y)
	parent.add_child(label)
	return label

func paragraph(parent: Node, text_value: String, rect: Rect2, font_size: int = 17, color: Color = Palette.MUTED) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = text_value
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.mouse_filter = MOUSE_FILTER_IGNORE
	label.set_meta("layout_height",rect.size.y)
	parent.add_child(label)
	return label

func panel(parent: Node, rect: Rect2, color: Color = Palette.PANEL, radius: int = 12, border: Color = Palette.EDGE) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.add_theme_stylebox_override("panel",Palette.surface(color) if radius>=5 else Palette.box(color,0,border))
	p.mouse_filter = MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p

func button(parent: Node, text_value: String, rect: Rect2, action: Callable, primary: bool = false) -> Button:
	var b := Button.new()
	b.text = text_value
	b.position = rect.position
	b.size = rect.size
	b.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size",16)
	if primary:
		b.add_theme_stylebox_override("normal",Palette.surface(Palette.MINT))
		b.add_theme_stylebox_override("hover",Palette.surface(Palette.MINT.lightened(0.12)))
		b.add_theme_color_override("font_color",Palette.INK)
		b.add_theme_color_override("font_hover_color",Palette.INK)
		b.add_theme_color_override("font_focus_color",Palette.INK)
		b.add_theme_font_override("font",font_bold)
	b.pressed.connect(func():
		audio.play("click")
		action.call()
	)
	parent.add_child(b)
	return b

func symbol_button(parent: Node, kind: String, rect: Rect2, action: Callable, help_text: String) -> Button:
	var b := button(parent,"",rect,action)
	icon(b,kind,Rect2(Vector2.ZERO,rect.size),Palette.WHITE,20)
	b.tooltip_text=help_text
	return b

func animate_button(b: Button, amount: float) -> void:
	if b.disabled or settings.get("motion",1.0) == 0:
		return
	if b.has_meta("hover_tween"):
		var previous: Tween = b.get_meta("hover_tween")
		if previous and previous.is_valid():
			previous.kill()
	b.pivot_offset = b.size/2
	var tween := b.create_tween()
	tween.tween_property(b,"scale",Vector2.ONE*amount,0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	b.set_meta("hover_tween",tween)

func icon(parent: Node, kind: String, rect: Rect2, color: Color = Palette.MINT, icon_size: float = 22) -> Glyph:
	var g := Glyph.new()
	g.position = rect.position
	g.size = rect.size
	g.kind = kind
	g.color = color
	g.icon_size = icon_size
	g.mouse_filter = MOUSE_FILTER_IGNORE
	parent.add_child(g)
	return g

func rule(parent: Node, p: Vector2, width_value: float) -> void:
	panel(parent,Rect2(p,Vector2(width_value,1)),Palette.EDGE,0,Palette.EDGE)

func show_menu() -> void:
	close_modal()
	wipe(ui)
	board_view = null
	hud.clear()
	screen = "menu"
	scenery.menu = true
	scenery.region = session.region() if session != null else 0
	scenery.restored = minf(1,float(session.index)/96) if session != null else 0
	var window := panel(ui,Rect2(86,156,610,581),Color("252d40"),5,Color("94a2b6"))
	panel(window,Rect2(5,5,600,38),Color("526e9b"),0,Color("9aaecf"))
	icon(window,"prism",Rect2(15,11,25,25),Palette.GOLD,18)
	label_at(window,"AFTERLIGHT.EXE",Rect2(48,10,310,27),14,Palette.WHITE,true)
	label_at(window,"01",Rect2(558,10,37,27),13,Palette.WHITE)
	label_at(window,"afterlight",Rect2(38,82,532,94),74,Palette.WHITE,true)
	label_at(window,"A world worth restoring.",Rect2(43,183,530,35),23,Palette.MUTED)
	var b := button(window,"Continue  →" if session != null else "New expedition  →",Rect2(42,261,526,65),start_play if session!=null else new_game,true)
	b.grab_focus()
	button(window,"Settings",Rect2(42,347,255,46),show_settings)
	button(window,"Field guide",Rect2(311,347,257,46),show_guide)
	if session!=null:
		button(window,"Start over",Rect2(42,409,255,43),confirm_new_game)
		button(window,"Credits",Rect2(311,409,257,43),show_credits)
	else:
		button(window,"Credits",Rect2(42,409,526,43),show_credits)
	label_at(window,"v%s  /  %s" % [Content.VERSION,"EXPEDITION %03d" % (session.index+1) if session else "READY WHEN YOU ARE"],Rect2(43,507,525,28),12,Palette.MUTED)
	if not OS.has_feature("web"):
		button(ui,"Exit",Rect2(1265,810,113,42),quit_game)
	layout_ui()

func new_game() -> void:
	session = GameSession.new()
	session.events.clear()
	save_game()
	start_play()


func confirm_new_game() -> void:
	var p := dialog("A fresh beginning",Vector2(620,350),"new")
	paragraph(p,"This replaces your current expedition. All equipment, restored regions and records will start over.",Rect2(38,98,540,92),20)
	button(p,"Keep my expedition",Rect2(38,240,264,54),close_modal,true)
	button(p,"Start over",Rect2(320,240,260,54),new_game)

func start_play() -> void:
	if session == null:
		new_game()
		return
	close_modal()
	wipe(ui)
	hud.clear()
	tool_buttons.clear()
	shop_buttons.clear()
	screen = "play"
	scenery.menu = false
	scenery.region = session.region()
	audio.set_region(session.region())
	selected_tool = ""
	ui_stage = disclosure_stage()
	build_header()
	build_field()
	build_tools()
	layout_ui()
	update_hud()
	if session.finished:
		finish_delay = 0.5

func disclosure_stage() -> int:
	if session.index > 0:
		return 3
	if session.finished:
		return 2
	return 1 if session.board.generated else 0

func build_header() -> void:
	label_at(ui,"AFTERLIGHT / FIELD OS",Rect2(45,31,350,35),18,Palette.WHITE,true)
	var region_name: String = Content.REGIONS[session.region()].name
	var title := label_at(ui,region_name,Rect2(45,70,390,29),14,Palette.MUTED)
	title.tooltip_text = "Site %d of 96" % (session.index+1)
	if ui_stage >= 2:
		panel(ui,Rect2(620,28,200 if ui_stage<3 else 300,58),Color("14262a"),28,Color("42605b"))
		icon(ui,"prism",Rect2(637,42,30,30),Palette.GOLD,22)
		hud.light = label_at(ui,"",Rect2(676,35,130,38),24,Palette.WHITE,true)
		if ui_stage >= 3:
			icon(ui,"core",Rect2(806,43,26,26),Palette.MUTED,20)
			hud.cores = label_at(ui,"",Rect2(843,38,74,32),20,Palette.MINT,true)
	symbol_button(ui,"pause",Rect2(1331,29,62,53),show_pause,"Pause · Esc")

func build_field() -> void:
	var early := session.index < 3
	var rect := Rect2(348,166,744,551) if early else Rect2(178,130,1084,621)
	board_view = BoardView.new()
	board_view.position = rect.position
	board_view.size = rect.size
	board_view.session = session
	board_view.motion = settings.motion
	board_view.high_contrast = settings.contrast
	board_view.cell_pressed.connect(on_cell)
	board_view.cell_hovered.connect(on_hover)
	ui.add_child(board_view)
	if ui_stage>=1:
		hud.flag_mode=symbol_button(board_view,"flag",Rect2(rect.size.x-73,48,44,34),toggle_flag_mode,"Flag mode · left click places flags · F")
	var accent := Color(Content.REGIONS[session.region()].color)
	var field_label := label_at(ui,"",Rect2(66,388,93,64),30,accent,true)
	field_label.tooltip_text = "Current site"
	field_label.mouse_filter = MOUSE_FILTER_PASS
	hud.progress = label_at(ui,"",Rect2(66,452,115,34),16,Palette.MUTED)
	hud.progress.visible = false
	if Content.strata_for(session.index,session.trial)>1:
		for layer in range(Content.strata_for(session.index,session.trial)):
			var slab := panel(ui,Rect2(70,512+layer*12,38,5),accent if layer<=session.stratum else Palette.EDGE,2)
			slab.tooltip_text = "Stratum %d of %d" % [session.stratum+1,Content.strata_for(session.index,session.trial)]
			slab.mouse_filter = MOUSE_FILTER_PASS
	if session.has("chain"):
		hud.chain = label_at(ui,"",Rect2(65,343,105,29),18,Palette.GOLD,true)
	if session.has("drone"):
		icon(ui,"drone",Rect2(1292,396,68,45),accent,32)
		hud.fleet_title = label_at(ui,str(session.drone_count()),Rect2(1360,400,45,38),22,accent,true)
		var fleet_button := symbol_button(ui,"pause",Rect2(1310,455,62,39),toggle_drones,"Pause / resume the fleet")
		hud.fleet_button = fleet_button
		hud.fleet_state = icon(ui,"pulse",Rect2(1326,508,30,30),Palette.MUTED,18)
		hud.fleet_state.mouse_filter = MOUSE_FILTER_PASS
	if session.has("cross"):
		panel(ui,Rect2(555,760,330,4),Palette.EDGE,2)
		hud.energy_bar = panel(ui,Rect2(555,760,330,4),accent,2)
		hud.energy_bar.mouse_filter = MOUSE_FILTER_PASS
	var cue := InputCue.new()
	cue.position=Vector2(620,732 if early else 841)
	cue.size=Vector2(200,38)
	cue.motion=settings.motion
	ui.add_child(cue)
	hud.cue=cue
	if ui_stage >= 2:
		var tree_button := button(ui,"",Rect2(1232,777,162,72),show_tree)
		icon(tree_button,"tree",Rect2(8,19,43,36),Palette.MINT,30)
		label_at(tree_button,"Grow",Rect2(58,20,90,32),21,Palette.WHITE,true)
		tree_button.tooltip_text = "Discover upgrades · Tab"
		hud.grow = tree_button
	if session.index >= 16:
		var map_button := button(ui,"Atlas",Rect2(46,798,111,42),show_records)
		map_button.tooltip_text = "Regions, records and optional mastery trials"

func build_tools() -> void:
	if ui_stage == 0:
		return
	var ids: Array[String] = ["probe"]
	for id in ["cross","line","nova","overdrive"]:
		if session.tool_available(id):
			ids.append(id)
	var width_value := ids.size()*83.0
	for j in range(ids.size()):
		var id: String = ids[j]
		var b := button(ui,"",Rect2(720-width_value/2+j*83,789,70,65),func(): select_tool(id))
		icon(b,tool_symbol(id),Rect2(16,14,38,38),Palette.MINT,29)
		label_at(b,str({"probe":1,"cross":2,"line":3,"nova":4,"overdrive":5}[id]),Rect2(6,1,20,19),10,Palette.MUTED)
		b.tooltip_text = tool_help(id)
		tool_buttons[id] = b
		hud["charge_"+id] = label_at(b,"",Rect2(39,44,28,18),11,Palette.GOLD)
	if session.layer_ready or session.finished:
		for b in tool_buttons.values():
			b.visible = false
		var next_button := button(ui,"Descend ↓" if session.layer_ready else "Site restored →",Rect2(602,786,236,66),descend_or_complete,true)
		hud.descend = next_button

func tool_symbol(id: String) -> String:
	match id:
		"probe":
			if session.has("prism"):
				return "upgrade:pulse3_focus" if session.has("focus") else "upgrade:pulse3"
			return "upgrade:pulse2_focus" if session.has("focus") else ("upgrade:probe2" if session.has("probe2") else "pulse")
		"cross":
			return "upgrade:diagonal" if session.has("diagonal") else "upgrade:cross"
		"line":
			return "upgrade:vertical" if session.has("vertical") else "upgrade:line"
		"nova":
			return "upgrade:aftershock" if session.has("aftershock") else "upgrade:nova"
	return "upgrade:"+id

func tool_help(id: String) -> String:
	if id=="probe":
		var count := 3 if session.has("prism") else (2 if session.has("probe2") else 1)
		return "Pulse · %d safe opening%s\n%s · 9s recharge" % [count,"s" if count>1 else "","Aim near your cursor" if session.has("focus") else "Free"]
	var symbol := tool_symbol(id).trim_prefix("upgrade:")
	var name_value: String=Content.upgrade(symbol).name
	var shape: String={"cross":"8 arms" if session.has("diagonal") else "Cross","line":"Row + column" if session.has("vertical") else "Full row","nova":"7 × 7" if session.has("aftershock") else "5 × 5","overdrive":"10× fleet · 12s"}.get(id,"")
	return "%s · %s\n%d energy" % [name_value,shape,session.tool_cost(id)]

func descend_or_complete() -> void:
	if session.finished:
		show_completion()
	elif session.advance_layer():
		consume_events()
		start_play()
		save_game()

func update_hud() -> void:
	if screen != "play" or session == null or hud.is_empty():
		return
	if hud.has("light"):
		hud.light.text = format_number(session.credits)
	if hud.has("cores"):
		hud.cores.text = str(session.cores)
	if hud.has("flag_mode"):
		hud.flag_mode.add_theme_stylebox_override("normal",Palette.surface(Palette.MINT if settings.flag_mode else Palette.PANEL_LIGHT,not settings.flag_mode))
		var flag_glyph := hud.flag_mode.get_child(0) as Glyph
		flag_glyph.color=Palette.INK if settings.flag_mode else Palette.WHITE
		flag_glyph.queue_redraw()
		hud.flag_mode.tooltip_text="Flag mode on · click to return to revealing" if settings.flag_mode else "Flag mode · left click places flags · F"
	if hud.has("energy_bar"):
		hud.energy_bar.size.x = maxf(1,330*session.energy/session.capacity())
		hud.energy_bar.tooltip_text = "%d / %d energy" % [session.energy,session.capacity()]
	var b := session.board
	hud.progress.text = "%d / %d" % [b.open_count(),b.width*b.height-b.mine_count]
	if hud.has("chain"):
		hud.chain.text = "×%d" % session.multiplier()
		hud.chain.tooltip_text = "Manual chain: %d. No timer." % session.chain
	hud.cue.visible = not session.finished and not session.layer_ready and (selected_tool!="" or settings.flag_mode or (session.index==0 and session.manual_actions<4))
	hud.cue.mode = "aim" if selected_tool!="" else ("flag" if b.generated or settings.flag_mode else "reveal")
	hud.cue.keyboard = board_view.keyboard_cell>=0
	hud.cue.tooltip_text = "Aim · Esc cancels" if selected_tool!="" else ("Flag · right mouse / F" if b.generated else "Reveal · left mouse / Enter")
	for id in tool_buttons:
		var btool: Button = tool_buttons[id]
		var running: bool=id=="overdrive" and session.overdrive_seconds>0
		btool.disabled = running or (session.probe_charge<1 if id=="probe" else session.energy<session.minimum_tool_cost(id)) or session.finished or session.layer_ready
		var caption: Label = hud["charge_"+id]
		caption.text = str(int(session.probe_charge)) if id=="probe" and session.has("reservoir") else ("%ds" % ceili((1-session.probe_charge)*9) if id=="probe" and session.probe_charge<1 else (str(int(session.tool_cost(id))) if id!="probe" else ""))
		if running:
			caption.text="%ds" % ceili(session.overdrive_seconds)
		var tool_glyph := btool.get_child(0) as Glyph
		tool_glyph.color=Palette.GOLD if running else Palette.MINT
		tool_glyph.queue_redraw()
		btool.add_theme_stylebox_override("normal",Palette.surface(Palette.MINT.darkened(0.55) if selected_tool==id else Palette.PANEL_LIGHT,selected_tool!=id))
	if hud.has("fleet_title"):
		hud.fleet_title.text = str(session.drone_count())
		hud.fleet_state.visible = session.drone_status == "Waiting for a new opening"
		hud.fleet_state.tooltip_text = "Fleet needs a new opening"
		var fleet_glyph := hud.fleet_button.get_child(0) as Glyph
		fleet_glyph.kind = "pause" if session.drones_enabled else "play"
		fleet_glyph.queue_redraw()
	if hud.has("grow"):
		var ready := 0
		for item in Content.UPGRADES:
			if session.unlock_reason(item)=="READY TO INSTALL":
				ready += 1
		hud.grow.add_theme_stylebox_override("normal",Palette.surface(Palette.PANEL_LIGHT.lightened(0.07) if ready else Palette.PANEL))
	board_view.active_tool = selected_tool
	board_view.blocked = modal_kind != "" or session.finished or session.layer_ready

func show_tree() -> void:
	if session == null or disclosure_stage() < 2:
		return
	var p := dialog("",Vector2(1380,844),"tree")
	# The tree is a place to explore; the field stays quiet while this is open.
	upgrade_tree = UpgradeTree.new()
	upgrade_tree.position = Vector2(12,96)
	upgrade_tree.size = Vector2(992,713)
	upgrade_tree.session = session
	upgrade_tree.motion = settings.motion
	upgrade_tree.chosen = tree_selected
	upgrade_tree.zoom = 0.55 if session.index>25 else 0.92
	upgrade_tree.selected.connect(tree_focus)
	upgrade_tree.activate.connect(purchase_upgrade)
	p.add_child(upgrade_tree)
	label_at(p,"Discoveries",Rect2(38,29,540,49),32,Palette.WHITE,true)
	label_at(p,"%d / 50" % session.upgrades.size(),Rect2(984,36,120,32),17,Palette.MUTED)
	icon(p,"prism",Rect2(1106,40,24,24),Palette.GOLD,19)
	label_at(p,format_number(session.credits),Rect2(1135,36,93,32),18,Palette.WHITE)
	icon(p,"core",Rect2(1227,40,24,24),Palette.MUTED,19)
	label_at(p,str(session.cores),Rect2(1257,36,50,32),18,Palette.WHITE)
	tree_detail = Control.new()
	tree_detail.position = Vector2(1024,135)
	tree_detail.size = Vector2(314,627)
	p.add_child(tree_detail)
	var cue := InputCue.new()
	cue.mode="tree"
	cue.position=Vector2(38,786)
	cue.size=Vector2(280,42)
	cue.tooltip_text="Drag to pan · scroll to zoom\nArrow keys select · Enter connects"
	p.add_child(cue)
	tree_focus(tree_selected)
	upgrade_tree.grab_focus()

func tree_focus(id: String) -> void:
	tree_selected = id
	if is_instance_valid(upgrade_tree):
		upgrade_tree.chosen = id
	if not is_instance_valid(tree_detail):
		return
	wipe(tree_detail)
	var item := Content.upgrade(id)
	var color := Palette.MINT
	label_at(tree_detail,"ORIGIN" if item.branch<0 else Content.BRANCH_NAMES[item.branch],Rect2(0,0,314,26),12,color,true)
	var preview := DiscoveryPreview.new()
	preview.position = Vector2(0,49)
	preview.size = Vector2(300,200)
	preview.item = item
	preview.motion = settings.motion
	tree_detail.add_child(preview)
	icon(tree_detail,"upgrade:"+id,Rect2(0,275,45,48),Palette.MINT,38)
	paragraph(tree_detail,item.name,Rect2(60,274,250,80),26,Palette.WHITE)
	paragraph(tree_detail,item.desc,Rect2(0,361,302,92),18,Palette.MUTED)
	var reason := session.unlock_reason(item)
	var owned := session.has(id)
	label_at(tree_detail,"%s light   /   %d cores" % [format_number(item.cost),item.cores] if not owned else "Connected",Rect2(0,479,306,30),17,color)
	var buy_button := button(tree_detail,"Connect" if reason=="READY TO INSTALL" else reason,Rect2(0,530,300,59),func(): purchase_upgrade(id),reason=="READY TO INSTALL")
	buy_button.add_theme_font_size_override("font_size",15)
	buy_button.disabled = reason != "READY TO INSTALL"
	shop_buttons[id] = buy_button

func rebuild_shop() -> void:
	show_tree()

func update_shop() -> void:
	pass

func on_cell(i: int, right: bool, keyboard_reveal: bool = false) -> void:
	if modal_kind != "" or session.finished:
		return
	get_viewport().gui_release_focus()
	if right or (settings.flag_mode and session.board.generated and selected_tool == "" and not keyboard_reveal):
		session.flag(i)
	elif selected_tool != "":
		if session.use_tool(selected_tool,i):
			selected_tool = ""
	else:
		session.reveal(i)
	after_action()

func on_hover(i: int) -> void:
	# Clue/flag/plate counts are drawn in the terminal's footer, away from the
	# puzzle. A popup must never cover the neighbouring cells being inspected.
	board_view.tooltip_text = ""

func select_tool(id: String) -> void:
	if modal_kind!="" or not session.tool_available(id):
		return
	if session.finished:
		show_completion()
		return
	if id == "probe" and not session.has("focus"):
		session.use_tool("probe")
	elif id == "overdrive":
		session.use_tool(id)
	elif id == "probe":
		selected_tool = "" if selected_tool == id else id
	elif session.has(id):
		selected_tool = "" if selected_tool == id else id
	after_action()

func purchase_upgrade(id: String) -> void:
	if session.buy(id):
		var old_history := modal_history.duplicate()
		var old_pan := upgrade_tree.pan if is_instance_valid(upgrade_tree) else Vector2.ZERO
		var old_zoom := upgrade_tree.zoom if is_instance_valid(upgrade_tree) else 0.76
		consume_events()
		start_play()
		show_tree()
		modal_history.assign(old_history)
		upgrade_tree.pan = old_pan
		upgrade_tree.zoom = old_zoom
		upgrade_tree.burst_id = id
		upgrade_tree.burst_age = 0
		save_game()

func toggle_drones() -> void:
	session.drones_enabled = not session.drones_enabled
	update_hud()
	mark_save()

func toggle_flag_mode() -> void:
	settings.flag_mode=not settings.flag_mode
	selected_tool=""
	store.write_settings(settings)
	update_hud()

func after_action() -> void:
	consume_events()
	if screen=="play" and ui_stage != disclosure_stage():
		start_play()
	update_hud()
	mark_save()

func consume_events() -> void:
	var events := session.events.duplicate()
	session.events.clear()
	for event in events:
		match event.type:
			"reveal":
				board_view.animate_cells(event.cells,event.source)
				if event.amount > 0:
					var p := board_view.position+board_view.cell_position(event.cells[0])
					effects.popup(p,"+%d" % event.amount,Palette.MINT)
					effects.burst(p,Palette.MINT,mini(event.cells.size()*2+3,18),hud.light.position+Vector2(-24,19) if hud.has("light") else Vector2(-1,-1))
					audio.play("reveal",pow(2,float(mini(event.chain,16)%5)/12))
			"excavate":
				var p := board_view.position+board_view.cell_position(event.cell)
				board_view.animations[event.cell] = 0
				if event.get("source","")=="drone":
					board_view.visit_drone(event.cell)
				effects.burst(p,Palette.GOLD,6 if event.broken else 3)
				audio.play("flag",0.8 if not event.broken else 1.2)
			"layer_complete":
				board_view.complete_wave = 0
				audio.play("complete",1.2)
				call_deferred("refresh_layer_ui")
			"new_layer":
				call_deferred("refresh_layer_ui")
			"strike":
				var p := board_view.position+board_view.cell_position(event.cell)
				board_view.shake = 3
				effects.burst(p,Palette.CORAL,18)
				effects.ring(p,Palette.CORAL)
				audio.play("strike")
				toast("Shield caught it." if event.protected else "A strike. Keep your light, keep going.")
			"flag":
				audio.play("flag",1.1 if event.auto else 1.0)
				board_view.animations[event.cell] = 0
			"pocket":
				var p := board_view.position+board_view.cell_position(event.cell)
				effects.ring(p,Palette.GOLD)
				audio.play("pocket")
			"tool":
				audio.play("tool")
				var p := board_view.position+board_view.size/2 if event.cell < 0 else board_view.position+board_view.cell_position(event.cell)
				effects.ring(p,Palette.MINT)
				if event.cell >= 0 and event.id in ["line","cross","nova"]:
					for target in session.tool_cells(event.id,event.cell):
						effects.beam(p,board_view.position+board_view.cell_position(target),Palette.MINT)
			"upgrade":
				audio.play("upgrade")
				effects.burst(Vector2(1100,500),Palette.GOLD,30)

			"tip":
				toast(event.text,4)
			"complete":
				board_view.complete_wave = 0
				effects.burst(board_view.position+board_view.size/2,Palette.GOLD,40)
				audio.play("complete")
				finish_delay = 1.2
				save_game()

func _process(delta: float) -> void:
	if screen == "play" and session != null and modal_kind == "":
		session.tick(delta)
		if not session.events.is_empty():
			consume_events()
			mark_save()
		autosave_clock += delta
		if autosave_clock > 12:
			save_game()
		if finish_delay >= 0:
			finish_delay -= delta
			if finish_delay < 0 and session.finished:
				show_completion()
	hud_clock += delta
	if hud_clock > 0.2:
		hud_clock = 0
		update_hud()
	if save_pending:
		save_delay -= delta
		if save_delay <= 0:
			save_game()
	if toast_time > 0:
		toast_time -= delta
		toast_layer.modulate.a = minf(1,toast_time*3)
		if toast_time <= 0:
			wipe(toast_layer)

func mark_save() -> void:
	if not save_pending:
		save_pending = true
		save_delay = 1.0

func save_game() -> bool:
	if session == null:
		return true
	var success := store.write_session(session)
	if success:
		save_status = "All progress saved"
	else:
		save_status = "Save needs attention"
		toast(store.last_error,8)
	autosave_clock = 0
	save_pending = false
	return success

func toast(message: String, duration: float = 3.5) -> void:
	wipe(toast_layer)
	toast_time = duration
	toast_layer.modulate.a = 1
	panel(toast_layer,Rect2(390,103,660,52),Palette.PANEL_LIGHT,12,Palette.MINT.darkened(0.4))
	paragraph(toast_layer,message,Rect2(410,113,620,35),16,Palette.WHITE)

func dialog(title: String, dimensions: Vector2, kind: String) -> Panel:
	var previous := modal_kind
	var history := modal_history.duplicate()
	var return_focus := modal_return_focus if previous!="" else get_viewport().gui_get_focus_owner()
	close_modal()
	modal_history.assign(history)
	if previous!="" and previous!=kind:
		modal_history.append(previous)
	modal_return_focus=return_focus
	set_background_focus(false)
	get_viewport().gui_release_focus()
	toast_time = 0
	wipe(toast_layer)
	modal_kind = kind
	var dim := ColorRect.new()
	dim.color = Color(0.015,0.035,0.045,0.86)
	dim.size = size
	dim.mouse_filter = MOUSE_FILTER_STOP
	modal.add_child(dim)
	var p := panel(modal,Rect2((size-dimensions)/2,dimensions),Palette.PANEL,5,Color("9aa5b7"))
	panel(p,Rect2(5,5,dimensions.x-10,76),Color("526e9b"),0,Color("869dbc"))
	p.mouse_filter = MOUSE_FILTER_STOP
	label_at(p,title,Rect2(38,28,dimensions.x-125,50),30,Palette.WHITE,true)
	var close_button := symbol_button(p,"close",Rect2(dimensions.x-71,31,38,38),back_modal,"Back · Esc" if not modal_history.is_empty() else "Close · Esc")
	close_button.grab_focus()
	rule(p,Vector2(38,87),dimensions.x-76)
	if board_view:
		board_view.blocked = true
	return p

func close_modal() -> void:
	wipe(modal)
	modal_kind = ""
	modal_history.clear()
	set_background_focus(true)
	if is_instance_valid(modal_return_focus) and modal_return_focus.is_inside_tree() and modal_return_focus.is_visible_in_tree():
		modal_return_focus.grab_focus()
	modal_return_focus=null
	if board_view:
		board_view.blocked = session.finished or session.layer_ready

func set_background_focus(enabled: bool) -> void:
	for control in ui.find_children("*","Control",true,false):
		if enabled and control.has_meta("modal_focus"):
			control.focus_mode=int(control.get_meta("modal_focus"))
			control.remove_meta("modal_focus")
		elif not enabled and not control.has_meta("modal_focus"):
			control.set_meta("modal_focus",control.focus_mode)
			control.focus_mode=Control.FOCUS_NONE

func back_modal() -> void:
	var history := modal_history.duplicate()
	close_modal()
	while not history.is_empty():
		var previous: String=history.pop_back()
		var action: Callable={"pause":show_pause,"settings":show_settings,"guide":show_guide,"records":show_records,"credits":show_credits,"licenses":show_licenses,"complete":show_completion,"tree":show_tree}.get(previous,Callable())
		if action.is_valid():
			action.call()
			modal_history.assign(history)
			return

func show_pause() -> void:
	if screen != "play":
		return
	save_game()
	var p := dialog("Paused",Vector2(540,594),"pause")
	label_at(p,save_status,Rect2(38,106,468,36),16,Palette.MUTED)
	var resume := button(p,"Resume expedition   →",Rect2(38,167,464,57),close_modal,true)
	resume.grab_focus()
	button(p,"Settings",Rect2(38,239,226,48),show_settings)
	button(p,"Field guide",Rect2(277,239,225,48),show_guide)
	button(p,"Atlas & records",Rect2(38,303,464,48),show_records)
	button(p,"Save & main menu",Rect2(38,367,464,48),func():
		save_game()
		show_menu()
	)
	button(p,"Save & quit",Rect2(38,431,464,48),quit_game)
	label_at(p,"F10  Capture a local field report",Rect2(38,518,464,26),14,Palette.MUTED)

func show_settings() -> void:
	var p := dialog("Settings",Vector2(690,706),"settings")
	var names := ["Music","Sound effects","Motion intensity"]
	var keys := ["music","sfx","motion"]
	for i in range(3):
		label_at(p,names[i],Rect2(38,113+i*71,230,32),18,Palette.WHITE)
		var slider := HSlider.new()
		slider.position = Vector2(289,123+i*71)
		slider.size = Vector2(284,24)
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.05
		slider.value = settings[keys[i]]
		slider.tooltip_text="0 removes shake, drifting and reveal movement" if keys[i]=="motion" else names[i]
		var value_label := label_at(p,"%d%%" % roundi(slider.value*100),Rect2(594,115+i*71,65,32),16,Palette.MINT)
		slider.value_changed.connect(func(value):
			settings[keys[i]] = value
			value_label.text = "%d%%" % roundi(value*100)
			apply_settings()
			store.write_settings(settings)
		)
		p.add_child(slider)
	rule(p,Vector2(38,333),614)
	var toggles := [["particles","Resource particles"],["contrast","High contrast clues"],["auto_pause","Pause when window loses focus"],["fullscreen","Fullscreen  ·  F11"]]
	for i in range(toggles.size()):
		var key: String = toggles[i][0]
		var toggle := CheckBox.new()
		toggle.text = toggles[i][1]
		toggle.position = Vector2(38,354+i*54)
		toggle.size = Vector2(614,44)
		toggle.button_pressed = settings[key]
		toggle.add_theme_color_override("font_color",Palette.WHITE)
		toggle.toggled.connect(func(value):
			settings[key] = value
			apply_settings()
			store.write_settings(settings)
		)
		p.add_child(toggle)
	label_at(p,"Saved automatically",Rect2(38,642,380,35),14,Palette.MUTED)
	button(p,"Done",Rect2(474,641,178,40),back_modal,true)

func apply_settings() -> void:
	if scenery:
		scenery.motion = settings.motion
	if effects:
		effects.motion = settings.motion
		effects.enabled = settings.particles
	if audio:
		audio.music_volume = settings.music
		audio.sfx_volume = settings.sfx
	if board_view:
		board_view.motion = settings.motion
		board_view.high_contrast = settings.contrast
	if not visual_test and not OS.has_feature("web"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func show_guide(page: int = 0) -> void:
	var p := dialog("Field guide",Vector2(820,641),"guide")
	for i in range(3):
		button(p,["Clues","Equipment","Depth"][i],Rect2(38+i*252,109,240,41),func(): show_guide(i),i==page)
	var preview := DiscoveryPreview.new()
	preview.position = Vector2(61,225)
	preview.size = Vector2(300,200)
	preview.item = Content.upgrade(["lens","cross","drill"][page])
	preview.motion = settings.motion
	p.add_child(preview)
	var heading: String = ["Read the neighbours.","Give your hands more reach.","Go deeper. Bring better tools."][page]
	var text_value: String = [
		"1 means one charge in the eight touching tiles.\n\nRight-click to flag. Match a clue's flags, then click the clue to open its neighbours.\n\nUncertain? Pulse opens safe ground.",
		"Grow opens the upgrade tree. Connect a node to reach its branches.\n\nSelect a tool, then aim at the field. Hover its button for the cost and effect.\n\nManual work and crystals recharge energy.",
		"Stripes are buried plates. Read the clues, then break through.\n\nClear a stratum to descend. Equipment stays with you.\n\nDrones solve clues. Drills and beams let them tackle bigger excavations."
	][page]
	paragraph(p,heading,Rect2(378,195,399,65),25,Palette.WHITE)
	paragraph(p,text_value,Rect2(378,289,392,255),17,Palette.MUTED)
	label_at(p,"Arrows: select   Enter: reveal   F: flag   Tab: grow   Esc: pause",Rect2(38,580,750,28),14,Palette.MUTED)

func show_region(number: int) -> void:
	var data: Dictionary = Content.REGIONS[number]
	var p := dialog(data.name,Vector2(650,463),"region")
	label_at(p,"RELAY %02d  /  %s" % [number+1,data.tag],Rect2(38,109,584,29),13,Color(data.color),true)
	paragraph(p,data.story,Rect2(38,163,580,92),25,Palette.WHITE)
	paragraph(p,data.effect,Rect2(38,279,575,66),18)
	label_at(p,"RESTORED" if session.index > number*16+15 else ("CURRENT REGION" if session.region()==number else "Restore the previous relay to reach this region."),Rect2(38,374,575,39),16,Color(data.color))

func show_completion() -> void:
	if not session.finished:
		return
	var reward := session.last_reward
	var region_end: bool = reward.region_end
	var ending := region_end and session.index == 95
	var dimensions := Vector2(708,572 if region_end else 405)
	var p := dialog("Morning, at last." if ending else ("Relay restored" if region_end else "Site restored"),dimensions,"complete")
	var accent := Color(Content.REGIONS[session.region()].color)
	label_at(p,"✦  ".repeat(int(reward.rating)),Rect2(36,103,470,65),39,Palette.GOLD,true)
	if region_end:
		paragraph(p,Content.REGIONS[session.region()].end,Rect2(38,186,632,126),21,Palette.WHITE)
	var y := 338 if region_end else 190
	icon(p,"prism",Rect2(38,y,42,42),Palette.GOLD,28)
	label_at(p,"+%s" % format_number(reward.earned),Rect2(95,y-3,240,44),31,Palette.GOLD,true)
	icon(p,"core",Rect2(415,y,40,40),Palette.MUTED,26)
	label_at(p,"+%d" % reward.cores,Rect2(466,y-3,202,44),31,accent,true)
	button(p,"Grow",Rect2(38,y+78,253,56),show_tree)
	var next := button(p,"Beyond dawn →" if ending else ("Return →" if session.trial>=0 else "Next site →"),Rect2(309,y+78,361,56),next_expedition,true)
	next.grab_focus()
	label_at(p,"Saved",Rect2(38,dimensions.y-45,200,26),12,Palette.MUTED)

func next_expedition() -> void:
	session.next_board()
	session.events.clear()
	finish_delay = -1
	save_game()
	start_play()
	if session.index%16 == 0:
		toast(Content.REGIONS[session.region()].story.replace("\n"," "),6)

func show_records() -> void:
	if session == null:
		return
	var p := dialog("Atlas",Vector2(884,750),"records")
	label_at(p,"%d / 96 fields    ·    %d stars    ·    %s light recovered" % [mini(session.medals.size(),96),session.stars(),format_number(session.total_light)],Rect2(38,110,808,36),19,Palette.MINT)
	label_at(p,"%d:%02d in the field    /    %d drone reveals    /    %d charges mapped" % [int(session.play_seconds)/60,int(session.play_seconds)%60,session.total_drone,session.total_flags],Rect2(38,151,808,30),15,Palette.MUTED)
	for r in range(6):
		var y := 203+r*58
		label_at(p,Content.REGIONS[r].name,Rect2(38,y,215,34),17,Color(Content.REGIONS[r].color))
		for j in range(16):
			var stars: int = int(session.medals.get(str(r*16+j),0))
			var tile := panel(p,Rect2(259+j*35,y,29,32),Palette.PANEL_LIGHT if stars else Palette.INK,5,Palette.EDGE)
			var lab := label_at(tile,str(stars) if stars else "·",Rect2(0,0,29,32),15,Palette.GOLD if stars else Palette.MUTED)
			lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_at(p,"MASTERY TRIALS",Rect2(38,566,400,26),12,Palette.MUTED,true)
	for t in range(12):
		var number := t
		var b := button(p,str(t+1)+("  ★" if session.trial_medals.has(str(t)) else ""),Rect2(38+t*67,606,59,41),func(): show_trial(number))
		b.disabled = session.index < (t/2+1)*16
		b.tooltip_text = "Survey only" if t%2==0 else "Full fleet · dense field"
	label_at(p,"FLEET LIVERY",Rect2(38,681,156,30),12,Palette.MUTED,true)
	for i in range(3):
		var b := button(p,["Sea glass","Sunbeam · 48★","Coral · 144★"][i],Rect2(204+i*213,677,201,36),func():
			session.livery = i
			mark_save()
			show_records()
		,i==session.livery)
		b.disabled = session.stars() < [0,48,144][i]

func show_trial(number: int) -> void:
	var p := dialog("Mastery trial %02d" % (number+1),Vector2(650,430),"trial")
	paragraph(p,"Survey only" if number%2==0 else "Full fleet expedition",Rect2(38,113,575,46),24,Palette.MINT)
	paragraph(p,"A denser, fixed-seed field. " + ("Drones and advanced tools rest; your free Pulse still works." if number%2==0 else "Use your complete toolkit and fleet to earn a perfect survey.") + "\n\nFirst clear awards three extra cores. Trials are available between campaign fields.",Rect2(38,174,574,149),18)
	var can_start := session.finished or not session.board.generated
	var b := button(p,"Deploy   →" if can_start else "Finish your current field first",Rect2(38,346,574,50),func():
		# Finish the current campaign field before entering the trial, avoiding
		# replaying a completed reward on return.
		if session.finished:
			session.next_board()
		if session.begin_trial(number):
			session.events.clear()
			start_play()
			save_game()
	,true)
	b.disabled = not can_start

func show_credits() -> void:
	var p := dialog("About Afterlight",Vector2(750,614),"credits")
	label_at(p,"AFTERLIGHT",Rect2(38,115,674,60),43,Palette.WHITE,true)
	paragraph(p,"An original incremental puzzle expedition.\nArt: procedural geometry and cartography.\nMusic and sound: six original scores and oscillator synthesis.\n\nBuilt with Godot Engine 4.7 (MIT licence). Typography uses Godot's bundled Noto Sans (SIL Open Font License).\n\nInspired by quiet science fiction and the pleasure of watching small machines learn.\n\nGame-feel references: Juice It or Lose It, Martin Jonasson & Petri Purho; The Art of Screenshake, Jan Willem Nijman.",Rect2(38,196,674,322),17,Palette.MUTED)
	button(p,"Engine & library licences",Rect2(38,537,327,44),show_licenses)
	button(p,"Back to the light",Rect2(385,537,327,44),close_modal,true)

func show_licenses() -> void:
	var p := dialog("Open-source acknowledgements",Vector2(850,712),"licenses")
	var text := RichTextLabel.new()
	text.position = Vector2(38,110)
	text.size = Vector2(774,558)
	text.add_theme_font_size_override("normal_font_size",14)
	text.add_theme_color_override("default_color",Palette.MUTED)
	var content := "GODOT ENGINE\n\n" + Engine.get_license_text() + "\n\nTHIRD-PARTY COMPONENTS\n"
	for entry in Engine.get_copyright_info():
		content += "\n" + str(entry.name) + "\n"
		for part in entry.parts:
			content += "\n" + "\n".join(part.copyright) + "\nLicence: " + str(part.license) + "\n"
	for key in Engine.get_license_info():
		content += "\n\n" + key + "\n" + Engine.get_license_info()[key]
	text.text = content
	p.add_child(text)

func capture_report() -> void:
	if modal_kind == "report":
		return
	await RenderingServer.frame_post_draw
	report_image = get_viewport().get_texture().get_image()
	var p := dialog("Leave a field report",Vector2(760,536),"report")
	paragraph(p,"Your screenshot and expedition state are ready. Add a note; this stays on your computer and is never sent automatically.",Rect2(38,108,684,65),17)
	var entry := TextEdit.new()
	entry.position = Vector2(38,187)
	entry.size = Vector2(684,219)
	entry.placeholder_text = "What happened? What did you expect?"
	p.add_child(entry)
	entry.grab_focus()
	button(p,"Save local report",Rect2(38,437,684,56),func():
		var folder := store.path("reports/"+Time.get_datetime_string_from_system().replace(":","-"))
		DirAccess.make_dir_recursive_absolute(folder)
		var screenshot_error := report_image.save_png(folder.path_join("screenshot.png"))
		var file := FileAccess.open(folder.path_join("report.txt"),FileAccess.WRITE)
		if file == null or screenshot_error != OK:
			toast("Could not write report. Check the save folder permissions.",6)
			return
		file.store_string("Afterlight "+Content.VERSION+"\n"+entry.text+"\n\n"+JSON.stringify(session.to_dict() if session else {},"  "))
		file.close()
		close_modal()
		toast("Report saved to "+ProjectSettings.globalize_path(folder),8)
	,true)

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_F11:
		settings.fullscreen = not settings.fullscreen
		apply_settings()
		store.write_settings(settings)
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_F10:
		capture_report()
		return
	if event.keycode == KEY_ESCAPE:
		if modal_kind != "":
			back_modal()
		elif selected_tool != "":
			selected_tool = ""
			update_hud()
		elif screen == "play":
			show_pause()
		get_viewport().set_input_as_handled()
		return
	if modal_kind != "":
		return
	if event.keycode == KEY_TAB and screen=="play":
		show_tree()
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_F1:
		show_guide()
		return
	if screen != "play":
		return
	# Tab/Enter still operate native menus. Arrow keys explicitly return to
	# the field, even when a tool button currently owns keyboard focus.
	if event.keycode in [KEY_SPACE,KEY_ENTER] and get_viewport().gui_get_focus_owner() is Button:
		return
	if session.layer_ready:
		if event.keycode in [KEY_ENTER,KEY_SPACE]:
			descend_or_complete()
			get_viewport().set_input_as_handled()
		return
	if session.finished:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			show_completion()
		return
	var b := session.board
	if event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:
		if board_view.keyboard_cell < 0:
			board_view.keyboard_cell = b.width*(b.height/2)+b.width/2
		else:
			var n := board_view.keyboard_cell
			if event.keycode == KEY_LEFT and n%b.width > 0:
				n -= 1
			elif event.keycode == KEY_RIGHT and n%b.width < b.width-1:
				n += 1
			elif event.keycode == KEY_UP:
				n = maxi(0,n-b.width)
			elif event.keycode == KEY_DOWN:
				n = mini(b.cells.size()-1,n+b.width)
			board_view.keyboard_cell = n
		get_viewport().gui_release_focus()
	elif event.keycode in [KEY_SPACE,KEY_ENTER] and board_view.keyboard_cell >= 0:
		on_cell(board_view.keyboard_cell,false,true)
	elif event.keycode == KEY_SPACE or event.keycode == KEY_1:
		select_tool("probe")
	elif event.keycode == KEY_F:
		if board_view.keyboard_cell >= 0:
			on_cell(board_view.keyboard_cell,true)
		else:
			toggle_flag_mode()
	elif event.keycode in [KEY_2,KEY_3,KEY_4]:
		select_tool({KEY_2:"cross",KEY_3:"line",KEY_4:"nova"}[event.keycode])
	elif event.keycode == KEY_5 and session.has("overdrive"):
		session.use_tool("overdrive")
		after_action()
	if event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN,KEY_SPACE,KEY_ENTER,KEY_F,KEY_1,KEY_2,KEY_3,KEY_4,KEY_5]:
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and not visual_test and settings.get("auto_pause",true) and screen == "play" and modal_kind == "":
		show_pause()

func quit_game() -> void:
	if not save_game():
		var p := dialog("Your save needs attention",Vector2(676,404),"save_error")
		paragraph(p,store.last_error+"\n\nYour previous save is still available. Stay here to keep the current expedition in memory, or retry after freeing disk space.",Rect2(38,109,600,146),18)
		button(p,"Stay here",Rect2(38,305,185,53),close_modal,true)
		button(p,"Retry save",Rect2(243,305,185,53),quit_game)
		button(p,"Quit without saving",Rect2(448,305,190,53),func(): get_tree().quit())
		return
	store.write_settings(settings)
	if not OS.has_feature("web"):
		get_tree().quit()
	else:
		show_menu()

func format_number(value: int) -> String:
	if value < 10000:
		return str(value)
	return "%.1fk" % (float(value)/1000)

# The release smoke path is deliberately gated behind both an explicit command
# argument and an isolated save directory. It tests the shipped PCK itself.
func release_smoke() -> void:
	if store.directory == "user://":
		printerr("Release smoke requires an isolated --test-data path")
		get_tree().quit(1)
		return
	session = null
	show_menu()
	await smoke_capture("release-menu")
	await smoke_click(Vector2(390,450))
	var ok := screen == "play" and session != null
	if not ok:
		printerr("Release menu did not start game")
		get_tree().quit(1)
		return
	await smoke_click(board_view.position+board_view.cell_position(27))
	ok = ok and session.board.generated and session.strikes == 0
	await smoke_capture("release-field")
	save_game()
	var loaded := store.load_session()
	ok = ok and loaded != null and loaded.board.cells == session.board.cells
	while not session.finished:
		session.probe_one("tool")
	after_action()
	show_tree()
	await smoke_capture("release-tree")
	await smoke_click(tree_detail.global_position+Vector2(150,555))
	ok = ok and session.has("lens") and save_game()
	loaded = store.load_session()
	ok = ok and loaded != null and loaded.has("lens")
	show_settings()
	await smoke_capture("release-settings")
	show_licenses()
	await smoke_capture("release-licences")
	print("AFTERLIGHT %s: exported build boots, renders, buys a tree node and reloads saves; editor=%s" % ["PASS" if ok else "FAIL",str(OS.has_feature("editor"))])
	get_tree().quit(0 if ok else 1)

func smoke_capture(filename: String) -> void:
	for _i in range(30):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(store.path(filename+".png"))

func smoke_click(p: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = p
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	get_viewport().push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	get_viewport().push_input(event,true)
	await get_tree().process_frame

func refresh_layer_ui() -> void:
	if screen == "play" and modal_kind == "":
		start_play()
