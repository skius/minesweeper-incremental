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

func _ready() -> void:
	get_tree().auto_accept_quit = false
	visual_test = OS.get_cmdline_user_args().has("--visual-test")
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
	if store.notice != "":
		toast(store.notice,7)
	if visual_test:
		var runner = load("res://tests/visual_session.gd").new()
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
	theme.set_stylebox("normal","Button",Palette.box(Palette.PANEL_LIGHT,9,Palette.EDGE))
	theme.set_stylebox("hover","Button",Palette.box(Palette.PANEL_LIGHT.lightened(0.08),9,Palette.MINT.darkened(0.3)))
	theme.set_stylebox("pressed","Button",Palette.box(Palette.MINT,9))
	theme.set_stylebox("focus","Button",Palette.box(Color.TRANSPARENT,9,Palette.GOLD,2))
	theme.set_stylebox("disabled","Button",Palette.box(Palette.PANEL,9,Palette.EDGE.darkened(0.35)))
	theme.set_stylebox("panel","TooltipPanel",Palette.box(Palette.PANEL_LIGHT,8,Palette.EDGE))
	theme.set_color("font_color","TooltipLabel",Palette.WHITE)
	theme.set_font_size("font_size","TooltipLabel",16)
	theme.set_stylebox("normal","TextEdit",Palette.box(Palette.INK,8,Palette.EDGE))
	theme.set_color("font_color","TextEdit",Palette.WHITE)
	theme.set_stylebox("scroll","VScrollBar",Palette.box(Palette.PANEL,3))
	theme.set_stylebox("grabber","VScrollBar",Palette.box(Palette.EDGE,3))
	theme.set_stylebox("grabber_highlight","VScrollBar",Palette.box(Palette.MUTED,3))
	theme.set_stylebox("slider","HSlider",Palette.box(Palette.EDGE,3))
	theme.set_stylebox("grabber_area","HSlider",Palette.box(Palette.MINT,3))

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
	parent.add_child(label)
	return label

func panel(parent: Node, rect: Rect2, color: Color = Palette.PANEL, radius: int = 12, border: Color = Palette.EDGE) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.add_theme_stylebox_override("panel",Palette.box(color,radius,border))
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
		b.add_theme_stylebox_override("normal",Palette.box(Palette.MINT,9))
		b.add_theme_stylebox_override("hover",Palette.box(Palette.MINT.lightened(0.12),9))
		b.add_theme_color_override("font_color",Palette.INK)
		b.add_theme_color_override("font_hover_color",Palette.INK)
		b.add_theme_color_override("font_focus_color",Palette.INK)
		b.add_theme_font_override("font",font_bold)
	b.pressed.connect(func():
		audio.play("click")
		action.call()
	)
	b.mouse_entered.connect(func(): animate_button(b,1.018))
	b.mouse_exited.connect(func(): animate_button(b,1.0))
	parent.add_child(b)
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
	icon(ui,"pulse",Rect2(62,47,34,34),Palette.MINT,29)
	label_at(ui,"FIELDWORK DIVISION",Rect2(111,49,290,30),14,Palette.MUTED,true)
	label_at(ui,"EST. TOMORROW",Rect2(1190,48,190,30),12,Palette.MUTED)
	label_at(ui,"A MINESWEEPER EXPEDITION",Rect2(72,206,540,27),15,Palette.MINT,true)
	label_at(ui,"AFTERLIGHT",Rect2(65,235,650,110),78,Palette.WHITE,true)
	paragraph(ui,"One small discovery.\nA world coming back to life.",Rect2(74,357,520,76),26,Palette.MUTED)
	var y := 470.0
	if session != null:
		var continue_button := button(ui,"Continue expedition   →",Rect2(74,y,380,60),start_play,true)
		continue_button.grab_focus()
		label_at(ui,"FIELD %02d  /  %s" % [session.index+1,Content.REGIONS[session.region()].name.to_upper()],Rect2(76,y+69,560,25),13,Palette.MUTED)
		y += 116
	else:
		var begin_button := button(ui,"Begin expedition   →",Rect2(74,y,380,60),new_game,true)
		begin_button.grab_focus()
		y += 81
	button(ui,"Field guide",Rect2(74,y,184,47),show_guide)
	button(ui,"Settings",Rect2(270,y,184,47),show_settings)
	if session != null:
		button(ui,"New expedition",Rect2(74,y+60,184,43),confirm_new_game)
		button(ui,"Credits",Rect2(270,y+60,184,43),show_credits)
	else:
		button(ui,"Credits",Rect2(74,y+62,184,43),show_credits)
		button(ui,"Quit",Rect2(270,y+62,184,43),quit_game)
	rule(ui,Vector2(74,785),520)
	label_at(ui,"READ THE GROUND",Rect2(74,807,190,23),12,Palette.MINT,true)
	label_at(ui,"BUILD YOUR FLEET",Rect2(269,807,190,23),12,Palette.MINT,true)
	label_at(ui,"BRING BACK THE LIGHT",Rect2(465,807,210,23),12,Palette.MINT,true)
	label_at(ui,"v%s  ·  Made for unhurried discovery" % Content.VERSION,Rect2(74,854,590,22),12,Palette.MUTED.darkened(0.15))
	if OS.has_feature("web"):
		label_at(ui,"Saves live in this browser",Rect2(1110,854,260,22),12,Palette.MUTED)

