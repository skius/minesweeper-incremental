extends Node

var app: Control
var last_id: int = -1
var busy: bool = false
var clock: float = 0
var path: String = "res://test_runs/manual/"
var history: Array = []

func run(root_app: Control) -> void:
	app = root_app
	DirAccess.make_dir_recursive_absolute(path)
	app.session = app.store.load_session()
	app.show_menu()
	await capture()

func _process(delta: float) -> void:
	clock += delta
	if app == null or busy or clock < 0.15:
		return
	clock = 0
	if not FileAccess.file_exists(path+"command.json"):
		return
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path+"command.json")) != OK:
		return
	var command = parser.data
	if not command is Dictionary or int(command.get("id",-1)) <= last_id:
		return
	last_id = int(command.id)
	busy = true
	history.append(command)
	match command.get("action",""):
		"drift_fixture":
			app.close_modal()
			app.session=GameSession.new()
			app.session.index=40
			app.session.upgrades.assign(["lens","chording","cross","focus","probe2","ballast","anchor","tracer","battery"])
			app.session.drones_enabled=false
			app.session.credits=0
			app.session.cores=0
			app.session.start_board()
			app.start_play()
		"hover":
			var motion := InputEventMouseMotion.new()
			motion.position=app.board_view.position+app.board_view.cell_position(int(command.cell))
			get_viewport().push_input(motion,true)
		"click":
			var p := Vector2(command.get("x",0),command.get("y",0))
			if command.has("cell") and app.board_view != null:
				p = app.board_view.position+app.board_view.cell_position(int(command.cell))
			var motion := InputEventMouseMotion.new()
			motion.position = p
			get_viewport().push_input(motion,true)
			var event := InputEventMouseButton.new()
			event.position = p
			event.button_index = MOUSE_BUTTON_RIGHT if command.get("right",false) else MOUSE_BUTTON_LEFT
			event.pressed = true
			get_viewport().push_input(event,true)
			event = event.duplicate()
			event.pressed = false
			get_viewport().push_input(event,true)
		"key":
			var event := InputEventKey.new()
			event.keycode = int(command.code)
			event.pressed = true
			get_viewport().push_input(event,true)
			event = event.duplicate()
			event.pressed = false
			get_viewport().push_input(event,true)
		"resize":
			DisplayServer.window_set_size(Vector2i(command.width,command.height))
		"quit":
			var file := FileAccess.open(path+"history.json",FileAccess.WRITE)
			file.store_string(JSON.stringify(history,"  "))
			file.close()
			print("AFTERLIGHT PASS: visual decision playtest, %d actions" % history.size())
			app.quit_game()
			return
	await capture()
	busy = false

func capture() -> void:
	for _i in range(45):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path+"latest.png")
	var visible := {"id":last_id,"screen":app.screen,"modal":app.modal_kind,"tool":app.selected_tool}
	if app.session != null:
		var s: GameSession = app.session
		visible.merge({"drift_wave":s.drift.sequence,"drift_in":s.drift.remaining,"shelter":s.drift.focus,"anchors":s.drift.anchors.count(1),"traces":Array(s.drift.traces),"plates":Array(s.board.plates)})
		visible.merge({"index":s.index,"credits":s.credits,"cores":s.cores,"energy":s.energy,"strikes":s.strikes,"damage":s.damage,"cargo":s.board_earned,"failed":s.failed,"attempt":s.attempt,"finished":s.finished,"upgrades":s.upgrades,"width":s.board.width,"height":s.board.height,"cells":[]})
		for i in range(s.board.cells.size()):
			visible.cells.append(str(s.board.clues[i]) if s.board.cells[i]==MineBoard.OPEN else ("F" if s.board.cells[i]==MineBoard.FLAG else ("X" if s.board.cells[i]==MineBoard.HIT else "?")))
	var file := FileAccess.open(path+"visible.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(visible,"  "))
	file.close()
	var record := FileAccess.open(path+"history.json",FileAccess.WRITE)
	record.store_string(JSON.stringify(history,"  "))
	record.close()
