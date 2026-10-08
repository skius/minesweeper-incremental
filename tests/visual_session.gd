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

func run(root_app: Control) -> void:
	app = root_app
	DirAccess.make_dir_recursive_absolute("res://test_runs/shots")
	app.session = null
	app.show_menu()
	await shot("v2_01_desktop")
	await click(Vector2(390,450))
	check(app.screen=="play","new expedition via native button")
	check(app.tool_buttons.is_empty() and not app.hud.has("grow"),"opening exposes only the field")
	check(app.ui.find_children("*","Button",true,false).size()==1,"only one non-board control at the start: pause")
	check(app.session.board.width==6 and app.session.board.height==5,"tiny opening board")
	await shot("v2_02_first_field")
	await click(app.board_view.position+app.board_view.cell_position(15))
	check(app.session.board.generated and app.session.strikes==0,"safe initial native opening")
	check(app.tool_buttons.size()==1,"only Pulse appears after first reveal")
	await shot("v2_03_opening")
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
		check(app.board_view.tooltip_text.contains("neighbouring charge"),"clue explanation available on hover")
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
	app.show_tree()
	await shot("v2_05_first_tree")
	check(app.upgrade_tree.visible_node(Content.upgrade("lens")),"tree begins at origin")
	check(not app.upgrade_tree.visible_node(Content.upgrade("nova")),"distant future upgrades hidden")
	await click(app.tree_detail.global_position+Vector2(150,542))
	check(app.session.has("lens"),"connect origin using native button")
	await shot("v2_06_first_branches")
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
	app.close_modal()
	app.show_guide()
	await shot("v2_09_guide")
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
	await click(Vector2(720,810))
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
	DisplayServer.window_set_size(Vector2i(1920,1080))
	await shot("v2_20_wide_field")
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
	app.store.directory=original_directory
	app.close_modal()
	configure(95)
	app.session.stratum=Content.strata_for(95)-1
	while not app.session.finished:
		app.session.probe_one("tool")
	app.consume_events()
	await frames(90)
	await shot("v2_25_ending")
	app.next_expedition()
	check(app.session.completed_campaign and app.session.index==96,"new campaign ending reaches endless")
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
