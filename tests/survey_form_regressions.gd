extends RefCounted

static func run(check: Callable) -> void:
	_check_first_choices(check)
	_check_contracts(check)
	_check_terrain(check)
	_check_drill(check)

static func _check_first_choices(check: Callable) -> void:
	# Every legal first click must fund Lens plus one active play-style choice.
	# The first core makes this a choice; neither path can strand progression.
	for first_cell in range(30):
		var first := GameSession.new()
		first.reveal(first_cell)
		_finish(first)
		check.call(first.finished and first.cores == 1, "first clear awards one choice core at opening%d" % first_cell)
		check.call(first.buy("lens"), "first clear affords origin at opening%d" % first_cell)
		for choice in ["cross", "drone"]:
			var path := GameSession.from_dict(first.to_dict())
			check.call(path != null, "first-choice save is valid")
			if path == null:
				continue
			check.call(path.buy(choice), "first clear immediately affords " + choice)
			var other := "drone" if choice == "cross" else "cross"
			check.call(not path.buy(other), "first clear affords exactly one major style choice")
			path.next_board()
			_finish(path)
			check.call(path.finished and path.buy(other), "second clear can acquire other style after " + choice)
	check.call(Content.upgrade("cross").pre == "lens" and Content.upgrade("cross").rank == 0, "Crossbeam is an immediate root branch")
	check.call(Content.upgrade("drone").rank == 0, "Scout is an immediate root branch")

static func _check_contracts(check: Callable) -> void:
	for field in range(6):
		check.call(Content.contract(field).form == "legacy", "initial field stays familiar%d" % field)
	for field in range(6, 96):
		var previous := ""
		for layer in range(Content.strata_for(field)):
			var spec := Content.contract(field, -1, layer)
			check.call(spec.form in ["shelf", "shaft", "geode"], "authored survey form exists")
			check.call(spec.form != previous, "successive strata visibly change survey form")
			check.call(spec.width <= 26 and spec.height <= 18 and spec.width >= 6 and spec.height >= 6, "survey dimensions stay within readability budget")
			if spec.form == "shelf":
				check.call(spec.width > spec.height, "shelf is wide")
			elif spec.form == "shaft":
				check.call(spec.height > spec.width, "shaft is tall")
			else:
				check.call(spec.width == spec.height, "geode is square")
			previous = spec.form
	for trial in range(12):
		var a := Content.contract(96, trial)
		var b := Content.contract(120, trial)
		check.call(a.form == "legacy" and a.seed == b.seed and a.width == b.width and a.height == b.height, "fixed trials retain their exact geometry/generator")

