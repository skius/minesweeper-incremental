extends SceneTree

var failures: Array[String] = []
var reports: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for profile in [{"name":"fast","think":1.0,"branch":0},{"name":"fleet-first","think":1.0,"branch":1},{"name":"deliberate","think":3.0,"branch":3}]:
		var s := GameSession.new()
		var elapsed := 0.0
		var actions := 0
		var strata := 0
		var unlocks: Array = []
		var regions: Array = []
		for field in range(Content.CAMPAIGN_LENGTH):
			var loops := 0
			while not s.finished and loops < 30000:
				loops += 1
				var items := Content.UPGRADES.duplicate()
				items.sort_custom(func(a,b):
					if (a.branch == profile.branch) != (b.branch == profile.branch):
						return a.branch == profile.branch
					return a.rank < b.rank
				)
				for item in items:
					if s.buy(item.id):
						unlocks.append({"id":item.id,"field":field+1,"minute":snappedf(elapsed/60,0.1)})
						elapsed += 2 # Opening a known upgrade and confirming it.
				if s.layer_ready:
					strata += 1
					s.advance_layer()
					elapsed += 0.7
				for _sample in range(int(profile.think*5)):
					s.tick(0.2)
				elapsed += profile.think
				if not s.finished and not s.layer_ready:
					if smart_action(s):
						actions += 1
				s.events.clear()
			if not s.finished:
				failures.append("%s stalled on field %d" % [profile.name,field])
				break
			if s.strikes > 0:
				failures.append("Unsafe policy %s at %d" % [profile.name,field])
			strata += 1
			elapsed += 4
			if field%16 == 15:
				regions.append({"region":s.region(),"minutes":snappedf(elapsed/60,0.1),"upgrades":s.upgrades.size(),"reveals":s.total_reveals,"drone":s.total_drone})
				print("%s region %d: %.1fm, %d upgrades" % [profile.name,s.region()+1,elapsed/60,s.upgrades.size()])
			s.next_board()
		for item in Content.UPGRADES:
			if s.buy(item.id):
				unlocks.append({"id":item.id,"field":97,"minute":snappedf(elapsed/60,0.1)})
		if s.upgrades.size() != 50:
			failures.append("%s cannot buy every upgrade (%d)" % [profile.name,s.upgrades.size()])
		var result := {"policy":profile.name,"seconds_per_decision":profile.think,"minutes":snappedf(elapsed/60,0.1),"actions":actions,"strata":strata,"upgrades":s.upgrades.size(),"regions":regions,"unlocks":unlocks,"drone_reveals":s.total_drone,"reveals":s.total_reveals,"light":s.credits,"cores":s.cores}
		reports.append(result)
		print("CAMPAIGN %s: %.1f minutes, %d actions, %d strata, %d/50 upgrades" % [profile.name,elapsed/60,actions,strata,s.upgrades.size()])
	var file := FileAccess.open("res://test_runs/balance_v2.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(reports,"\t"))
	file.close()
	for failure in failures:
		printerr("FAIL: "+failure)
	print("AFTERLIGHT %s: fast campaign policies with aimed tools and chording" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)

# Decisions use public tile states, plating and logical deductions only. No mine map.
func smart_action(s: GameSession) -> bool:
	if not s.board.generated:
		s.reveal(s.board.height/2*s.board.width+s.board.width/2)
		return true
	var b := s.board
	var best_tool := ""
	var best_cell := -1
	var best_gain := 3.0
	for id in ["cross","line","nova"]:
		if not s.has(id) or s.energy < s.tool_cost(id):
			continue
		# Sample the entire field on a coarse lattice, including its edges.
		for y in range(0,b.height,2):
			for x in range(0,b.width,2):
				var target := y*b.width+x
				var gain := 0.0
				for n in s.tool_cells(id,target):
					if b.cells[n] == MineBoard.HIDDEN:
						gain += 1.0 if b.plates[n] <= s.excavation_power("tool") else 0.45
				# Prefer efficient shapes, rather than spending all energy on a tiny patch.
				gain *= 6.0/s.tool_cost(id)
				if gain > best_gain:
					best_gain = gain
					best_tool = id
					best_cell = target
	if best_cell >= 0:
		return s.use_tool(best_tool,best_cell)
	var best_chord := -1
	var chord_gain := 1
	for i in range(b.cells.size()):
		var gain := b.chord_targets(i).size()
		if gain > chord_gain:
			chord_gain = gain
			best_chord = i
	if best_chord >= 0:
		s.chord(best_chord)
		return true
	var moves := b.deductions(true)
	if s.has("conductor") and not moves.safe.is_empty():
		for i in range(b.cells.size()):
			if b.cells[i] == MineBoard.OPEN:
				var gain := 0
				for n in b.neighbours(i):
					gain += 1 if moves.safe.has(n) else 0
				if gain > chord_gain:
					chord_gain = gain
					best_chord = i
		if best_chord >= 0:
			s.chord(best_chord)
			return true
	if s.probe_charge >= 1 and (moves.safe.size() < 2 or s.has("prism")):
		return s.use_tool("probe")
	if not moves.mines.is_empty():
		s.flag(moves.mines[0])
		return true
	if not moves.safe.is_empty():
		s.reveal(moves.safe[0])
		return true
	return false
