extends Node

var app: Control
var shots: int = 0
var checks: int = 0
var failed: bool = false

func frames(count: int) -> void:
	for _i in range(count):
		await get_tree().process_frame

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed = true
		printerr("FAIL: " + message)

func click(p: Vector2, right: bool = false) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = p
	get_viewport().push_input(motion,true)
	var event := InputEventMouseButton.new()
	event.position = p
	event.button_index = MOUSE_BUTTON_RIGHT if right else MOUSE_BUTTON_LEFT
	event.pressed = true
	get_viewport().push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	get_viewport().push_input(event,true)
	await frames(4)

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	get_viewport().push_input(event,true)
	await frames(3)
	event = event.duplicate()
	event.pressed = false
	get_viewport().push_input(event,true)

func shot(name_value: String) -> void:
	await frames(30)
	check_layout(app.ui,name_value)
	check_layout(app.modal,name_value)
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := "res://test_runs/shots/"+name_value+".png"
	check(image.save_png(path) == OK,"screenshot "+name_value)
	shots += 1
	if name_value == "08_midgame":
		var dump: Array[String] = []
		for child in app.ui.get_children():
			if child is Control:
				dump.append("%s %s %s" % [child.get_class(),child.get_global_rect(),child.text if child is Label else ""])
		var file := FileAccess.open("res://test_runs/layout.txt",FileAccess.WRITE)
		file.store_string("\n".join(dump))
		file.close()

func check_layout(node: Node, shot_name: String) -> void:
	if node is Label and node.has_meta("layout_height") and node.autowrap_mode != TextServer.AUTOWRAP_OFF:
		check(node.size.y <= float(node.get_meta("layout_height"))+2,"text fits in "+shot_name+": "+node.text.left(35))
	for child in node.get_children():
		check_layout(child,shot_name)

func check_field_spacing() -> void:
	var buttons: Array=app.ui.find_children("*","Button",true,false).filter(func(b): return b.is_visible_in_tree())
	for i in range(buttons.size()):
		for j in range(i+1,buttons.size()):
			check(not buttons[i].get_global_rect().intersects(buttons[j].get_global_rect()),"field buttons have separate hit areas: %s / %s" % [buttons[i].tooltip_text,buttons[j].tooltip_text])
	if app.hud.has("currency"):
		check(is_equal_approx(app.hud.currency.get_global_rect().get_center().x,app.size.x/2),"currency uses the field centre axis")
	if app.hud.has("equipment"):
		check(is_equal_approx(app.hud.equipment.get_global_rect().get_center().x,app.size.x/2),"equipment uses the field centre axis")
		check(is_equal_approx(app.hud.equipment.position.y-app.board_view.get_global_rect().end.y,16),"field and equipment have a consistent 16px gap")
	for id in app.tool_buttons:
		var glyph: Glyph=app.tool_buttons[id].get_child(0)
		var price: Label=app.hud["charge_"+id]
		check(not glyph.get_global_rect().intersects(price.get_global_rect()),"tool art never overlaps its price: "+id)
		check(glyph.mounted,"tool symbol has a dedicated instrument well: "+id)
	if app.hud.has("energy"):
		for tool in app.tool_buttons.values():
			check(tool.get_global_rect().position.y-app.hud.energy.get_global_rect().end.y>=8,"energy and tools have breathing room")

