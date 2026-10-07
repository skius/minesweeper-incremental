class_name GameSession
extends RefCounted

var board := MineBoard.new()
var index: int = 0
var trial: int = -1
var credits: int = 0
var cores: int = 0
var upgrades: Array[String] = []
var medals: Dictionary = {}
var trial_medals: Dictionary = {}
var total_light: int = 0
var total_reveals: int = 0
var total_flags: int = 0
var total_drone: int = 0
var total_strikes: int = 0
var play_seconds: float = 0
var board_seconds: float = 0
var energy: float = 10.0
var probe_charge: float = 1.0
var drone_clock: float = 0.0
var overclock: float = 0.0
var chain: int = 0
var strikes: int = 0
var manual_actions: int = 0
var board_earned: int = 0
var finished: bool = false
var completed_campaign: bool = false
var drones_enabled: bool = true
var drone_status: String = "Awaiting deployment"
var events: Array[Dictionary] = []
var last_reward: Dictionary = {}
var paid_flags: Array[int] = []
var seen_intro: bool = false
var livery: int = 0

func _init() -> void:
	start_board()

func has(id: String) -> bool:
	return upgrades.has(id)

func region() -> int:
	return Content.region_for(index)

func capacity() -> float:
	return 24.0 if has("nova") else (18.0 if has("battery") else 10.0)

func drone_count() -> int:
	if not has("drone"):
		return 0
	if has("swarm"):
		return 8
	if has("fleet"):
		return 4
	return 2 if has("pair") else 1

func multiplier() -> int:
	return 1 + mini(chain / 8, 2) if has("chain") else 1

func stars() -> int:
	var sum := 0
	for value in medals.values():
		sum += int(value)
	return sum

func start_board() -> void:
	var spec := Content.contract(index, trial)
	board.setup(spec.width, spec.height, spec.mines, spec.seed)
	board_seconds = 0
	energy = capacity()
	probe_charge = 1
	drone_clock = 0
	overclock = 0
	chain = 0
	strikes = 0
	manual_actions = 0
	board_earned = 0
	finished = false
	paid_flags.clear()
	last_reward.clear()
	drone_status = "Make the first opening" if has("drone") else "Scout drone unlocks after field 2"
	events.append({"type":"new_board"})

func next_board() -> void:
	if not finished:
		return
	if trial >= 0:
		trial = -1
	else:
		index += 1
		if index >= Content.CAMPAIGN_LENGTH:
			completed_campaign = true
	start_board()

func begin_trial(number: int) -> bool:
	if number < 0 or number > 11 or index < (number / 2 + 1) * 16:
		return false
	if not finished and board.generated:
		return false
	trial = number
	start_board()
	return true

func buy(id: String) -> bool:
	var item := Content.upgrade(id)
	if item.is_empty() or has(id) or index < int(item.rank) or credits < int(item.cost) or cores < int(item.cores):
		return false
	if item.pre != "" and not has(item.pre):
		return false
	credits -= int(item.cost)
	cores -= int(item.cores)
	upgrades.append(id)
	energy = minf(energy + 4, capacity())
	events.append({"type":"upgrade","id":id})
	return true

func unlock_reason(item: Dictionary) -> String:
	if has(item.id):
		return "INSTALLED"
	if index < int(item.rank):
		return "After field %d" % int(item.rank)
	if item.pre != "" and not has(item.pre):
		return "Requires " + Content.upgrade(item.pre).name
	if cores < int(item.cores):
		return "Need %d more cores" % (int(item.cores) - cores)
	if credits < int(item.cost):
		return "Need %d more light" % (int(item.cost) - credits)
	return "READY TO INSTALL"

func add_light(amount: int) -> void:
	credits += amount
	total_light += amount
	board_earned += amount

func reveal(i: int, source: String = "manual") -> void:
	if finished or i < 0 or i >= board.cells.size():
		return
	if board.cells[i] == MineBoard.OPEN and source == "manual":
		chord(i)
		return
	var first := not board.generated
	var changed := board.reveal(i)
	if changed.is_empty():
		return
	if source == "manual":
		manual_actions += 1
		if board.cells[i] != MineBoard.HIT:
			chain += 1
	var earned := 0
	var pockets: Array[int] = []
	for cell in changed:
		if board.cells[cell] == MineBoard.HIT:
			strikes += 1
			total_strikes += 1
			if not has("shield") or strikes > 1:
				chain = 0
				energy = maxf(0, energy - 3)
			events.append({"type":"strike","cell":cell,"protected":has("shield") and strikes == 1})
			continue
		total_reveals += 1
		if source == "drone":
			total_drone += 1
		var value := (2 + region()) * (multiplier() if source == "manual" or has("relay") else 1)
		if board.pockets[cell] == 1:
			value *= 3
			value += 25 if has("bounty") else 0
			pockets.append(cell)
			events.append({"type":"pocket","cell":cell})
			if region() == 2 or has("battery"):
				energy = minf(capacity(), energy + 4)
			if region() == 5 or has("fleet"):
				overclock = maxf(overclock, 10)
		if source == "manual" or (source == "tool" and has("resonance")):
			energy = minf(capacity(), energy + 0.45)
		if source == "manual":
			probe_charge = minf(1, probe_charge + 0.035)
		earned += value
	add_light(earned)
	events.append({"type":"reveal","cells":changed,"amount":earned,"source":source,"chain":chain})
	for pocket in pockets:
		if region() == 4:
			for n in range(board.cells.size()):
				if board.mines[n] == 1 and board.cells[n] == MineBoard.HIDDEN:
					board.toggle_flag(n)
					events.append({"type":"flag","cell":n,"auto":true})
					break
		if has("prism") and source != "echo":
			for n in board.neighbours(pocket):
				if board.mines[n] == 0 and board.cells[n] == MineBoard.HIDDEN:
					reveal(n, "echo")
					break
		if has("aurora") and source != "echo":
			for n in cross_cells(pocket):
				if board.mines[n] == 0:
					reveal(n, "echo")
	if first and has("relay"):
		for _j in range(2):
			probe_one("tool")
	if region() == 3 and source == "manual" and manual_actions % 8 == 0:
		probe_one("thermal")
	check_completion()