static func _check_terrain(check: Callable) -> void:
	for seed_value in range(1, 41):
		var reference := MineBoard.new()
		reference.setup(12, 12, 27, seed_value, 2)
		reference.reveal(78)
		for form in ["shelf", "shaft", "geode"]:
			var board := MineBoard.new()
			board.setup(12, 12, 27, seed_value, 2, form)
			board.reveal(78)
			check.call(board.mines == reference.mines and board.clues == reference.clues, "terrain cannot change mine RNG or clues: " + form)
			check.call(board.mines.count(1) == 27 and board.clues[78] == 0, "exact mine count and safe first opening: " + form)
			for n in board.neighbours(78):
				check.call(board.cells[n] == MineBoard.OPEN and board.plates[n] == 0, "first neighbourhood is unplated and open: " + form)
			check.call(MineBoard.validate(board.to_dict()), "all generated clue arithmetic and cell states validate: " + form)
			check.call(board.plates.count(0) < 130 and board.plates.count(0) > 35, "terrain has both excavation and open corridors: " + form)
			check.call(board.pockets.count(1) == roundi(117 * 0.07), "pocket density stays controlled: " + form)
			var deep := MineBoard.new()
			deep.setup(12, 12, 27, seed_value, 5, form)
			deep.reveal(78)
			check.call(deep.mines == board.mines and deep.clues == board.clues and deep.pockets == board.pockets, "plate depth changes no other random stream: " + form)
			var restored := MineBoard.from_dict(JSON.parse_string(JSON.stringify(board.to_dict())))
			check.call(restored != null and restored.survey_form == form and restored.cells == board.cells and restored.plates == board.plates and restored.pockets == board.pockets, "generated form roundtrips exactly: " + form)
			for wrong in ["unknown", "SHELF", "", 0, null, []]:
				var malformed := board.to_dict()
				malformed.form = wrong
				check.call(MineBoard.from_dict(malformed) == null, "unknown/malformed survey form rejected")
			if form in ["shelf", "shaft"]:
				_check_seams(check, board, 78)
			else:
				check.call(board.plates.count(3) > 0, "geode has a thicker core worth a drill")
		var saved_legacy := reference.to_dict()
		saved_legacy.erase("form")
		var old := MineBoard.from_dict(saved_legacy)
		check.call(old != null and old.survey_form == "legacy" and old.mines == reference.mines and old.plates == reference.plates and old.pockets == reference.pockets, "old generated saves retain exact board and terrain")
	var original := MineBoard.new()
	original.setup(7, 7, 10, 2)
	original.reveal(24)
	var historical_mines: Array[int] = [5,7,9,14,27,29,38,42,46,48]
	var historical_pockets: Array[int] = [19,33]
	for i in range(49):
		check.call(original.mines[i] == int(historical_mines.has(i)) and original.pockets[i] == int(historical_pockets.has(i)), "legacy seed2 mine/pocket snapshot unchanged")
	var unopened := MineBoard.new()
	unopened.setup(12, 12, 27, 2, 2)
	var old_unopened_data := unopened.to_dict()
	old_unopened_data.erase("form")
	var old_unopened := MineBoard.from_dict(old_unopened_data)
	unopened.reveal(78)
	old_unopened.reveal(78)
	check.call(old_unopened.mines == unopened.mines and old_unopened.plates == unopened.plates and old_unopened.pockets == unopened.pockets, "old unopened saves retain exact legacy generation")

static func _check_seams(check: Callable, board: MineBoard, first_cell: int) -> void:
	var excluded := board.neighbours(first_cell)
	excluded.append(first_cell)
	var horizontal := board.survey_form == "shelf"
	var outer := board.height if horizontal else board.width
	var inner := board.width if horizontal else board.height
	var bands := 0
	for a in range(outer):
		var state := -1
		for b in range(inner):
			var cell := a * board.width + b if horizontal else b * board.width + a
			if excluded.has(cell):
				continue
			if state < 0:
				state = board.plates[cell]
			check.call(board.plates[cell] == state, "a geological seam stays coherent across its row/column")
		bands += 1 if state > 0 else 0
	check.call(bands >= 2 and bands < outer, "seams preserve readable unplated corridors")

static func _check_drill(check: Callable) -> void:
	var spec := Content.contract(6)
	check.call(spec.form == "shelf" and spec.crust == 2, "first plating introduces meaningful two-hit seams")
	check.call(Content.upgrade("drill").rank == 6 and Content.upgrade("drill").cost == 220, "pick arrives with the first seam")
	var before := GameSession.new()
	before.index = 6
	before.start_board()
	before.board.setup(spec.width, spec.height, spec.mines, spec.seed, spec.crust, spec.form)
	before.reveal(spec.width * (spec.height / 2) + spec.width / 2)
	var target := -1
	for i in range(before.board.cells.size()):
		if before.board.mines[i] == 0 and before.board.cells[i] == MineBoard.HIDDEN and before.board.plates[i] == 2:
			target = i
			break
	check.call(target >= 0, "first seam contains safe excavation work")
	if target < 0:
		return
	var after := GameSession.from_dict(before.to_dict())
	after.upgrades.assign(["lens", "chain"])
	after.credits = 220
	after.cores = 1
	check.call(after.buy("drill"), "pick is purchasable at the seam introduction")
	before.reveal(target)
	after.reveal(target)
	check.call(before.board.cells[target] == MineBoard.HIDDEN and before.board.plates[target] == 1, "ordinary pick visibly chips the new seam")
	check.call(after.board.cells[target] == MineBoard.OPEN and after.board.plates[target] == 0, "Diamond pick makes the same seam a single satisfying hit")

static func _finish(session: GameSession) -> void:
	var guard := 0
	while not session.finished and guard < 1500:
		guard += 1
		if session.layer_ready:
			session.advance_layer()
		else:
			session.probe_one("tool")
