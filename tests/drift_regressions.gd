extends SceneTree

# Independent adversarial runner. It never accesses player saves or launches UI.
# Synthetic fields use actual mine positions and recomputed, truthful clues.
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("DRIFT CHECK FAILED: "+message)

func fixture(index: int = 95) -> GameSession:
	var s := GameSession.new()
	s.index = index
	s.board.setup(15,13,20,91337,2)
	s.board.generated = true
	for y in range(1,13,3):
		for x in range(1,15,3):
			s.board.mines[y*15+x] = 1
	s.board.plates.fill(2)
	recompute(s.board)
	s.ensure_drift()
	s.events.clear()
	return s

func recompute(b: MineBoard) -> void:
	for cell in range(b.cells.size()):
		b.clues[cell] = 0
		for n in b.neighbours(cell):
			b.clues[cell] += b.mines[n]

func wave(s: GameSession) -> Dictionary:
	s.events.clear()
	s.shift_field()
	for event in s.events:
		if event.type == "drift":
			return event
	return {"moves":[],"cells":[]}

func json_copy(data: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(data))

func state(s: GameSession) -> String:
	return JSON.stringify(json_copy(s.to_dict()))

func run() -> void:
	focus_and_geometry()
	grace_and_guards()
	worked_and_anchors()
	drift_rewards()
	timers_and_stasis()
	chord_and_convergence()
	saves_and_validation()
	print("AFTERLIGHT %s: %d independent drift checks, %d failures" % ["PASS" if failures.is_empty() else "FAIL",checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func assert_truthful(s: GameSession, label: String) -> void:
	check(s.board.mines.count(1) == s.board.mine_count,label+": mine count conserved")
	for cell in range(s.board.cells.size()):
		var expected := 0
		for n in s.board.neighbours(cell):
			expected += s.board.mines[n]
		check(s.board.clues[cell] == expected,label+": clue %d is truthful" % cell)
		check(not (s.board.cells[cell] == MineBoard.OPEN and s.board.mines[cell] == 1),label+": no mine under open tile")
		check(not (s.board.pockets[cell] == 1 and s.board.mines[cell] == 1),label+": crystal remains safe")

func focus_and_geometry() -> void:
	for focus_cell in [0,14,180,194,97]:
		var s := fixture()
		s.set_focus(focus_cell)
		var protected := s.drift.area(s.board,focus_cell,2)
		var halo := s.drift.area(s.board,focus_cell,3)
		var original_clues := s.board.clues.duplicate()
		var original_mines := s.board.mines.duplicate()
		var total_moves := 0
		check(protected.size() == (25 if focus_cell == 97 else 9), "focus bounds match 5x5 rectangle clipped at corners")
		for iteration in range(30):
			var before := s.board.mines.duplicate()
			var result := wave(s)
			total_moves += result.moves.size()
			var touched: Array[int] = []
			for pair in result.moves:
				var source: int = pair[0]
				var target: int = pair[1]
				check(absi(source%15-target%15)+absi(source/15-target/15) == 1,"mine moves one orthogonal neighbour")
				check(before[source] == 1 and before[target] == 0 and s.board.mines[source] == 0 and s.board.mines[target] == 1,"wave swaps a mine and safe cell atomically")
				check(not touched.has(source) and not touched.has(target),"wave never reuses either endpoint")
				touched.append(source)
				touched.append(target)
			for n in halo:
				check(s.board.mines[n] == original_mines[n],"focus plus halo retains mine geometry")
			for n in protected:
				check(s.board.clues[n] == original_clues[n],"every clue within pointer focus remains stable")
			if iteration%10 == 0:
				assert_truthful(s,"focus wave")
		check(total_moves > 0,"focus protection still permits movement elsewhere")
		var remembered := s.drift.focus
		s.set_focus(-1)
		s.set_focus(s.board.cells.size())
		check(s.drift.focus == remembered,"offboard pointer retains most recent valid working area")
	var ballast := fixture()
	ballast.upgrades.assign(["ballast"])
	ballast.set_focus(97)
	check(ballast.drift.radius == 3 and ballast.drift.area(ballast.board,97,ballast.drift.radius).size() == 49,"Ballast enlarges focus from 25 to 49 cells")
	var before := ballast.board.clues.duplicate()
	for _step in range(30):
		wave(ballast)
	for cell in ballast.drift.area(ballast.board,97,3):
		check(ballast.board.clues[cell] == before[cell],"Ballast preserves every clue in expanded area")

func grace_and_guards() -> void:
	var s := fixture()
	s.set_focus(0)
	s.tick(0.2)
	s.set_focus(14)
	s.tick(0.2)
	s.set_focus(194)
	var old_zones := s.drift.area(s.board,0,3)+s.drift.area(s.board,14,3)
	var original := s.board.mines.duplicate()
	for cell in old_zones:
		check(s.drift.grace[cell] > 0,"all earlier focus zones receive simultaneous grace")
	for _step in range(20):
		wave(s)
	for cell in old_zones:
		check(s.board.mines[cell] == original[cell],"multiple grace zones remain frozen across waves")
	s.tick(1.31)
	check(is_zero_approx(s.drift.grace[0]) and s.drift.grace[14]>0,"grace expires per tile rather than resetting the whole previous region")
	s.tick(0.2)
	check(is_zero_approx(s.drift.grace[14]),"last previous zone expires after its own full grace")
	for guard in ["disabled","unopened","failed","finished","nested","stasis","converged"]:
		var g := fixture()
		match guard:
			"disabled": g.drift.enabled = false
			"unopened": g.board.generated = false
			"failed": g.failed = true
			"finished": g.finished = true
			"nested": g.action_depth = 1
			"stasis": g.drift.stasis = 4
			"converged": g.drift.converged = true
		var mines := g.board.mines.duplicate()
		var sequence := g.drift.sequence
		check(wave(g).moves.is_empty() and g.board.mines == mines and g.drift.sequence == sequence,"shift guard: "+guard)
	for index in [0,31,32,48,64,80,95]:
		var g := fixture(index)
		check(g.drift.enabled == (index>=32),"drift begins at field 33")
		check(g.drift.period == ([12,12,12,10,8,6,6][[0,31,32,48,64,80,95].find(index)]),"region-scaled drift period")
	var trial := fixture()
	trial.trial = 10
	trial.start_board()
	trial.upgrades.assign(["anchor","stasis","interceptor","drone"])
	check(not trial.drift.enabled and not trial.tool_available("anchor") and not trial.tool_available("stasis"),"late campaign progress cannot enable drift tools in a static Survey trial")

func worked_and_anchors() -> void:
	var s := fixture()
	# Protect one mine, one false flag, one crystal, a mine partially excavated,
	# and a safe tile partially excavated. Focus is moved away after the actions.
	s.board.cells[16] = MineBoard.FLAG
	s.board.cells[17] = MineBoard.FLAG
	s.board.pockets[18] = 1
	s.break_plates(19,1,"manual")
	s.break_plates(20,1,"tool")
	s.set_focus(194)
	var before := s.board.mines.duplicate()
	for _step in range(80):
		wave(s)
	for cell in [16,17,18,19,20]:
		check(s.board.mines[cell] == before[cell],"worked, flagged and crystal cell stays fixed: %d" % cell)
	check(s.drift.surveyed[19] == 1 and s.drift.surveyed[20] == 1,"both manual and tool excavation record permanent survey")
	var flags := fixture()
	flags.flag(16)
	flags.flag(16)
	check(flags.drift.surveyed[16] == 0 and flags.drift.anchors[16] == 0,"unflagging untouched terrain cannot create free permanent anchors")
	flags.upgrades.assign(["mooring"])
	flags.flag(16)
	flags.flag(16)
	check(flags.drift.anchors.count(1) == 9,"Mooring leaves its promised 3x3 anchor after flag removal")
	var anchor := fixture()
	anchor.upgrades.assign(["anchor"])
	anchor.energy = 10
	check(anchor.use_tool("anchor",97) and anchor.energy == 6 and anchor.drift.anchors.count(1) == 25,"Ground anchor buys a 5x5 permanent patch for 4 energy")
	check(not anchor.use_tool("anchor",97) and anchor.energy == 6,"duplicate anchor cannot charge again for unchanged geometry")
	var base_clues := anchor.board.clues.duplicate()
	anchor.set_focus(0)
	anchor.tick(2)
	for _step in range(40):
		wave(anchor)
	for cell in anchor.drift.area(anchor.board,97,2):
		check(anchor.board.clues[cell] == base_clues[cell],"anchored clues stay stable after pointer leaves")
	var deep := fixture()
	deep.upgrades.assign(["anchor","deep_anchor"])
	check(deep.use_tool("anchor",97) and deep.drift.anchors.count(1) == 49,"Deep anchor grows to 7x7")
	for cell in deep.drift.area(deep.board,97,3):
		check(deep.board.plates[cell] == 1 and deep.drift.surveyed[cell] == 1,"Deep anchor cracks one plate and surveys its footprint")
	var beam := fixture()
	beam.upgrades.assign(["cross","beam_anchor"])
	check(beam.use_tool("cross",97),"paid beam fixture is valid")
	for cell in beam.cross_cells(97):
		check(beam.drift.anchors[cell] == 1,"accepted beam anchors every cell in its footprint")
	var empty := fixture()
	empty.upgrades.assign(["cross","beam_anchor"])
	for cell in empty.cross_cells(97):
		if empty.board.mines[cell] == 0:
			empty.board.cells[cell] = MineBoard.OPEN
			empty.board.plates[cell] = 0
	check(not empty.use_tool("cross",97) and empty.energy == 10 and empty.drift.anchors.count(1) == 0,"empty beam gives no free protection and spends no energy")
	var pulse := fixture()
	pulse.upgrades.assign(["grounded_pulse"])
	var target := pulse.board.safe_probe()
	check(pulse.use_tool("probe"),"Rooted pulse fires")
	for cell in pulse.drift.area(pulse.board,target,1):
		check(pulse.drift.anchors[cell] == 1,"Rooted pulse anchors around its actual chosen safe target")

func drift_rewards() -> void:
	var idle := fixture()
	idle.upgrades.assign(["induction","tracer","backwash","interceptor","drone"])
	idle.energy = 1
	idle.drift.anchors.fill(1)
	check(wave(idle).moves.is_empty() and idle.energy == 1 and idle.board_earned == 0,"blocked zero-move wave cannot farm energy, cargo or traces")
	check(idle.drift.traces.count(1) == 0 and idle.board.cells.count(MineBoard.FLAG) == 0,"empty wave triggers no trace or interception")
	var charged := fixture()
	charged.upgrades.assign(["induction"])
	charged.energy = 1
	check(not wave(charged).moves.is_empty() and charged.energy == 3,"Dynamo pays exactly 2 energy per nonempty wave, not per moving mine")
	charged.energy = 9
	wave(charged)
	check(charged.energy == 10,"Dynamo respects storage capacity")
	var trace := fixture()
	trace.upgrades.assign(["tracer"])
	var result := wave(trace)
	check(result.moves.size() == 4,"late fixture has a four-mine wave")
	var wakes: Array[int] = []
	for pair in result.moves:
		wakes.append(pair[0])
		check(trace.drift.traces[pair[0]] == 1 and trace.drift.surveyed[pair[0]] == 1 and trace.board.mines[pair[0]] == 0,"Tracer reserves safe vacated tile permanently")
		check(trace.board.cells[pair[0]] == MineBoard.HIDDEN,"Tracer provides information without becoming Backwash reveal")
	for _step in range(40):
		wave(trace)
	for cell in wakes:
		check(trace.board.mines[cell] == 0,"later waves cannot refill visible safe wakes")
	for active in [false,true]:
		var interceptor := fixture()
		interceptor.upgrades.assign(["interceptor","drone","swarm"])
		interceptor.drones_enabled = active
		var caught := wave(interceptor)
		check(interceptor.board.cells.count(MineBoard.FLAG) == (1 if active else 0),"Interceptor obeys fleet toggle and catches only one mine per wave")
		if active:
			var cell: int = caught.moves[0][1]
			check(interceptor.board.mines[cell] == 1 and interceptor.board.cells[cell] == MineBoard.FLAG,"Interceptor flags actual new mine destination")
	var backwash := fixture()
	backwash.upgrades.assign(["backwash","induction","interceptor","drone"])
	backwash.energy = 1
	var wake := wave(backwash)
	for pair in wake.moves:
		check(backwash.board.cells[pair[0]] == MineBoard.OPEN and backwash.board.plates[pair[0]] == 0 and backwash.board.mines[pair[0]] == 0,"Backwash shatters all plates and reveals each actual vacated tile")
	check(backwash.strikes == 0 and backwash.action_depth == 0 and not backwash.failed,"combined wave upgrades resolve safely in one balanced root action")
	assert_truthful(backwash,"combined drift rewards")

func timers_and_stasis() -> void:
	var s := fixture()
	s.upgrades.assign(["stasis","stasis_engine","cross","line","nova","supercap"])
	s.energy = 20
	s.drift.remaining = 2
	check(s.use_tool("stasis") and s.energy == 12 and s.drift.stasis == 12,"Stasis purchases 12 seconds for 8 energy")
	check(not s.use_tool("stasis") and s.energy == 12,"active Stasis cannot be purchased twice")
	check(s.tool_cost("cross") == 3 and s.tool_cost("line") == 5 and s.tool_cost("nova") == 8,"Stillwater halves all beam prices during Stasis")
	s.tick(11)
	check(s.drift.sequence == 0 and s.drift.remaining == 2 and s.drift.stasis == 1,"Stasis pauses remaining drift countdown")
	s.tick(1.5)
	check(s.drift.sequence == 0 and is_equal_approx(s.drift.remaining,1.5) and s.drift.stasis == 0,"frame crossing Stasis expiry advances only unfrozen time")
	check(s.tool_cost("cross") == 6 and s.tool_cost("line") == 10 and s.tool_cost("nova") == 16,"Stillwater pricing returns when Stasis expires")
	s.tick(1.5)
	check(s.drift.sequence == 1,"wave occurs on resumed countdown deadline")
	var before := state(s)
	s.tick(0)
	check(state(s) == before,"zero-time tick leaves drift state unchanged")
	var stalled := fixture()
	stalled.tick(100)
	check(stalled.drift.sequence == 1,"long OS stall produces only one visible wave")

func chord_fixture() -> GameSession:
	var s := fixture()
	s.board.plates.fill(0)
	# 16 is the only charge beside clue17; a correct flag satisfies that clue.
	s.board.cells[17] = MineBoard.OPEN
	s.board.cells[16] = MineBoard.FLAG
	return s

func chord_and_convergence() -> void:
	var locked := chord_fixture()
	check(locked.board.clues[17] == 1 and not locked.board.chord_targets(17).is_empty(),"chord fixture has a truthful satisfied clue")
	var before := locked.board.cells.duplicate()
	locked.chord(17)
	check(locked.board.cells == before and not locked.can_chord(),"ordinary chording is locked before its upgrade")
	locked.upgrades.assign(["chording","clue_anchor"])
	locked.chord(17)
	check(locked.board.cells != before and locked.strikes == 0,"Chord relay unlocks ordinary safe chord")
	for cell in locked.drift.area(locked.board,17,2):
		check(locked.drift.anchors[cell] == 1,"Clue moorings anchor around successful chord centre")
	check(locked.drift.focus == 17,"chording retains pointer focus on clicked clue, not final opened neighbour")
	for id in ["chord","conductor","flywheel","synchrony"]:
		var old := chord_fixture()
		old.upgrades.assign([id])
		var historical := json_copy(old.to_dict())
		historical.version = 3
		historical.erase("drift")
		var restored := GameSession.from_dict(historical)
		check(restored != null and restored.can_chord(),"v3 chord-dependent upgrade retains basic capability: "+id)
	var convergence := fixture()
	convergence.upgrades.assign(["convergence","drone"])
	var retained := 0
	for cell in range(convergence.board.cells.size()):
		if convergence.board.mines[cell] == 0:
			if retained < 44:
				retained += 1
			else:
				convergence.board.cells[cell] = MineBoard.OPEN
				convergence.board.plates[cell] = 0
	check(convergence.board.safe_remaining() == 44,"Convergence fixture starts just above one-quarter threshold")
	convergence.check_completion()
	check(not convergence.drift.converged,"Convergence cannot trigger above one-quarter safe ground")
	convergence.probe_one("tool")
	check(convergence.drift.converged,"Convergence triggers exactly when last quarter remains")
	var fleet_called := false
	for event in convergence.events:
		fleet_called = fleet_called or event.type == "drone_work"
	check(fleet_called,"Convergence calls its advertised immediate fleet cycle")
	var sequence := convergence.drift.sequence
	convergence.shift_field()
	check(convergence.drift.sequence == sequence,"Convergence permanently stops future waves")
	var count := 0
	for event in convergence.events:
		count += 1 if event.type == "convergence" else 0
	check(count == 1,"recursive convergence fleet work cannot trigger a second convergence")

func saves_and_validation() -> void:
	var s := fixture()
	s.upgrades.assign(["ballast","tracer","induction","anchor","stasis"])
	s.set_focus(0)
	s.tick(0.25)
	s.set_focus(14)
	wave(s)
	s.use_tool("anchor",97)
	s.energy = 10
	s.use_tool("stasis")
	s.tick(1.125)
	var data := json_copy(s.to_dict())
	var restored := GameSession.from_dict(data)
	check(restored != null,"v4 drift session reloads with live timer, grace, surveyed, anchor and trace state")
	if restored != null:
		check(state(restored) == state(s),"v4 save round-trip preserves exact complete drift state")
		for step in range(80):
			if step%7 == 0:
				var cell := (step*31)%s.board.cells.size()
				s.set_focus(cell)
				restored.set_focus(cell)
			s.tick(0.375)
			restored.tick(0.375)
			check(state(s) == state(restored),"uninterrupted and resumed worlds choose identical future drift waves")
	var legacy := json_copy(fixture().to_dict())
	legacy.version = 3
	legacy.erase("drift")
	var old := GameSession.from_dict(legacy)
	check(old != null and not old.drift.enabled and old.board.to_dict() == fixture().board.to_dict(),"v3 migration keeps exact current late field static")
	if old != null:
		check(old.has("chording"),"legacy late player keeps previously available chording")
		old.tick(100)
		check(old.drift.sequence == 0,"legacy field does not silently begin drifting")
		old.start_board()
		check(old.drift.enabled,"next newly generated late field gains drift")
	var base := json_copy(fixture().to_dict())
	for value in [null,[],true,"drift"]:
		var invalid := base.duplicate(true)
		invalid.drift = value
		check(GameSession.from_dict(invalid) == null,"v4 requires a structured drift payload")
	for key in ["enabled","converged"]:
		for value in [null,0,"false",[],{}]:
			var invalid := base.duplicate(true)
			invalid.drift[key] = value
			check(GameSession.from_dict(invalid) == null,"reject malformed drift boolean "+key)
	for key in ["remaining","stasis","sequence","focus","radius"]:
		for value in [null,true,"1",[],{},INF,-INF,NAN]:
			var invalid := base.duplicate(true)
			invalid.drift[key] = value
			check(GameSession.from_dict(invalid) == null,"reject malformed drift numeric "+key)
	for fields in [{"remaining":-1},{"remaining":15},{"stasis":-1},{"stasis":15},{"sequence":-1},{"sequence":0.5},{"focus":-2},{"focus":195},{"focus":0.5},{"radius":1},{"radius":4},{"radius":2.5}]:
		var invalid := base.duplicate(true)
		invalid.drift.merge(fields,true)
		check(GameSession.from_dict(invalid) == null,"reject out-of-range drift state "+str(fields))
	for key in ["surveyed","anchors","traces","grace"]:
		for value in [null,[],{},"array"]:
			var invalid := base.duplicate(true)
			invalid.drift[key] = value
			check(GameSession.from_dict(invalid) == null,"reject malformed drift array "+key)
		for value in [null,true,-1,2,"0",INF,NAN]:
			var invalid := base.duplicate(true)
			invalid.drift[key][0] = value
			check(GameSession.from_dict(invalid) == null,"reject invalid cell in drift array "+key)
	var false_trace := base.duplicate(true)
	false_trace.drift.traces[16] = 1
	false_trace.drift.surveyed[16] = 1
	check(GameSession.from_dict(false_trace) == null,"trace may never claim a mined tile is safe")
	false_trace = base.duplicate(true)
	false_trace.drift.traces[0] = 1
	check(GameSession.from_dict(false_trace) == null,"trace must also be permanently surveyed")
	var early := json_copy(fixture(0).to_dict())
	early.drift.enabled = true
	check(GameSession.from_dict(early) == null,"early field cannot load illicit enabled drift")
	for key in base.drift.keys():
		var missing := base.duplicate(true)
		missing.drift.erase(key)
		check(GameSession.from_dict(missing) == null,"v4 requires drift field "+key)