func new_game() -> void:
	session = GameSession.new()
	session.events.clear()
	save_game()
	start_play()
	toast("Welcome, surveyor. Start anywhere — your first opening is always safe.",6)

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
	screen = "play"
	scenery.menu = false
	scenery.region = session.region()
	selected_tool = ""
	build_header()
	build_atlas()
	build_field()
	build_workshop()
	build_fleet()
	build_tools()
	update_hud()
	if session.finished:
		finish_delay = 0.5

func build_header() -> void:
	icon(ui,"pulse",Rect2(30,28,42,42),Palette.MINT,30)
	label_at(ui,"AFTERLIGHT",Rect2(84,24,280,36),27,Palette.WHITE,true)
	label_at(ui,"FIELDWORK DIVISION  /  EXPEDITION %03d" % (session.index+1),Rect2(85,62,430,21),11,Palette.MUTED)
	icon(ui,"prism",Rect2(767,30,34,36),Palette.GOLD,24)
	hud.light = label_at(ui,str(session.credits),Rect2(813,22,160,40),28,Palette.WHITE,true)
	label_at(ui,"COLLECTED LIGHT",Rect2(814,62,177,20),11,Palette.MUTED)
	icon(ui,"cross",Rect2(1024,30,34,36),Palette.MINT,24)
	hud.cores = label_at(ui,str(session.cores),Rect2(1070,22,100,40),28,Palette.WHITE,true)
	label_at(ui,"RESEARCH CORES",Rect2(1071,62,165,20),11,Palette.MUTED)
	button(ui,"II   Pause",Rect2(1270,30,138,48),show_pause)
	rule(ui,Vector2(32,103),1376)

