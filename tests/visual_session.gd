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

func run(root_app: Control) -> void:
	app = root_app
	DirAccess.make_dir_recursive_absolute("res://test_runs/shots")
	# A fresh in-memory profile avoids altering or depending on a previous run.
	app.session = null
	app.show_menu()
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
	app.close_modal()
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
	await click(Vector2(555,821))
	check(app.selected_tool == "cross","crossbeam selection")
	await click(app.board_view.position+app.board_view.cell_position(18))
	await shot("09_crossbeam")
	app.show_records()
	await shot("10_atlas")
	app.close_modal()
	app.save_game()
	var restored: GameSession = app.store.load_session()
	check(restored != null and restored.board.cells == app.session.board.cells,"native mid-board save")
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