func run(root_app: Control) -> void:
	app = root_app
	DirAccess.make_dir_recursive_absolute("res://test_runs/shots")
	app.session = null
	app.show_menu()
	await shot("v2_01_desktop")
	await click(Vector2(390,450))
	check(app.screen=="play","new expedition via native button")
	check(app.tool_buttons.is_empty() and not app.hud.has("grow"),"opening exposes only the field")
	check(app.ui.find_children("*","Button",true,false).size()==2,"opening has only pause and optional field legend")
	check(app.session.board.width==6 and app.session.board.height==5,"tiny opening board")
	await key(KEY_L)
	check(app.modal_kind=="legend","keyboard opens optional field legend")
	await shot("v4_40_start_legend")
	await key(KEY_L)
	check(app.modal_kind=="","legend shortcut returns to field")
	await shot("v2_02_first_field")
	await click(app.board_view.position+app.board_view.cell_position(15))
	check(app.session.board.generated and app.session.strikes==0,"safe initial native opening")
	check(app.tool_buttons.size()==1,"only Pulse appears after first reveal")
	await shot("v2_03_opening")
	check(app.hud.has("flag_mode"),"flag mode becomes discoverable after first opening")
	await click(app.hud.flag_mode.global_position+app.hud.flag_mode.size/2)
	check(app.settings.flag_mode,"native flag control enables flagging")
	await click(app.hud.flag_mode.global_position+app.hud.flag_mode.size/2)
	check(not app.settings.flag_mode,"native flag control returns to revealing")
	var hovered_clue := -1
	for i in range(app.session.board.cells.size()):
		if app.session.board.cells[i]==MineBoard.OPEN and app.session.board.clues[i]>0:
			hovered_clue=i
			break
	if hovered_clue>=0:
		var mouse := InputEventMouseMotion.new()
		mouse.position=app.board_view.position+app.board_view.cell_position(hovered_clue)
		get_viewport().push_input(mouse,true)
		await frames(70)
		check(app.board_view.hover==hovered_clue and app.board_view.tooltip_text.is_empty(),"clue inspection uses footer without covering neighbours")
		await shot("v2_26_clue_hover")
	var safety := 0
	while not app.session.finished and safety<100:
		safety+=1
		var moves: Dictionary=app.session.board.deductions(true)
		if not moves.safe.is_empty():
			await click(app.board_view.position+app.board_view.cell_position(moves.safe[0]))
		else:
			app.session.probe_charge=1
			app.session.use_tool("probe")
			app.after_action()
	check(app.session.finished,"small field completed")
	await frames(90)
	await shot("v2_04_first_clear")
	app.close_modal()
	app.tree_selected="legacy"
	app.show_tree()
	check(app.upgrade_tree.chosen=="lens","a remembered future selection cannot bypass disclosure")
	await shot("v2_05_first_tree")
	check(app.upgrade_tree.visible_node(Content.upgrade("lens")),"tree begins at origin")
	check(not app.upgrade_tree.visible_node(Content.upgrade("nova")),"distant future upgrades hidden")
	for item in Content.UPGRADES:
		check(not app.upgrade_tree.visible_node(item) if item.rank>app.session.index else true,"future field gates never appear: "+item.id)
	await click(app.tree_detail.global_position+Vector2(150,542))
	check(app.session.has("lens"),"connect origin using native button")
	await shot("v2_06_first_branches")
	await click(app.upgrade_tree.global_position+app.upgrade_tree.center_for("cross"))
	check(app.tree_selected=="cross" and app.upgrade_tree.chosen=="cross","click pins tree selection")
	var tree_hover := InputEventMouseMotion.new()
	tree_hover.position=app.upgrade_tree.global_position+app.upgrade_tree.center_for("drone")
	get_viewport().push_input(tree_hover,true)
	await frames(4)
	check(app.upgrade_tree.hovered=="drone" and app.tree_selected=="cross","hovering a different upgrade does not replace selection")
	check(app.shop_buttons.cross==app.tree_detail.find_children("*","Button",true,false)[0],"purchase button remains bound to the clicked upgrade")
	await shot("v5_41_tree_pinned")
	await click(app.shop_buttons.cross.global_position+app.shop_buttons.cross.size/2)
	check(app.session.has("cross") and not app.session.has("drone"),"crossing other nodes en route to purchase buys pinned selection")
	check(app.tree_selected=="cross","purchase retains selected node")
	await key(KEY_ESCAPE)
	app.next_expedition()
	await key(KEY_ESCAPE)
	check(app.modal_kind=="pause","Escape pauses")
	var elapsed: float=app.session.play_seconds
	await frames(80)
	check(elapsed==app.session.play_seconds,"modal freezes active game")
	await shot("v2_07_pause")
	app.show_settings()
	await shot("v2_08_settings")
	for _step in range(18):
		await key(KEY_TAB)
		var owner := get_viewport().gui_get_focus_owner()
		check(owner!=null and app.modal.is_ancestor_of(owner),"settings keyboard focus stays inside the modal")
	var charge_before: float=app.session.probe_charge
	app.select_tool("probe")
	check(app.session.probe_charge==charge_before,"background tool activation is guarded while modal is open")
	await key(KEY_ESCAPE)
	check(app.modal_kind=="pause","closing settings returns to pause")
	await key(KEY_ESCAPE)
	check(app.modal_kind=="","closing pause returns to field")
	app.show_guide()
	await shot("v2_09_guide")
	app.close_modal()
	configure(1)
	await click(app.board_view.global_position+app.board_view.cell_position(24))
	app.select_tool("cross")
	var early_aim := InputEventMouseMotion.new()
	early_aim.position=app.board_view.global_position+app.board_view.cell_position(18)
	get_viewport().push_input(early_aim,true)
	await shot("v4_36_early_aim")
	check_field_spacing()
	app.show_legend()
	await shot("v4_38_early_legend")
	check(app.modal_kind=="legend" and not app.modal.find_children("*","Label",true,false).any(func(label): return label.text=="Plating"),"legend hides unencountered plating")
	app.close_modal()
	# A fully connected early build in the first plated site.
	configure(10)
	await click(app.board_view.position+app.board_view.cell_position(30))
	await frames(50)
	await shot("v2_10_early_equipment")
	await key(KEY_TAB)
	check(app.modal_kind=="tree","Tab opens tree")
	await shot("v2_11_early_tree")
	await key(KEY_ESCAPE)
	await key(KEY_RIGHT)
	check(app.board_view.keyboard_cell>=0,"keyboard can reach board after tree")
	configure(38)
	await click(app.board_view.position+app.board_view.cell_position(65))
	await shot("v2_12_excavation")
	await key(KEY_2)
	check(app.selected_tool=="cross","crossbeam is aimable")
	check(app.hud.has("energy") and app.hud.energy.cost==6,"aiming a beam quotes energy beside the tool dock")
	await click(app.board_view.position+app.board_view.cell_position(95))
	check(app.session.strikes==0,"beam preserves safe excavation")
	await shot("v2_13_beam")
	app.show_tree()
	app.tree_focus("perforator")
	await shot("v2_14_mid_tree")
	app.close_modal()
	app.select_tool("probe")
	check(app.selected_tool=="probe","focused Pulse becomes an aimed tool")
	await click(app.board_view.position+app.board_view.cell_position(12))
	check(app.selected_tool=="" and app.session.strikes==0,"focused Pulse input opens safe ground")
	app.session.drones_enabled=false
	while not app.session.layer_ready:
		app.session.probe_one("tool")
	app.consume_events()
	await frames(5)
	await shot("v2_15_descent")
	var saved_layer: int=app.session.stratum
	await click(app.hud.descend.global_position+app.hud.descend.size/2)
	check(app.session.stratum==saved_layer+1,"native descent advances exactly one stratum")
	app.save_game()
	var restored: GameSession=app.store.load_session()
	check(restored!=null and restored.stratum==app.session.stratum and restored.board.plates==app.session.board.plates,"native plated/depth save roundtrip")
	configure(88)
	await click(app.board_view.position+app.board_view.cell_position(180))
	await frames(110)
	await shot("v2_16_fleet")
	app.show_tree()
	app.tree_focus("legacy")
	await shot("v2_17_full_tree")
	for item in Content.UPGRADES:
		app.tree_focus(item.id)
		await frames(2)
		check_layout(app.tree_detail,item.id)
	app.tree_focus("diagonal")
	await frames(95)
	await shot("v2_27_upgrade_preview")
	var motion := InputEventMouseButton.new()
	motion.position=app.upgrade_tree.global_position+app.upgrade_tree.size/2
	motion.button_index=MOUSE_BUTTON_WHEEL_UP
	motion.pressed=true
	var old_zoom: float=app.upgrade_tree.zoom
	get_viewport().push_input(motion,true)
	check(app.upgrade_tree.zoom>old_zoom,"native scroll zooms discovery map")
	await key(KEY_LEFT)
	check(app.upgrade_tree.chosen!="diagonal","keyboard explores a connected map")
	app.upgrade_tree.zoom=0.55
	app.upgrade_tree.pan=Vector2.ZERO
	DisplayServer.window_set_size(Vector2i(960,600))
	await shot("v2_18_small_tree")
	app.close_modal()
	await shot("v2_19_small_field")
	app.select_tool("nova")
	var late_aim := InputEventMouseMotion.new()
	late_aim.position=app.board_view.global_position+app.board_view.cell_position(100)
	get_viewport().push_input(late_aim,true)
	await shot("v4_37_small_aim")
	check(app.hud.charge_nova.text.to_float()==app.hud.energy.cost,"aimed discounted price matches the energy meter")
	check(app.hud.charge_probe.text.begins_with("FREE"),"stored Pulse charges remain explicitly free")
	check_field_spacing()
	await click(app.hud.legend.global_position+app.hud.legend.size/2)
	await shot("v4_39_small_legend")
	check(app.modal_kind=="legend" and app.modal.find_children("*","Label",true,false).any(func(label): return label.text=="Plating"),"field legend explains encountered plating")
	app.close_modal()
	app.selected_tool=""
	app.session.drones_enabled=false
	for _i in range(4):
		await click(app.hud.zoom_in.global_position+app.hud.zoom_in.size/2)
	check(app.board_view.zoom==2,"native zoom control doubles clue size")
	check(app.board_view.tile_size*960.0/app.size.x>=28,"zoom gives readable physical clue tiles at minimum window size")
	app.board_view.keyboard_cell=app.session.board.cells.size()-app.session.board.width-1
	await key(KEY_DOWN)
	check(app.board_view.visible_cell(app.board_view.keyboard_cell),"keyboard navigation pans to keep the selected clue visible")
	var zoom_index: int=app.board_view.keyboard_cell
	check(app.board_view.index_at(app.board_view.cell_position(zoom_index))==zoom_index,"zoomed coordinates map to the correct board cell")
	await shot("v3_33_zoomed_field")
	# Camera gestures must update aim without relying on a later mouse motion.
	var board_view: BoardView=app.board_view
	var pointer: Vector2=board_view.grid_origin+Vector2(board_view.visible_columns,board_view.visible_rows)*board_view.tile_size*0.5
	var wheel := InputEventMouseButton.new()
	wheel.position=board_view.global_position+pointer
	wheel.button_index=MOUSE_BUTTON_WHEEL_UP
	wheel.pressed=true
	get_viewport().push_input(wheel,true)
	wheel=wheel.duplicate()
	wheel.pressed=false
	get_viewport().push_input(wheel,true)
	check(board_view.keyboard_cell==-1 and board_view.hover==board_view.index_at(pointer),"wheel zoom reprojects aim and clears stale keyboard target")
	var clicked: Array[int]=[]
	var record_click := func(cell: int,_right: bool): clicked.append(cell)
	board_view.cell_pressed.connect(record_click)
	var press := InputEventMouseButton.new()
	press.position=wheel.position
	press.button_index=MOUSE_BUTTON_RIGHT
	press.pressed=true
	get_viewport().push_input(press,true)
	press=press.duplicate()
	press.pressed=false
	get_viewport().push_input(press,true)
	check(clicked.size()==1 and clicked[0]==board_view.hover,"click after wheel uses the displayed target without an intervening motion")
	board_view.cell_pressed.disconnect(record_click)
	board_view.keyboard_cell=zoom_index
	press=press.duplicate()
	press.button_index=MOUSE_BUTTON_MIDDLE
	press.pressed=true
	get_viewport().push_input(press,true)
	var pan_motion := InputEventMouseMotion.new()
	pan_motion.position=press.position+Vector2(board_view.tile_size*2,0)
	pan_motion.button_mask=MOUSE_BUTTON_MASK_MIDDLE
	get_viewport().push_input(pan_motion,true)
	press=press.duplicate()
	press.position=pan_motion.position
	press.pressed=false
	get_viewport().push_input(press,true)
	check(not board_view.panning and board_view.keyboard_cell==-1 and board_view.hover==board_view.index_at(press.position-board_view.global_position),"middle pan release preserves correct aim without a later motion")
	board_view.keyboard_cell=zoom_index
	await click(board_view.global_position+board_view.minimap_rect().get_center())
	check(board_view.keyboard_cell==-1 and board_view.hover==-1,"overview navigation clears the old board target")
	await click(app.hud.zoom_fit.global_position+app.hud.zoom_fit.size/2)
	check(app.board_view.zoom==1 and app.board_view.view_offset==Vector2i.ZERO,"fit control restores the complete field: %s / %s" % [app.board_view.zoom,app.board_view.view_offset])
	DisplayServer.window_set_size(Vector2i(1920,1080))
	await shot("v2_20_wide_field")
	check(is_equal_approx(app.size.x/app.size.y,1920.0/1080.0),"16:9 viewport expands without letterboxing")
	check(app.scenery.size==app.size,"wallpaper fills the viewport")
	check(app.board_view.size.x>1084,"field uses the wider viewport")
	app.show_settings()
	await shot("v3_29_wide_settings")
	var dialog_panel: Control=app.modal.get_child(1)
	check(dialog_panel.position.is_equal_approx((app.size-dialog_panel.size)/2),"resized modal remains centred")
	app.close_modal()
	DisplayServer.window_set_size(Vector2i(1600,720))
	await shot("v3_30_ultrawide_field")
	check(is_equal_approx(app.size.x/app.size.y,1600.0/720.0),"ultrawide expands without letterboxing")
	DisplayServer.window_set_size(Vector2i(1920,1080))
	await frames(4)
	var samples: Array[float]=[]
	for frame in range(180):
		var begin:=Time.get_ticks_usec()
		await get_tree().process_frame
		samples.append((Time.get_ticks_usec()-begin)/1000.0)
	samples.sort()
	var report:=FileAccess.open("res://test_runs/performance_v2.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"frames":180,"median_ms":samples[90],"p95_ms":samples[171],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)},"  "))
	report.close()
	DisplayServer.window_set_size(Vector2i(1440,900))
	app.show_records()
	await shot("v2_21_atlas")
	app.show_credits()
	await shot("v2_22_credits")
	app.show_licenses()
	await shot("v2_23_licences")
	app.close_modal()
	# Saving failure still cannot silently quit the new presentation.
	var original_directory: String=app.store.directory
	var blocker_path: String=app.store.path("blocked_directory")
	var blocker:=FileAccess.open(blocker_path,FileAccess.WRITE)
	blocker.store_string("test")
	blocker.close()
	app.store.directory=blocker_path+"/"
	app.quit_game()
	check(app.modal_kind=="save_error","failed save keeps game open")
	await shot("v2_24_save_recovery")
	app.show_settings()
	app.save_settings()
	check(not app.settings_saved and app.settings_retry_button.visible,"failed settings write exposes a retry action")
	check(app.settings_status_label.text.contains("could not"),"settings failure does not claim saved")
	await shot("v3_31_settings_retry")
	app.store.directory=original_directory
	app.save_settings()
	check(app.settings_saved and not app.settings_retry_button.visible,"settings retry succeeds once storage is restored")
	app.close_modal()
	configure(96)
	check(app.session.begin_trial(0),"survey trial opens between sites")
	app.start_play()
	check(app.tool_buttons.keys()==["probe"] and not app.hud.has("energy") and not app.hud.has("fleet_button"),"survey trial only exposes usable equipment")
	await shot("v3_34_survey_trial")
	configure(96)
	check(app.session.begin_trial(11),"final fleet trial opens from completed campaign")
	app.start_play()
	app.session.drones_enabled=false
	await click(app.board_view.global_position+app.board_view.cell_position(247))
	check(app.session.board.width==26 and app.session.board.height==18 and app.session.board.crust==6,"final trial provides campaign-sized plated work")
	await shot("v3_35_final_trial")
	configure(95)
	app.session.stratum=Content.strata_for(95)-1
	while not app.session.finished:
		app.session.probe_one("tool")
	app.consume_events()
	await frames(90)
	app.store.directory=blocker_path+"/"
	app.show_completion()
	var failure_labels: Array=app.modal.find_children("*","Label",true,false)
	var reports_failure := false
	for failure_label in failure_labels:
		reports_failure=reports_failure or failure_label.text.begins_with("Save failed")
	check(reports_failure,"completion keeps save failure visible after opening its dialog")
	await shot("v3_32_completion_retry")
	app.store.directory=original_directory
	app.show_completion()
	await shot("v2_25_ending")
	app.next_expedition()
	check(app.session.completed_campaign and app.session.index==96,"new campaign ending reaches endless")
	app.close_modal()
	app.toast_time=0
	app.wipe(app.toast_layer)
	var atlas := load("res://tests/icon_atlas.gd").new() as Control
	app.modal.add_child(atlas)
	await shot("v3_28_icon_families")
	var icon_image := get_viewport().get_texture().get_image()
	var signatures: Dictionary={}
	for id in atlas.icon_rects:
		var signature: int=hash(icon_image.get_region(atlas.icon_rects[id]).get_data())
		check(not signatures.has(signature),"unique rendered upgrade silhouette: "+id)
		signatures[signature]=id
	check(signatures.size()==50,"every discovery owns a distinct rendered symbol")
	app.wipe(app.modal)
	for page in range(5):
		for after in [false,true]:
			var previews := load("res://tests/preview_atlas.gd").new() as Control
			app.modal.add_child(previews)
			previews.populate(page,after)
			await shot("v3_preview_%d_%s" % [page,"after" if after else "before"])
			app.wipe(app.modal)
	print("AFTERLIGHT %s: %d native input/state checks, %d viewport screenshots" % ["FAIL" if failed else "PASS",checks,shots])
	get_tree().quit(1 if failed else 0)

func configure(index: int) -> void:
	app.close_modal()
	app.session=GameSession.new()
	app.session.index=index
	app.session.credits=2000+index*200
	app.session.cores=14
	for item in Content.UPGRADES:
		if item.rank<=index:
			app.session.upgrades.append(item.id)
	for field in range(index):
		app.session.medals[str(field)]=3
	app.session.start_board()
	app.session.events.clear()
	app.start_play()