func build_atlas() -> void:
	label_at(ui,"THE RELAY NETWORK",Rect2(32,128,224,24),12,Palette.MUTED,true)
	var current := session.region()
	for i in range(6):
		var y := 176+i*67
		var active := i == current
		var color := Color(Content.REGIONS[i].color) if i <= current else Palette.MUTED.darkened(0.5)
		if active:
			panel(ui,Rect2(32,y-4,224,60),Palette.PANEL_LIGHT,10,color.darkened(0.65))
		icon(ui,"pulse" if i < current else "prism",Rect2(43,y+6,30,30),color,21)
		var region_button := button(ui,Content.REGIONS[i].name,Rect2(82,y,165,30),func(): show_region(i))
		region_button.add_theme_stylebox_override("normal",Palette.box(Color.TRANSPARENT,4))
		region_button.add_theme_font_size_override("font_size",15)
		region_button.add_theme_color_override("font_color",color if active else Palette.MUTED)
		region_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		for n in range(16):
			var completed := session.medals.has(str(i*16+n))
			panel(ui,Rect2(88+n*9,y+38,5,4),color if completed else Palette.EDGE.darkened(0.25),1,Color.TRANSPARENT)
	rule(ui,Vector2(32,608),224)
	label_at(ui,"RESTORATION",Rect2(32,630,224,23),12,Palette.MUTED,true)
	label_at(ui,"%02d / 96" % mini(96,session.medals.size()),Rect2(32,656,224,45),32,Palette.WHITE,true)
	paragraph(ui,"%s\n%s" % [Content.REGIONS[current].rule.to_upper(),Content.REGIONS[current].effect],Rect2(32,723,220,110),14,Palette.MUTED)
	button(ui,"Atlas & records",Rect2(32,847,224,31),show_records)

func build_field() -> void:
	var region_data: Dictionary = Content.REGIONS[session.region()]
	var accent := Color(region_data.color)
	label_at(ui,region_data.tag,Rect2(284,128,740,24),12,accent,true)
	label_at(ui,region_data.name,Rect2(280,158,750,50),36,Palette.WHITE,true)
	hud.field_info = label_at(ui,"FIELD %02d / 16   ·   %s" % [session.index%16+1,Content.title_for(session.index)],Rect2(284,213,750,25),14,Palette.MUTED)
	hud.energy_label = label_at(ui,"",Rect2(846,177,202,30),13,Palette.MINT)
	hud.energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var energy_bar := ProgressBar.new()
	energy_bar.position = Vector2(881,218)
	energy_bar.show_percentage = false
	energy_bar.add_theme_stylebox_override("background",Palette.box(Palette.EDGE,3))
	energy_bar.add_theme_stylebox_override("fill",Palette.box(accent,3))
	energy_bar.size = Vector2(164,7)
	ui.add_child(energy_bar)
	hud.energy_bar = energy_bar
	board_view = BoardView.new()
	board_view.position = Vector2(280,257)
	board_view.size = Vector2(768,462)
	board_view.session = session
	board_view.motion = settings.motion
	board_view.high_contrast = settings.contrast
	board_view.cell_pressed.connect(on_cell)
	board_view.cell_hovered.connect(on_hover)
	ui.add_child(board_view)
	panel(ui,Rect2(280,733,768,45),Palette.PANEL,9)
	icon(ui,"prism",Rect2(293,742,24,24),accent,17)
	hud.progress = label_at(ui,"",Rect2(328,741,240,28),15,Palette.WHITE)
	hud.chain = label_at(ui,"",Rect2(590,741,192,28),15,accent)
	hud.strikes = label_at(ui,"",Rect2(810,741,222,28),15,Palette.MUTED)
	hud.instruction = label_at(ui,"",Rect2(284,865,760,25),13,Palette.MUTED)