func flag(i: int) -> void:
	if finished:
		return
	if board.toggle_flag(i):
		events.append({"type":"flag","cell":i,"auto":false})

func chord(i: int) -> void:
	if finished:
		return
	var targets := board.chord_targets(i)
	if targets.is_empty():
		events.append({"type":"tip","text":"Match this clue with neighbouring flags before chording."})
		return
	for n in targets:
		reveal(n, "manual")
	if has("chord") and not finished:
		for _pass in range(5):
			var any := false
			for cell in range(board.cells.size()):
				for n in board.chord_targets(cell):
					if board.cells[n] == MineBoard.HIDDEN:
						any = true
						reveal(n, "cascade")
			if not any or finished:
				break

func cross_cells(i: int) -> Array[int]:
	var result: Array[int] = [i]
	for d in [-2, -1, 1, 2]:
		if i % board.width + d >= 0 and i % board.width + d < board.width:
			result.append(i + d)
		if i / board.width + d >= 0 and i / board.width + d < board.height:
			result.append(i + d * board.width)
	return result

func tool_cost(id: String) -> float:
	return {"probe":0.0,"cross":6.0,"line":10.0,"nova":16.0,"overdrive":12.0}.get(id, 999.0)

func tool_cells(id: String, i: int) -> Array[int]:
	var result: Array[int] = []
	if i < 0 or i >= board.cells.size():
		return result
	if id == "cross":
		return cross_cells(i)
	if id == "line":
		for x in range(board.width):
			result.append((i / board.width) * board.width + x)
	if id == "nova":
		for y in range(maxi(0, i / board.width - 2), mini(board.height, i / board.width + 3)):
			for x in range(maxi(0, i % board.width - 2), mini(board.width, i % board.width + 3)):
				result.append(y * board.width + x)
	return result

func use_tool(id: String, i: int = -1) -> bool:
	if finished or (id != "probe" and not has(id)):
		return false
	if trial >= 0 and trial % 2 == 0 and id != "probe":
		events.append({"type":"tip","text":"This mastery trial is survey tools only: use the probe and your clues."})
		return false
	if id == "probe":
		if probe_charge < 1:
			return false
		probe_charge = 0
		var count := 3 if has("prism") else (2 if has("probe2") else 1)
		for _j in range(count):
			probe_one("tool")
		events.append({"type":"tool","id":id,"cell":i})
		return true
	if energy < tool_cost(id):
		events.append({"type":"tip","text":"More energy needed. Reveal safe tiles or let the capacitor recharge."})
		return false
	if id == "overdrive":
		energy -= tool_cost(id)
		overclock = 12
		events.append({"type":"tool","id":id,"cell":i})
		return true
	if i < 0 or i >= board.cells.size():
		return false
	if not board.generated:
		reveal(i)
	var targets := tool_cells(id, i)
	var any := false
	for n in targets:
		if board.mines[n] == 0 and board.cells[n] != MineBoard.OPEN:
			any = true
	if not any:
		events.append({"type":"tip","text":"Already surveyed. Aim at covered ground; no energy was spent."})
		return false
	energy -= tool_cost(id)
	for n in targets:
		if board.mines[n] == 0:
			if board.cells[n] == MineBoard.FLAG:
				board.cells[n] = MineBoard.HIDDEN
			reveal(n, "tool")
	events.append({"type":"tool","id":id,"cell":i})
	return true

func probe_one(source: String) -> void:
	var cell := board.safe_probe()
	if cell >= 0:
		if board.cells[cell] == MineBoard.FLAG:
			board.cells[cell] = MineBoard.HIDDEN
		reveal(cell, source)

func tick(delta: float) -> void:
	if finished:
		return
	play_seconds += delta
	if not board.generated:
		return
	board_seconds += delta
	energy = minf(capacity(), energy + delta * (0.6 if has("capacitor") else 0.3))
	probe_charge = minf(1, probe_charge + delta / 9.0)
	overclock = maxf(0, overclock - delta)
	if drone_count() == 0 or not drones_enabled or (trial >= 0 and trial % 2 == 0):
		return
	drone_clock += delta
	var interval := 0.85 if overclock > 0 else 3.0
	if drone_clock >= interval:
		drone_clock = fmod(drone_clock, interval)
		drone_cycle()

