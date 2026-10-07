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