func build_workshop() -> void:
	label_at(ui,"THE WORKSHOP",Rect2(1072,128,336,25),12,Palette.MUTED,true)
	label_at(ui,"Make light work.",Rect2(1072,158,336,45),27,Palette.WHITE,true)
	for i in range(3):
		var b := button(ui,["Tools","Fleet","Systems"][i],Rect2(1072+i*114,215,108,38),func():
			shop_group = i
			rebuild_shop()
		)
		b.name = "ShopTab%d" % i
		if i == shop_group:
			b.add_theme_stylebox_override("normal",Palette.box(Palette.MINT.darkened(0.72),7,Palette.MINT.darkened(0.35)))
	var scroll := ScrollContainer.new()
	scroll.name = "ShopScroll"
	scroll.position = Vector2(1072,266)
	scroll.size = Vector2(336,391)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_theme_stylebox_override("panel",Palette.box(Color.TRANSPARENT))
	ui.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",10)
	scroll.add_child(column)
	shop_buttons.clear()
	var items := Content.UPGRADES.duplicate()
	items.sort_custom(func(a,b):
		if session.has(a.id) != session.has(b.id):
			return not session.has(a.id)
		return a.rank < b.rank
	)
	for item in items:
		if int(item.group) != shop_group:
			continue
		var card := Panel.new()
		card.custom_minimum_size = Vector2(320,156)
		card.add_theme_stylebox_override("panel",Palette.box(Palette.PANEL,10,Palette.EDGE))
		column.add_child(card)
		icon(card,item.icon,Rect2(14,13,30,30),Palette.MINT if not session.has(item.id) else Palette.MUTED,22)
		label_at(card,item.name,Rect2(55,12,255,32),18,Palette.WHITE,true)
		paragraph(card,item.desc,Rect2(16,50,286,58),14,Palette.MUTED)
		var purchase := button(card,"",Rect2(15,117,287,28),func(): purchase_upgrade(item.id))
		purchase.add_theme_font_size_override("font_size",13)
		shop_buttons[item.id] = purchase
	update_shop()

func rebuild_shop() -> void:
	for name_value in ["ShopScroll","ShopTab0","ShopTab1","ShopTab2"]:
		var node := ui.get_node_or_null(name_value)
		if node:
			ui.remove_child(node)
			node.queue_free()
	# Only rebuild the scroll and tabs; labels are retained.
	var old_count := ui.get_child_count()
	build_workshop()
	# Remove the duplicated static title labels created by the shared builder.
	for i in range(2):
		var node := ui.get_child(old_count)
		ui.remove_child(node)
		node.queue_free()

func build_fleet() -> void:
	panel(ui,Rect2(1072,676,336,180),Palette.PANEL,12)
	icon(ui,"drone",Rect2(1088,693,42,42),Palette.MINT,28)
	hud.fleet_title = label_at(ui,"",Rect2(1142,690,244,30),19,Palette.WHITE,true)
	hud.fleet_status = paragraph(ui,"",Rect2(1142,725,244,44),14,Palette.MUTED)
	hud.fleet_button = button(ui,"",Rect2(1088,791,305,43),toggle_drones)
	label_at(ui,"ESC  pause  ·  F1  guide  ·  F10  report",Rect2(1072,867,340,22),11,Palette.MUTED)

func build_tools() -> void:
	var ids := ["probe","cross","line","nova"]
	for i in range(4):
		var id: String = ids[i]
		var b := button(ui,"",Rect2(280+i*195,794,183,56),func(): select_tool(id))
		b.add_theme_font_size_override("font_size",15)
		tool_buttons[id] = b

