extends SceneTree

var checks: int = 0
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for seed_value in range(1, 81):
		var b := MineBoard.new()
		b.setup(12, 10, 22, seed_value)
		var opening := (seed_value * 17) % 120
		b.reveal(opening)
		check(b.mines.count(1) == 22, "mine count seed %d" % seed_value)
		check(b.clues[opening] == 0 and b.cells[opening] == MineBoard.OPEN, "safe opening")
		for n in b.neighbours(opening):
			check(b.mines[n] == 0, "safe neighbourhood")
		var clone := MineBoard.from_dict(b.to_dict())
		check(clone != null and clone.cells == b.cells, "board roundtrip")
		var iterations := 0
		while not b.completed() and iterations < 200:
			iterations += 1
			var moves := b.deductions(true)
			for n in moves.safe:
				check(b.mines[n] == 0, "solver never opens mine seed %d" % seed_value)
			for n in moves.mines:
				check(b.mines[n] == 1, "solver never flags safe seed %d" % seed_value)
			if not moves.safe.is_empty():
				b.reveal(moves.safe[0])
			else:
				b.reveal(b.safe_probe())
		check(b.completed(), "all boards completable")
	var s := GameSession.new()
	s.reveal(20)
	var light_before := s.credits
	for i in range(s.board.cells.size()):
		if s.board.cells[i] == MineBoard.HIDDEN:
			s.flag(i)
			s.flag(i)
	check(s.credits == light_before, "flags cannot farm currency")
	for i in range(s.board.cells.size()):
		if s.board.mines[i] == 1:
			s.reveal(i)
	check(s.failed and s.strikes == 2 and s.credits == light_before and s.board_earned==0, "two strikes lose the attempt and cargo, preserving bank")
	check(s.retry_board(),"failed field can be retried immediately")
	while not s.finished:
		s.probe_one("tool")
	check(s.last_reward.rating == 3 and s.cores == 1, "successful retry pays one core")
	var completion_light := s.credits
	s.check_completion()
	s.reveal(0)
	check(s.credits == completion_light, "no duplicate completion payout")
	s.next_board()
	check(s.index == 1 and not s.finished and not s.board.generated, "next expedition")
	s.credits = 1000
	s.cores = 10
	check(not s.buy("nova"), "rank gating")
	s.buy("lens")
	check(s.buy("probe2") and not s.buy("probe2"), "buy exactly once")
	s.use_tool("probe")
	check(not s.use_tool("probe"), "probe cooldown enforced")
	s.tick(9)
	check(s.probe_charge == 1, "probe regenerates")
	var unsafe_flag := s.board.safe_probe()
	s.flag(unsafe_flag)
	var moves := s.board.deductions(true)
	for n in moves.safe:
		check(s.board.mines[n] == 0, "wrong flags cannot contaminate bot logic")
	var store := SaveStore.new()
	check(store.directory != "user://", "tests isolated from player data")
	check(store.write_session(s), "write save: " + store.last_error)
	var restored := store.load_session()
	check(restored != null and restored.credits == s.credits and restored.board.cells == s.board.cells, "save/load exact state")
	s.credits += 17
	check(store.write_session(s), "second write creates backup")
	var file := FileAccess.open(store.path("expedition.json"), FileAccess.WRITE)
	file.store_string("broken")
	file.close()
	restored = store.load_session()
	check(restored != null and restored.credits == s.credits - 17 and store.notice != "", "corrupt save recovered from backup")
	check(store.write_session(s), "corrupt primary replaced with healthy state")
	var data := s.to_dict()
	data.board.clues[0] = 99
	check(GameSession.from_dict(data) == null, "invalid save rejected")
	check(not s.begin_trial(0), "trials locked early")
	# Targeted rule fixtures supplement the generated solver corpus.
	var fixture := GameSession.new()
	fixture.index = 60
	fixture.upgrades.assign(["cross","line","nova","drone","flagger","logic","oracle","capacitor","battery"])
	fixture.start_board()
	fixture.reveal(90)
	var tool_strikes := fixture.strikes
	for tool in ["cross","line","nova"]:
		fixture.energy = fixture.capacity()
		fixture.use_tool(tool,0)
		check(fixture.strikes == tool_strikes,"%s cannot hit mines" % tool)
	fixture.trial = 2
	fixture.start_board()
	fixture.reveal(30)
	fixture.energy = fixture.capacity()
	var opened := fixture.board.open_count()
	check(not fixture.use_tool("cross",0),"survey trials reject advanced tools")
	fixture.tick(30)
	check(fixture.board.open_count() == opened,"survey trials park drones")
	check(fixture.use_tool("probe"),"survey trials retain guaranteed probe")
	fixture.trial = -1
	fixture.index = 95
	fixture.start_board()
	while not fixture.finished:
		if fixture.layer_ready:
			fixture.advance_layer()
		fixture.probe_one("tool")
	check(fixture.last_reward.region_end,"last relay has ending")
	var finish_restore := GameSession.from_dict(fixture.to_dict())
	check(finish_restore != null and finish_restore.finished,"completed debrief survives restart")
	fixture.next_board()
	check(fixture.completed_campaign and fixture.index == 96,"endless begins after final relay")
	check(fixture.begin_trial(0),"mastery accessible from fresh endless board")
	while not fixture.finished:
		if fixture.layer_ready:
			fixture.advance_layer()
		fixture.probe_one("tool")
	fixture.next_board()
	check(fixture.index == 96 and fixture.trial == -1 and not fixture.finished,"trial returns to same pending campaign field")
	# Chording a deliberately wrong flag is allowed to strike: clues never lie.
	var chord_board := MineBoard.new()
	chord_board.setup(8,7,7,71093)
	chord_board.reveal(27)
	chord_board.toggle_flag(5) # visible clue 12 touches 5 and the actual charge 13.
	var targets := chord_board.chord_targets(12)
	check(targets.has(13),"wrong flag produces dangerous chord")
	for n in targets:
		chord_board.reveal(n)
	check(chord_board.cells[13] == MineBoard.HIT,"chord respects actual mine position")
	var count := 0
	for item in Content.UPGRADES:
		check(Content.upgrade(item.id).id == item.id, "content ID")
		if item.pre != "":
			check(not Content.upgrade(item.pre).is_empty(), "prerequisite exists")
		count += 1
	check(count == 65, "65 branching upgrades")
	for a in Content.UPGRADES:
		for b in Content.UPGRADES:
			if a.id<b.id:
				check(Content.tree_position(a).distance_to(Content.tree_position(b))>=80,"tree nodes have disjoint hit areas even at minimum zoom: "+a.id+" / "+b.id)
	# Depth must survive reloads and cannot pay out twice.
	var deep := GameSession.new()
	deep.index = 20
	deep.start_board()
	deep.reveal(40)
	check(deep.board.plates.count(2)>0,"deeper sites introduce visible plating")
	while not deep.finished:
		deep.probe_one("tool")
	var earned := deep.credits
	deep.check_completion()
	check(deep.credits==earned and deep.finished,"single board completes site and pays once")
	var roundtrip := GameSession.from_dict(JSON.parse_string(JSON.stringify(deep.to_dict())))
	check(roundtrip!=null and roundtrip.finished,"single-field clear checkpoint roundtrip")
	deep.next_board()
	check(deep.index==21 and deep.stratum==0,"next clear goes straight to the next site")
	check(not deep.board.generated,"next site creates distinct fresh puzzle")
	deep.reveal(40)
	var plated := -1
	for i in range(deep.board.cells.size()):
		if deep.board.plates[i]>0 and deep.board.mines[i]==0:
			plated=i
			break
	var before_plate: int = deep.board.plates[plated]
	deep.reveal(plated)
	check(deep.board.plates[plated]==before_plate-1 and deep.board.cells[plated]==MineBoard.HIDDEN,"unupgraded excavation takes one plate layer")
	deep.upgrades.append("drill")
	deep.reveal(plated)
	check(deep.board.cells[plated]==MineBoard.OPEN,"diamond drill breaks through remaining crust")
	var clone_deep := GameSession.from_dict(deep.to_dict())
	check(clone_deep!=null and clone_deep.board.plates==deep.board.plates,"partially excavated plates persist")
	var plain_cross := deep.cross_cells(80).size()
	deep.upgrades.append("diagonal")
	check(deep.cross_cells(80).size()>plain_cross,"diagonal upgrade changes beam footprint")
	var plain_line := deep.tool_cells("line",80).size()
	deep.upgrades.append("vertical")
	check(deep.tool_cells("line",80).size()>plain_line,"meridian adds full column")
	var plain_nova := deep.tool_cells("nova",80).size()
	deep.upgrades.append("aftershock")
	check(deep.tool_cells("nova",80).size()>plain_nova,"event horizon grows nova")
	deep.upgrades.append("reservoir")
	deep.probe_charge=2
	check(deep.use_tool("probe") and deep.use_tool("probe") and deep.probe_charge<1,"reservoir stores two separate pulses")
	deep.upgrades.append("supercap")
	check(deep.capacity()==40,"storm capacitor enables combined beam budget")
	deep.upgrades.append("excavator")
	deep.upgrades.append("perforator")
	check(deep.excavation_power("drone")==3 and deep.excavation_power("tool")==4,"specialised excavation strength")
	deep.upgrades.append("legacy")
	check(deep.excavation_power("manual")==6 and deep.excavation_power("drone")==6,"endgame breaks deep plating in one visit")
	deep.chain=24
	deep.start_board()
	check(deep.chain==24,"unbroken current carries chain between sites")
	# Existing 1.0 saves remain readable, including an exact in-progress field.
	var old := GameSession.new()
	old.reveal(20)
	var old_data := old.to_dict()
	old_data.version=1
	old_data.erase("stratum")
	old_data.erase("layer_ready")
	old_data.board.erase("plates")
	old_data.board.erase("crust")
	var migrated := GameSession.from_dict(old_data)
	check(migrated!=null and migrated.board.cells==old.board.cells and migrated.stratum==0,"v1 save migrates without resetting field")
	# Every tree path must reach the origin without a cycle.
	for item in Content.UPGRADES:
		var visited: Array[String]=[]
		var cursor: Dictionary=item
		while cursor.pre!="" and not visited.has(cursor.id):
			visited.append(cursor.id)
			cursor=Content.upgrade(cursor.pre)
		check(cursor.id=="lens","upgrade path reaches origin: "+item.id)
	load("res://tests/strike_regressions.gd").run(check)
	load("res://tests/upgrade_regressions.gd").run(check)
	load("res://tests/save_validation_regressions.gd").run(check)
	load("res://tests/survey_form_regressions.gd").run(check)
	load("res://tests/preview_regressions.gd").run(check)
	if failures.is_empty():
		print("AFTERLIGHT PASS: %d rule and persistence checks" % checks)
	else:
		printerr("AFTERLIGHT FAIL: %d / %d checks" % [failures.size(), checks])
	quit(0 if failures.is_empty() else 1)
