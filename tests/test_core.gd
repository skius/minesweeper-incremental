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
	check(s.strikes == s.board.mine_count and s.credits >= light_before, "mistakes never erase earned light")
	while not s.finished:
		s.probe_one("tool")
	check(s.last_reward.rating == 1 and s.cores == 1, "completion after all mine strikes")
	var completion_light := s.credits
	s.check_completion()
	s.reveal(0)
	check(s.credits == completion_light, "no duplicate completion payout")
	s.next_board()
	check(s.index == 1 and not s.finished and not s.board.generated, "next expedition")
	s.credits = 1000
	s.cores = 10
	check(not s.buy("nova"), "rank gating")
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
		fixture.probe_one("tool")
	check(fixture.last_reward.region_end,"last relay has ending")
	var finish_restore := GameSession.from_dict(fixture.to_dict())
	check(finish_restore != null and finish_restore.finished,"completed debrief survives restart")
	fixture.next_board()
	check(fixture.completed_campaign and fixture.index == 96,"endless begins after final relay")
	check(fixture.begin_trial(0),"mastery accessible from fresh endless board")
	while not fixture.finished:
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
	check(count == 24, "24 qualitative upgrades")
	if failures.is_empty():
		print("AFTERLIGHT PASS: %d rule and persistence checks" % checks)
	else:
		printerr("AFTERLIGHT FAIL: %d / %d checks" % [failures.size(), checks])
	quit(0 if failures.is_empty() else 1)