func update_hud() -> void:
	if screen != "play" or session == null or hud.is_empty():
		return
	hud.light.text = format_number(session.credits)
	hud.cores.text = str(session.cores)
	hud.energy_label.text = "ENERGY  %d / %d" % [int(session.energy),int(session.capacity())]
	hud.energy_bar.max_value = session.capacity()
	hud.energy_bar.value = session.energy
	var b := session.board
	hud.progress.text = "%d / %d surveyed" % [b.open_count(),b.width*b.height-b.mine_count]
	hud.chain.text = "CHAIN ×%d  ·  %d" % [session.multiplier(),session.chain] if session.has("chain") else "%d charges  ·  %d flags" % [b.mine_count,b.cells.count(MineBoard.FLAG)]
	hud.strikes.text = "CLEAN FIELD" if session.strikes == 0 else "%d strike%s · still safe to finish" % [session.strikes,"s" if session.strikes != 1 else ""]
	hud.strikes.add_theme_color_override("font_color",Palette.MINT if session.strikes == 0 else Palette.CORAL)
	hud.strikes.add_theme_font_size_override("font_size",14 if session.strikes == 0 else 12)
	if selected_tool != "":
		hud.instruction.text = "Aim %s at covered ground  ·  costs %d energy  ·  Esc cancels" % [Content.upgrade(selected_tool).name,int(session.tool_cost(selected_tool))]
	elif not b.generated:
		hud.instruction.text = "Click anywhere to begin. Your first opening is always safe."
	elif settings.flag_mode:
		hud.instruction.text = "FLAG MODE  ·  Click to mark  ·  F toggles back to reveal  ·  Arrows + Space / F"
	else:
		hud.instruction.text = "Click reveal / chord   ·   Right-click flag   ·   Space probe   ·   F flag mode"
	tool_buttons.probe.text = "1  Pulse  ·  READY" if session.probe_charge >= 1 else "1  Pulse  ·  %ds" % ceili((1-session.probe_charge)*9)
	tool_buttons.probe.disabled = session.probe_charge < 1 or session.finished
	if session.finished:
		tool_buttons.probe.text = "Field restored   →"
		tool_buttons.probe.disabled = false
		hud.instruction.text = "Survey complete. Install equipment, then select Field restored to continue."
	for id in ["cross","line","nova"]:
		var number: int = {"cross":2,"line":3,"nova":4}[id]
		var title: String = {"cross":"Crossbeam","line":"Horizon","nova":"Nova"}[id]
		tool_buttons[id].text = "%d  %s  ·  %d" % [number,title,int(session.tool_cost(id))] if session.has(id) else "%s  ·  locked" % title
		tool_buttons[id].disabled = not session.has(id) or session.energy < session.tool_cost(id) or session.finished
		tool_buttons[id].tooltip_text = Content.upgrade(id).desc
		tool_buttons[id].add_theme_stylebox_override("normal",Palette.box(Palette.MINT.darkened(0.68) if selected_tool==id else Palette.PANEL_LIGHT,9,Palette.MINT if selected_tool==id else Palette.EDGE))
	hud.fleet_title.text = "%d drone%s online" % [session.drone_count(),"s" if session.drone_count()!=1 else ""] if session.has("drone") else "A little help, soon."
	hud.fleet_status.text = "%s\nEnergy  %d / %d" % [session.drone_status if session.drones_enabled else "Fleet resting",int(session.energy),int(session.capacity())]
	if session.has("overdrive"):
		hud.fleet_button.text = "5  Overdrive  ·  12 energy" if session.overclock <= 0 else "OVERDRIVE  ·  %ds" % ceili(session.overclock)
	else:
		hud.fleet_button.text = "Rest fleet" if session.has("drone") and session.drones_enabled else ("Launch fleet" if session.has("drone") else "View fleet upgrades  →")
	board_view.active_tool = selected_tool
	board_view.blocked = modal_kind != "" or session.finished
	update_shop()

func update_shop() -> void:
	for id in shop_buttons:
		var item := Content.upgrade(id)
		var b: Button = shop_buttons[id]
		var reason := session.unlock_reason(item)
		b.disabled = reason != "READY TO INSTALL"
		b.tooltip_text = reason + "\n" + item.desc
		if reason == "INSTALLED":
			b.text = "✓  INSTALLED"
		elif session.index < int(item.rank) or (item.pre != "" and not session.has(item.pre)):
			b.text = reason
		else:
			b.text = "%s light   /   %d cores   →" % [format_number(item.cost),item.cores]
			b.add_theme_color_override("font_color",Palette.MINT)
			if not b.disabled:
				b.add_theme_stylebox_override("normal",Palette.box(Palette.MINT.darkened(0.78),6,Palette.MINT.darkened(0.35)))

func on_cell(i: int, right: bool) -> void:
	if modal_kind != "" or session.finished:
		return
	if right or (settings.flag_mode and selected_tool == ""):
		session.flag(i)
	elif selected_tool != "":
		if session.use_tool(selected_tool,i):
			selected_tool = ""
	else:
		session.reveal(i)
	after_action()

