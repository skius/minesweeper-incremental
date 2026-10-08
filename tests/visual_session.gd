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
	# A fresh in-memory profile avoids altering or depending on a previous run.
	app.session = null
	app.show_menu()
	check(absf(app.audio.music_player.stream.get_length()-32.0)<0.01,"procedural music duration survives compression")
	check(app.audio.music_player.stream.loop_end == 705600,"compressed music loops at the full sample length")
	await shot("01_menu")
	await click(Vector2(260,500))
	check(app.screen == "play","menu button begins expedition")
	await shot("02_first_field")
	await click(app.board_view.position+app.board_view.cell_position(27))
	check(app.session.board.generated,"mouse input generates board")
	check(app.session.board.clues[27] == 0,"first reveal safe")
	await frames(90)
	await shot("03_first_opening")
	var unknown := -1
	for i in range(app.session.board.cells.size()):
		if app.session.board.cells[i] == MineBoard.HIDDEN:
			unknown = i
			break
	if unknown >= 0:
		await click(app.board_view.position+app.board_view.cell_position(unknown),true)
		check(app.session.board.cells[unknown] == MineBoard.FLAG,"right click flags")
		await click(app.board_view.position+app.board_view.cell_position(unknown),true)
		check(app.session.board.cells[unknown] == MineBoard.HIDDEN,"right click unflags")
	await key(KEY_ESCAPE)
	check(app.modal_kind == "pause","Escape pauses")
	var before: float = app.session.board_seconds
	await frames(90)
	check(app.session.board_seconds == before,"pause freezes simulation")
	await shot("04_pause")
	app.show_settings()
	await shot("05_settings")
	app.close_modal()
	app.show_guide()
	await shot("06_guide")
	app.show_guide(1)
	await shot("13_guide_tools")
	app.show_guide(2)
	await shot("14_guide_fleet")
	app.show_credits()
	await shot("15_credits")
	app.show_licenses()
	await shot("16_licences")
	app.show_settings()
	# Settings are changed through native GUI input and must persist.
	await click(Vector2(712,526))
	check(app.settings.contrast,"high contrast setting toggles")
	check(app.store.load_settings().contrast,"settings persist immediately")
	app.settings.contrast = false
	app.apply_settings()
	app.store.write_settings(app.settings)
	app.close_modal()
	# Focus must not trap board navigation after a workshop purchase.
	await click(Vector2(1210,398))
	check(app.session.has("lens"),"workshop purchase through UI")
	await key(KEY_RIGHT)
	check(app.board_view.keyboard_cell >= 0,"arrows reach board from button focus")
	var selected: int = app.board_view.keyboard_cell
	app.tool_buttons.probe.grab_focus()
	await key(KEY_RIGHT)
	check(app.board_view.keyboard_cell == selected+1,"arrows escape persistent tool focus")
	await key(KEY_F)
	await key(KEY_F)
	await click(app.board_view.position+app.board_view.cell_position(27))
	# Complete the opening with visible logical moves and guaranteed probes.
	var safety := 0
	while not app.session.finished and safety < 100:
		safety += 1
		var moves: Dictionary = app.session.board.deductions(true)
		if not moves.safe.is_empty():
			await click(app.board_view.position+app.board_view.cell_position(moves.safe[0]))
		else:
			app.session.probe_charge = 1
			await click(Vector2(370,821))
	check(app.session.finished,"native first-field completion")
	await frames(90)
	await shot("07_completion")
	app.next_expedition()
	# Midgame fixture shows the actual upgraded scene and uses actual tool input.
	app.session.index = 35
	app.session.credits = 5600
	app.session.cores = 12
	app.session.upgrades.assign(["lens","probe2","cross","battery","line","drone","flagger","pair","logic","chain","salvage","shield","chord"])
	for i in range(35):
		app.session.medals[str(i)] = 3 if i%4 else 2
	app.session.start_board()
	app.session.events.clear()
	app.start_play()
	await click(app.board_view.position+app.board_view.cell_position(61))
	await frames(100)
	app.shop_group = 1
	app.rebuild_shop()
	await shot("08_midgame")
	DisplayServer.window_set_size(Vector2i(960,600))
	await shot("17_small_window")
	DisplayServer.window_set_size(Vector2i(1920,1080))
	await shot("18_widescreen")
	DisplayServer.window_set_size(Vector2i(1440,900))
	await frames(10)
	await click(Vector2(555,821))
	check(app.selected_tool == "cross","crossbeam selection")
	await click(app.board_view.position+app.board_view.cell_position(18))
	await shot("09_crossbeam")
	app.show_records()
	await shot("10_atlas")
	app.close_modal()
	app.show_trial(0)
	await shot("19_trial_briefing")
	app.close_modal()
	app.show_region(2)
	await shot("20_region")
	app.close_modal()
	app.capture_report()
	await frames(10)
	await shot("21_report")
	await click(Vector2(710,646))
	check(app.modal_kind == "","field report saved through GUI")
	check(DirAccess.dir_exists_absolute(app.store.path("reports")),"local report directory exists")
	app.close_modal()
	app.save_game()
	var restored: GameSession = app.store.load_session()
	check(restored != null and restored.board.cells == app.session.board.cells,"native mid-board save")
	# A failed save must not silently close the game and discard current work.
	var original_directory: String = app.store.directory
	var blocker_path: String = app.store.path("blocked_directory")
	var blocker := FileAccess.open(blocker_path,FileAccess.WRITE)
	blocker.store_string("This is a test file, not a directory.")
	blocker.close()
	app.store.directory = blocker_path+"/"
	app.quit_game()
	check(app.modal_kind == "save_error","failed-save quit keeps game open")
	await shot("22_save_recovery")
	app.store.directory = original_directory
	app.close_modal()
	# Late-game fixture with all equipment and eight solver drones.
	app.session.index = 88
	app.session.credits = 14382
	app.session.cores = 23
	app.session.upgrades.clear()
	for item in Content.UPGRADES:
		app.session.upgrades.append(item.id)
	app.session.start_board()
	app.session.events.clear()
	app.start_play()
	await click(app.board_view.position+app.board_view.cell_position(86))
	await frames(180)
	await shot("11_swarm")
	var sample_times: Array[float] = []
	var process_times: Array[float] = []
	for _frame in range(180):
		var start := Time.get_ticks_usec()
		await get_tree().process_frame
		sample_times.append(float(Time.get_ticks_usec()-start)/1000.0)
		process_times.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
	sample_times.sort()
	process_times.sort()
	var performance := {"frames":180,"uncapped_frame_p50_ms":sample_times[90],"uncapped_frame_p95_ms":sample_times[171],"process_p95_ms":process_times[171],"static_memory_mb":Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
	var performance_file := FileAccess.open("res://test_runs/performance.json",FileAccess.WRITE)
	performance_file.store_string(JSON.stringify(performance,"  "))
	performance_file.close()
	app.session.index = 95
	app.session.start_board()
	app.session.events.clear()
	app.start_play()
	while not app.session.finished:
		app.session.probe_one("tool")
	app.consume_events()
	await frames(90)
	await shot("12_ending")
	app.next_expedition()
	check(app.session.index==96 and app.session.completed_campaign,"campaign transitions to endless")
	print("AFTERLIGHT %s: %d native input/state checks, %d viewport screenshots" % ["FAIL" if failed else "PASS",checks,shots])
	get_tree().quit(1 if failed else 0)