func drone_cycle() -> void:
	for _j in range(drone_count()):
		if finished:
			return
		var moves := board.deductions(has("logic"))
		if not moves.safe.is_empty():
			var i: int = moves.safe[0]
			if board.cells[i] == MineBoard.FLAG:
				board.cells[i] = MineBoard.HIDDEN
			reveal(i, "drone")
			drone_status = "Surveying safe ground"
		elif has("flagger") and not moves.mines.is_empty():
			var i: int = moves.mines[0]
			board.toggle_flag(i)
			if has("capacitor") and not paid_flags.has(i):
				energy = minf(capacity(), energy + 1)
				paid_flags.append(i)
			events.append({"type":"flag","cell":i,"auto":true})
			drone_status = "Mapping proven charges"
		elif has("oracle") and energy >= 3:
			energy -= 3
			probe_one("drone")
			drone_status = "Oracle found an opening"
		else:
			drone_status = "Waiting for a new opening"
			return

func check_completion() -> void:
	if finished or not board.completed():
		return
	finished = true
	var correct_flags := 0
	for i in range(board.cells.size()):
		if board.cells[i] == MineBoard.FLAG and board.mines[i] == 1:
			correct_flags += 1
	total_flags += correct_flags
	var rating := 3 if strikes == 0 else (2 if strikes <= 2 else 1)
	var bonus := 70 + index * 12 + (correct_flags * 8 if has("salvage") else 0)
	var reward_cores := 1 + (1 if strikes == 0 and has("bounty") else 0)
	if index % Content.REGION_LENGTH == 15 and trial < 0:
		bonus *= 2
		reward_cores += 3
	if trial >= 0:
		var key := str(trial)
		if not trial_medals.has(key):
			reward_cores += 3
			bonus += 600 + trial * 120
		trial_medals[key] = maxi(rating, int(trial_medals.get(key, 0)))
	else:
		medals[str(index)] = maxi(rating, int(medals.get(str(index), 0)))
	cores += reward_cores
	add_light(bonus)
	if has("aurora"):
		energy = capacity()
	last_reward = {"bonus":bonus,"cores":reward_cores,"rating":rating,"flags":correct_flags,"earned":board_earned,"seconds":board_seconds,"region_end":index % Content.REGION_LENGTH == 15 and trial < 0}
	events.append({"type":"complete","reward":last_reward.duplicate()})

func to_dict() -> Dictionary:
	return {"version":1,"index":index,"trial":trial,"credits":credits,"cores":cores,"upgrades":upgrades,"medals":medals,"trial_medals":trial_medals,"total_light":total_light,"total_reveals":total_reveals,"total_flags":total_flags,"total_drone":total_drone,"total_strikes":total_strikes,"play_seconds":play_seconds,"board_seconds":board_seconds,"energy":energy,"probe_charge":probe_charge,"drone_clock":drone_clock,"overclock":overclock,"chain":chain,"strikes":strikes,"manual_actions":manual_actions,"board_earned":board_earned,"finished":finished,"completed_campaign":completed_campaign,"drones_enabled":drones_enabled,"last_reward":last_reward,"paid_flags":paid_flags,"seen_intro":seen_intro,"livery":livery,"board":board.to_dict()}

static func from_dict(data: Dictionary) -> GameSession:
	if int(data.get("version", 0)) != 1 or not data.get("board") is Dictionary:
		return null
	var loaded_board := MineBoard.from_dict(data.board)
	if loaded_board == null or int(data.get("index", -1)) < 0:
		return null
	for key in ["credits","cores","total_light","total_reveals","total_flags","total_drone","total_strikes","play_seconds","energy","probe_charge","strikes","chain"]:
		if not data.has(key) or not (data[key] is float or data[key] is int) or data[key] < 0 or not is_finite(float(data[key])):
			return null
	if not data.get("upgrades") is Array or not data.get("medals") is Dictionary or not data.get("trial_medals") is Dictionary:
		return null
	var result := GameSession.new()
	for key in ["index","trial","credits","cores","medals","trial_medals","total_light","total_reveals","total_flags","total_drone","total_strikes","play_seconds","board_seconds","energy","probe_charge","drone_clock","overclock","chain","strikes","manual_actions","board_earned","finished","completed_campaign","drones_enabled","last_reward","seen_intro","livery"]:
		if data.has(key):
			result.set(key, data[key])
	for id in data.upgrades:
		if not id is String or Content.upgrade(id).is_empty():
			return null
		if not result.upgrades.has(id):
			result.upgrades.append(id)
	for cell in data.get("paid_flags", []):
		result.paid_flags.append(int(cell))
	result.board = loaded_board
	result.energy = clampf(result.energy, 0, result.capacity())
	result.probe_charge = clampf(result.probe_charge, 0, 1)
	if result.finished != loaded_board.completed():
		return null
	result.events.clear()
	return result