func on_hover(i: int) -> void:
	if session == null or i < 0 or not session.has("lens"):
		return
	var b := session.board
	if b.cells[i] == MineBoard.OPEN and b.clues[i] > 0 and selected_tool == "":
		var flags := 0
		for n in b.neighbours(i):
			flags += 1 if b.cells[n] in [MineBoard.FLAG,MineBoard.HIT] else 0
		hud.instruction.text = "This %d touches %d charges. You marked %d. %s" % [b.clues[i],b.clues[i],flags,"Click to chord." if flags==b.clues[i] else "Check the outlined neighbours."]

func select_tool(id: String) -> void:
	if session.finished:
		show_completion()
		return
	if id == "probe":
		session.use_tool("probe")
	elif session.has(id):
		selected_tool = "" if selected_tool == id else id
	after_action()

func purchase_upgrade(id: String) -> void:
	if session.buy(id):
		rebuild_shop()
		after_action()
		save_game()

func toggle_drones() -> void:
	if not session.has("drone"):
		shop_group = 1
		rebuild_shop()
	elif session.has("overdrive"):
		session.use_tool("overdrive")
		after_action()
	else:
		session.drones_enabled = not session.drones_enabled
		update_hud()
		mark_save()

func after_action() -> void:
	consume_events()
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
					effects.burst(p,Palette.MINT,mini(event.cells.size()*2+3,18),Vector2(795,45))
					audio.play("reveal",pow(2,float(mini(event.chain,16)%5)/12))
			"strike":
				var p := board_view.position+board_view.cell_position(event.cell)
				board_view.shake = 3
				effects.burst(p,Palette.CORAL,18)
				effects.ring(p,Palette.CORAL)
				audio.play("strike")
				toast("Soft landing absorbed the shock. Keep exploring." if event.protected else "Charge struck. Your earnings are safe — keep exploring.")
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
				effects.burst(Vector2(1230,380),Palette.GOLD,30)
				toast("Installed: " + Content.upgrade(event.id).name + ". " + Content.upgrade(event.id).desc,5)
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

func save_game() -> void:
	if session == null:
		return
	if store.write_session(session):
		save_status = "All progress saved"
	else:
		save_status = "Save needs attention"
		toast(store.last_error,8)
	autosave_clock = 0
	save_pending = false

func toast(message: String, duration: float = 3.5) -> void:
	wipe(toast_layer)
	toast_time = duration
	toast_layer.modulate.a = 1
	panel(toast_layer,Rect2(308,107,824,62),Palette.PANEL_LIGHT,12,Palette.MINT.darkened(0.4))
	paragraph(toast_layer,message,Rect2(331,118,778,46),16,Palette.WHITE)

func dialog(title: String, dimensions: Vector2, kind: String) -> Panel:
	close_modal()
	toast_time = 0
	wipe(toast_layer)
	modal_kind = kind
	var dim := ColorRect.new()
	dim.color = Color(0.015,0.035,0.045,0.86)
	dim.size = Vector2(1440,900)
	dim.mouse_filter = MOUSE_FILTER_STOP
	modal.add_child(dim)
	var p := panel(modal,Rect2((Vector2(1440,900)-dimensions)/2,dimensions),Palette.PANEL,18,Palette.EDGE.lightened(0.10))
	p.mouse_filter = MOUSE_FILTER_STOP
	label_at(p,title,Rect2(38,28,dimensions.x-125,50),30,Palette.WHITE,true)
	button(p,"×",Rect2(dimensions.x-71,31,38,38),close_modal)
	rule(p,Vector2(38,87),dimensions.x-76)
	if board_view:
		board_view.blocked = true
	return p

func close_modal() -> void:
	wipe(modal)
	modal_kind = ""
	if board_view:
		board_view.blocked = session.finished

