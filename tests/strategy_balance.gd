extends SceneTree

# Equal-equipment counterexample search: blind clicking at 10 inputs/second
# versus the existing visible-information player policy at 1 decision/second.
# Every policy gets the same centre opening, upgrades, passive fleet and seed.
# Retries are immediate but cost one input; no purchases occur during a case.
const FIELDS = [0,5,20,47,72,95]
const ATTEMPTS = [0,3,11]
const MODES = ["row_spam","random_spam","row_toolkit","random_toolkit"]
var results: Array[Dictionary] = []
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var balance_path := "res://test_runs/balance_v2.json"
	if not FileAccess.file_exists(balance_path):
		printerr("Generate the current campaign balance report first: "+balance_path)
		quit(1)
		return
	var reports: Variant = JSON.parse_string(FileAccess.get_file_as_string(balance_path))
	if not reports is Array or reports.is_empty():
		printerr("Current balance report is not a nonempty array")
		quit(1)
		return
	var fast: Dictionary = reports[0]
	if int(fast.get("strata",0)) != Content.CAMPAIGN_LENGTH:
		printerr("Strategy benchmark requires a current one-field-per-site balance report")
		quit(1)
		return
	for field in FIELDS:
		var equipment: Array[String] = []
		for unlock in fast.unlocks:
			if int(unlock.field) <= field+1:
				equipment.append(str(unlock.id))
		for initial_attempt in ATTEMPTS:
			var solve := simulate(field,initial_attempt,equipment,"clue_policy",600)
			results.append(solve)
			if not solve.completed or solve.strikes != 0:
				failures.append("Clue policy failed field %d attempt %d" % [field+1,initial_attempt])
			# Give every spam policy at least two minutes, or three solver runs.
			var budget := minf(600,maxf(120,solve.seconds*3))
			for mode in MODES:
				var result := simulate(field,initial_attempt,equipment,mode,budget)
				result["clue_seconds"] = solve.seconds
				result["time_ratio_to_clue"] = snappedf(float(result.seconds)/maxf(0.1,solve.seconds),0.01) if result.completed else -1.0
				results.append(result)
		print("STRATEGY field %d: %d installed discoveries, 3 matched seeds complete" % [field+1,equipment.size()])
	var summary: Array[Dictionary] = []
	for mode in ["clue_policy"]+MODES:
		var cases := 0
		var completed := 0
		var failed_attempts := 0
		var elapsed := 0.0
		var banked := 0
		var losses := 0
		var faster := 0
		for result in results:
			if result.policy != mode:
				continue
			cases += 1
			completed += 1 if result.completed else 0
			failed_attempts += int(result.failed_attempts)
			elapsed += float(result.seconds)
			banked += int(result.banked_light)
			losses += int(result.strikes)
			faster += 1 if result.get("time_ratio_to_clue",-1.0)>0 and result.time_ratio_to_clue<1 else 0
		var row := {"policy":mode,"completed":completed,"cases":cases,"failed_attempts":failed_attempts,"seconds":snappedf(elapsed,0.1),"strikes":losses,"banked_light":banked,"faster_than_clue":faster}
		summary.append(row)
		print("STRATEGY "+JSON.stringify(row))
	# Regression limits distinguish blind clicking from late-game tool power.
	# Small tutorial fields can still be cleared by luck; a complete campaign
	# must not be efficiently funded by sweeping unexamined hidden tiles.
	for row in summary:
		if row.policy in ["row_spam","random_spam"]:
			if row.completed>=summary[0].completed/2 or float(row.banked_light)/maxf(1,row.seconds)>=float(summary[0].banked_light)/summary[0].seconds/4:
				failures.append("Blind clicking became a competitive progression strategy: "+row.policy)
	var output := FileAccess.open("res://test_runs/strategy_balance.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"campaign_source_minutes":fast.minutes,"summaries":summary,"cases":results},"\t"))
	output.close()
	for failure in failures:
		printerr(failure)
	print("AFTERLIGHT %s: %d equal-equipment strategy cases" % ["PASS" if failures.is_empty() else "FAIL",results.size()])
	quit(0 if failures.is_empty() else 1)

func simulate(field: int, initial_attempt: int, equipment: Array[String], mode: String, budget: float) -> Dictionary:
	var s := GameSession.new()
	s.index = field
	s.upgrades.assign(equipment)
	s.attempt = initial_attempt
	s.start_board(false)
	var rng := RandomNumberGenerator.new()
	rng.seed = 70001+field*191+initial_attempt*997
	var cursor := 0
	var actions := 0
	var failed_attempts := 0
	var steps := 0
	var best_fraction := 0.0
	var failed_observed := false
	while steps < roundi(budget*10) and not s.finished:
		steps += 1
		s.tick(0.1)
		if s.finished:
			break
		if mode == "clue_policy" and steps%10 != 0:
			continue
		if s.failed:
			if not failed_observed:
				failed_attempts += 1
			s.retry_board()
			failed_observed = false
			cursor = 0
			actions += 1
			continue
		if not s.board.generated:
			s.reveal((s.board.height/2)*s.board.width+s.board.width/2)
			actions += 1
		elif mode == "clue_policy":
			actions += 1 if preload("res://tests/player_policy.gd").act(s) else 0
		else:
			var acted := false
			if mode.ends_with("toolkit"):
				acted = tool_action(s)
			if not acted:
				var hidden: Array[int] = []
				for cell in range(s.board.cells.size()):
					if s.board.cells[cell] == MineBoard.HIDDEN:
						hidden.append(cell)
				if not hidden.is_empty():
					var target := -1
					if mode.begins_with("random"):
						target = hidden[rng.randi_range(0,hidden.size()-1)]
					else:
						for cell in hidden:
							if cell >= cursor:
								target = cell
								break
						if target < 0:
							target = hidden[0]
						cursor = (target+1)%s.board.cells.size()
					s.reveal(target)
					acted = true
			actions += 1 if acted else 0
		var total := s.board.cells.size()-s.board.mine_count
		best_fraction = maxf(best_fraction,1-float(s.board.safe_remaining())/total)
		if s.failed:
			failed_attempts += 1
			failed_observed = true
		s.events.clear()
	return {"field":field+1,"initial_attempt":initial_attempt,"policy":mode,"upgrades":equipment.size(),"completed":s.finished,"seconds":snappedf(steps/10.0,0.1),"actions":actions,"failed_attempts":failed_attempts,"strikes":s.total_strikes,"banked_light":s.credits,"cores":s.cores,"furthest_safe_fraction":snappedf(best_fraction,0.001),"last_safe_remaining":s.board.safe_remaining(),"last_damage":s.damage,"last_cargo":s.board_earned if not s.finished else 0}

func tool_action(s: GameSession) -> bool:
	# Same public-information beam targeting as player_policy; no clue reading,
	# flags, mine-map access, or hand-picked safe clicks are used by spam modes.
	var b := s.board
	var best_tool := ""
	var best_cell := -1
	var best_gain := 3.0
	for id in ["cross","line","nova"]:
		if not s.tool_available(id) or s.energy < s.minimum_tool_cost(id):
			continue
		for y in range(0,b.height,2):
			for x in range(0,b.width,2):
				var target := y*b.width+x
				var cost := s.effective_tool_cost(id,target)
				if s.energy < cost:
					continue
				var gain := 0.0
				for n in s.tool_cells(id,target):
					if b.cells[n] == MineBoard.HIDDEN:
						gain += 1.0 if b.plates[n] <= s.excavation_power("tool") else 0.45
				gain *= 6.0/cost
				if gain > best_gain:
					best_gain = gain
					best_tool = id
					best_cell = target
	if best_cell >= 0:
		return s.use_tool(best_tool,best_cell)
	if s.probe_charge >= 1:
		return s.use_tool("probe")
	if s.tool_available("overdrive") and s.drone_count()>0 and s.overdrive_seconds<=0 and s.energy>=s.tool_cost("overdrive"):
		return s.use_tool("overdrive")
	return false