func show_pause() -> void:
	if screen != "play":
		return
	save_game()
	var p := dialog("Take a breath.",Vector2(540,594),"pause")
	label_at(p,"The world can wait. "+save_status+".",Rect2(38,106,468,36),16,Palette.MUTED)
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
	var p := dialog("Make yourself comfortable.",Vector2(690,706),"settings")
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
		var toggle := CheckButton.new()
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
	paragraph(p,"Motion at 0 removes shake, drifting and reveal movement.\nAll settings save immediately.",Rect2(38,586,614,56),14)
	button(p,"Done",Rect2(474,641,178,40),close_modal,true)

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
	var p := dialog("A surveyor's field guide",Vector2(820,708),"guide")
	for i in range(3):
		button(p,["01  Read the ground","02  Tools & energy","03  Build a fleet"][i],Rect2(38+i*252,109,240,41),func(): show_guide(i),i==page)
	var title: String
	var body: String
	var tip: String
	if page == 0:
		title = "The number is a promise."
		body = "A number counts hidden charges in the eight tiles touching it, including diagonals. A 1 means exactly one neighbouring charge. Empty ground spreads open automatically.\n\nLeft-click to reveal. Right-click to place or remove a flag. When a number has the right number of flags around it, click it again to open its remaining neighbours: that is a chord. Wrong flags make chords dangerous.\n\nYour first opening is always safe. Later, use the free Pulse when the clues leave you uncertain. Charges break a chain and lower your field rating, but you keep all your light and can always finish."
		tip = "Arrows select a tile. Enter or Space reveals; F flags the selected tile. With no keyboard selection, Space pulses and F toggles click-to-flag mode."
	elif page == 1:
		title = "Give a good idea more reach."
		body = "Pulse opens guaranteed safe ground. It recharges in nine seconds; each manual reveal also fills it. There is no penalty for using it.\n\nCrossbeam sweeps a cross. Horizon sweeps a row. Nova sweeps a 5 × 5 area. Select a tool, then click the field to aim. These tools skip charges. Press Esc to cancel aiming.\n\nTools cost energy. Safe manual reveals and a slow passive recharge replenish it. Pockets can refill it after the Seed capacitor upgrade. Energy starts full on each expedition.\n\nChain reactor rewards deliberate manual play. Chains have no countdown. Think for as long as you need."
		tip = "1 Pulse    2 Crossbeam    3 Horizon    4 Nova    5 Overdrive\nNumbers refer to keyboard shortcuts; tool buttons show their energy cost."
	else:
		title = "First a companion. Eventually, a constellation."
		body = "Scout drones open cells proven safe by visible clues. Cartographers also mark proven charges. A pattern engine compares overlapping groups of clues. Your flags never mislead the fleet.\n\nIf a drone waits, it needs new information. Reveal a tile, chord, or use Pulse. The Oracle upgrade spends energy to find openings when logic stalls. Wingmate, Fleet and Swarm add more workers.\n\nFinishing a field earns research cores. Restore all sixteen fields in a region to wake its relay and receive a larger reward. Six regions lead to the Dawn Engine, then endless exploration.\n\nThree stars: no strikes. Two: at most two. One: you persevered. Equipment does not reduce your rating."
		tip = "Mastery trials unlock after each restored relay. They offer denser puzzles and extra research cores. Fleet liveries unlock at 48 and 144 stars."
	label_at(p,title,Rect2(38,175,745,50),26,Palette.WHITE,true)
	paragraph(p,body,Rect2(38,240,744,326),18,Palette.MUTED)
	panel(p,Rect2(38,588,744,81),Palette.PANEL_LIGHT,10)
	paragraph(p,tip,Rect2(54,602,710,62),15,Palette.MINT)

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
	var p := dialog("Morning, at last." if ending else ("Relay restored." if region_end else "A little more light."),Vector2(742,666),"complete")
	# Completion is a persistent state; closing is allowed for shopping, and the
	# Continue button on the field will reopen it.
	var accent := Color(Content.REGIONS[session.region()].color)
	label_at(p,"%s  /  FIELD %02d" % [Content.REGIONS[session.region()].name.to_upper(),session.index%16+1],Rect2(38,112,666,30),13,accent,true)
	label_at(p,"✦  " .repeat(int(reward.rating)),Rect2(38,157,666,66),46,Palette.GOLD,true)
	label_at(p,["","Every discovery counts.","A steady hand.","A flawless survey."][int(reward.rating)],Rect2(38,227,666,43),25,Palette.WHITE,true)
	var narrative: String = Content.REGIONS[session.region()].end if region_end else Content.TRANSMISSIONS[session.index%Content.TRANSMISSIONS.size()].split("|")[1]
	paragraph(p,narrative,Rect2(38,285,666,100),19,Palette.MUTED)
	panel(p,Rect2(38,403,666,88),Palette.PANEL_LIGHT,11)
	label_at(p,"+%s" % format_number(reward.earned),Rect2(59,411,260,43),29,Palette.GOLD,true)
	label_at(p,"LIGHT THIS FIELD",Rect2(61,457,250,21),11,Palette.MUTED)
	label_at(p,"+%d" % reward.cores,Rect2(390,411,260,43),29,accent,true)
	label_at(p,"RESEARCH CORES",Rect2(392,457,250,21),11,Palette.MUTED)
	button(p,"Visit workshop",Rect2(38,530,253,58),close_modal)
	var next := button(p,"Explore beyond dawn   →" if ending else ("Return from trial   →" if session.trial>=0 else ("Follow the next signal   →" if region_end else "Next field   →")),Rect2(309,530,395,58),next_expedition,true)
	next.grab_focus()
	label_at(p,"Progress saved  ·  %d:%02d in the field" % [int(reward.seconds)/60,int(reward.seconds)%60],Rect2(38,611,666,25),13,Palette.MUTED)

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
	var p := dialog("The atlas of small victories",Vector2(884,750),"records")
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
	var p := dialog("Made for the small discoveries.",Vector2(750,614),"credits")
	label_at(p,"AFTERLIGHT",Rect2(38,115,674,60),43,Palette.WHITE,true)
	paragraph(p,"An original incremental puzzle expedition.\nAll artwork is drawn with geometry. The soundtrack and sound effects are synthesized from oscillators and envelopes. No generated image or audio assets are used.\n\nBuilt with Godot Engine 4.7 (MIT licence). Typography uses Godot's bundled Noto Sans (SIL Open Font License).\n\nInspired by the language of Minesweeper, quiet science fiction, and the pleasure of watching small machines learn.\n\nGame-feel research: Martin Jonasson & Petri Purho's Juice It or Lose It; Jan Willem Nijman's The Art of Screenshake.",Rect2(38,196,674,322),18,Palette.MUTED)
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

func _unhandled_key_input(event: InputEvent) -> void:
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
			close_modal()
		elif selected_tool != "":
			selected_tool = ""
			update_hud()
		elif screen == "play":
			show_pause()
		return
	if modal_kind != "":
		return
	if event.keycode == KEY_F1:
		show_guide()
		return
	if screen != "play":
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
		on_cell(board_view.keyboard_cell,false)
	elif event.keycode == KEY_SPACE or event.keycode == KEY_1:
		select_tool("probe")
	elif event.keycode == KEY_F:
		if board_view.keyboard_cell >= 0:
			on_cell(board_view.keyboard_cell,true)
		else:
			settings.flag_mode = not settings.flag_mode
			store.write_settings(settings)
			update_hud()
	elif event.keycode in [KEY_2,KEY_3,KEY_4]:
		select_tool({KEY_2:"cross",KEY_3:"line",KEY_4:"nova"}[event.keycode])
	elif event.keycode == KEY_5 and session.has("overdrive"):
		session.use_tool("overdrive")
		after_action()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and not visual_test and settings.get("auto_pause",true) and screen == "play" and modal_kind == "":
		show_pause()

func quit_game() -> void:
	save_game()
	store.write_settings(settings)
	if not OS.has_feature("web"):
		get_tree().quit()
	else:
		show_menu()

func format_number(value: int) -> String:
	if value < 10000:
		return str(value)
	return "%.1fk" % (float(value)/1000)
