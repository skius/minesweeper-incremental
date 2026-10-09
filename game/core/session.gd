class_name GameSession
extends RefCounted

var board := MineBoard.new()
var index: int = 0
var stratum: int = 0
var layer_ready: bool = false
var descent_clock: float = 0
var excavations: int = 0
var manual_excavations: int = 0
var action_depth: int = 0
var cascade_guard: bool = false
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
var overdrive_seconds: float = 0.0
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
	return trial/2 if trial>=0 else Content.region_for(index)

func capacity() -> float:
	return 40.0 if has("supercap") else (24.0 if has("nova") or has("overdrive") else (18.0 if has("battery") else 10.0))

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
	stratum = 0
	layer_ready = false
	var spec := Content.contract(index, trial, stratum)
	board.setup(spec.width, spec.height, spec.mines, spec.seed, spec.crust, spec.form)
	board_seconds = 0
	energy = capacity()
	probe_charge = 1
	drone_clock = 0
	overclock = 0
	overdrive_seconds = 0
	if not has("legacy"):
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
	if id == "reservoir":
		probe_charge = 2
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
	action_depth+=1
	_reveal(i,source)
	action_depth-=1
	check_completion()

func break_plates(i: int, power: int, source: String) -> int:
	var removed := mini(power,board.plates[i])
	if removed<=0:
		return 0
	board.plates[i]-=removed
	excavations+=1
	if source=="manual":
		manual_excavations+=1
	add_light(removed*(1+region()))
	if has("crucible") or (source=="manual" and has("kinetic")):
		energy=minf(capacity(),energy+removed*0.65)
		probe_charge=minf(probe_capacity(),probe_charge+0.08)
	events.append({"type":"excavate","cell":i,"amount":removed,"broken":board.plates[i]==0,"source":source})
	return removed

func _reveal(i: int, source: String = "manual") -> void:
	if finished or layer_ready or i < 0 or i >= board.cells.size():
		return
	if board.cells[i] == MineBoard.OPEN:
		if source == "manual":
			chord(i)
		return
	var first := not board.generated
	if board.generated and board.cells[i] == MineBoard.HIDDEN and board.plates[i] > 0:
		var power := excavation_power(source)
		break_plates(i,power,source)
		if board.plates[i] == 0 and has("fracture") and source == "manual":
			for n in board.neighbours(i):
				break_plates(n,1,"fracture")
		if source == "manual" and has("seismic") and manual_excavations%6 == 0:
			events.append({"type":"seismic","cell":i})
			for n in cross_cells(i):
				if board.mines[n] == 0:
					reveal(n,"echo")
		if board.plates[i] > 0:
			return
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
			if has("sentry") and has("shield") and strikes == 1:
				probe_one("rescue")
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
			probe_charge = minf(probe_capacity(), probe_charge + 0.035)
		earned += value
	if has("echochamber") and board.clues[i] == 0 and not changed.is_empty():
		probe_charge = minf(probe_capacity(),probe_charge + 1)
	add_light(earned)
	events.append({"type":"reveal","cells":changed,"amount":earned,"source":source,"chain":chain})
	for pocket in pockets:
		if has("magnet") and source != "echo":
			for _extra in range(2):
				probe_one("echo",pocket)
		if region() == 4:
			for n in range(board.cells.size()):
				if board.mines[n] == 1 and board.cells[n] == MineBoard.HIDDEN:
					board.toggle_flag(n)
					events.append({"type":"flag","cell":n,"auto":true})
					break
		if has("prism") and source != "echo":
			probe_one("echo",pocket)
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
	if finished or layer_ready:
		return
	if board.toggle_flag(i):
		events.append({"type":"flag","cell":i,"auto":false})

func chord(i: int) -> void:
	action_depth+=1
	_chord(i)
	action_depth-=1
	check_completion()

func _chord(i: int) -> void:
	if finished:
		return
	var targets := board.chord_targets(i)
	if has("conductor") and i >= 0 and i < board.cells.size() and board.cells[i] == MineBoard.OPEN:
		targets.clear()
		var proved: Array = board.deductions(true).safe
		for n in board.neighbours(i):
			if proved.has(n):
				targets.append(n)
				if board.cells[n]==MineBoard.FLAG:
					board.cells[n]=MineBoard.HIDDEN
	if targets.is_empty():
		events.append({"type":"blocked_action","reason":"flags","cell":i})
		return
	var strikes_before := strikes
	for n in targets:
		if board.cells[n] == MineBoard.HIDDEN:
			reveal(n, "manual")
	if strikes == strikes_before:
		if has("flywheel"):
			probe_charge = minf(probe_capacity(),probe_charge+1)
		if has("synchrony") and not cascade_guard:
			cascade_guard = true
			drone_cycle()
			cascade_guard = false
	if has("chord") and strikes==strikes_before and not finished:
		for _pass in range(5):
			var any := false
			var safe: Array=board.deductions(true).safe
			for cell in range(board.cells.size()):
				for n in board.chord_targets(cell):
					if board.cells[n] == MineBoard.HIDDEN and safe.has(n):
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
	if has("diagonal"):
		for dx in [-2,-1,1,2]:
			for sign_value in [-1,1]:
				var x: int = i % board.width + dx
				var y: int = i / board.width + dx*sign_value
				if x>=0 and y>=0 and x<board.width and y<board.height:
					result.append(y*board.width+x)
	return result

func tool_cost(id: String) -> float:
	return {"probe":0.0,"cross":6.0,"line":10.0,"nova":16.0,"overdrive":12.0}.get(id, 999.0)

func minimum_tool_cost(id: String) -> float:
	return 2.0 if has("recycler") and id in ["cross","line","nova"] else tool_cost(id)

func tool_available(id: String) -> bool:
	return (id=="probe" or has(id)) and not (trial>=0 and trial%2==0 and id!="probe")

func effective_tool_cost(id: String, i: int) -> float:
	var cost := tool_cost(id)
	if not has("recycler") or id not in ["cross","line","nova"]:
		return cost
	var targets := tool_cells(id,i)
	if targets.is_empty():
		return cost
	var open_tiles := 0
	for n in targets:
		open_tiles+=1 if board.cells[n]==MineBoard.OPEN else 0
	return maxf(2,cost*(1-float(open_tiles)/targets.size()))

func tool_cells(id: String, i: int) -> Array[int]:
	var result: Array[int] = []
	if i < 0 or i >= board.cells.size():
		return result
	if id == "cross":
		return cross_cells(i)
	if id == "line":
		for x in range(board.width):
			result.append((i / board.width) * board.width + x)
		if has("vertical"):
			for y in range(board.height):
				var n := y*board.width+i%board.width
				if not result.has(n):
					result.append(n)
	if id == "nova":
		var radius := 3 if has("aftershock") else 2
		for y in range(maxi(0, i / board.width - radius), mini(board.height, i / board.width + radius+1)):
			for x in range(maxi(0, i % board.width - radius), mini(board.width, i % board.width + radius+1)):
				result.append(y * board.width + x)
	return result

func use_tool(id: String, i: int = -1) -> bool:
	action_depth+=1
	var used := _use_tool(id,i)
	action_depth-=1
	check_completion()
	return used

func _use_tool(id: String, i: int = -1) -> bool:
	if finished or layer_ready or not tool_available(id):
		return false
	if id == "probe":
		if probe_charge < 1:
			return false
		probe_charge -= 1
		var count := 3 if has("prism") else (2 if has("probe2") else 1)
		for _j in range(count):
			probe_one("tool",i if has("focus") else -1)
		events.append({"type":"tool","id":id,"cell":i})
		return true
	if energy < effective_tool_cost(id,i):
		events.append({"type":"blocked_action","reason":"energy","cell":i})
		return false
	if id == "overdrive":
		if overdrive_seconds>0:
			return false
		energy -= tool_cost(id)
		overdrive_seconds = 12
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
		events.append({"type":"blocked_action","reason":"empty","cell":i})
		return false
	energy -= effective_tool_cost(id,i)
	for n in targets:
		if has("harvester") and board.mines[n] == 1 and board.cells[n] == MineBoard.HIDDEN:
			board.toggle_flag(n)
			events.append({"type":"flag","cell":n,"auto":true})
		if id == "nova" and has("aftershock"):
			break_plates(n,board.plates[n],"blast")
		if board.mines[n] == 0:
			if board.cells[n] == MineBoard.FLAG:
				board.cells[n] = MineBoard.HIDDEN
			reveal(n, "tool")
	events.append({"type":"tool","id":id,"cell":i})
	return true

func probe_one(source: String, target: int = -1) -> void:
	var cell := board.safe_probe()
	if board.generated and (target >= 0 or has("cartogram")):
		var best := -1000000.0
		for i in range(board.cells.size()):
			if board.mines[i] != 0 or board.cells[i] == MineBoard.OPEN:
				continue
			var score := 0.0
			if target >= 0:
				score = -Vector2(i%board.width,i/board.width).distance_squared_to(Vector2(target%board.width,target/board.width))
			else:
				score = board.opening_size(i)
			if score > best:
				best = score
				cell = i
	if cell >= 0:
		if board.cells[cell] == MineBoard.FLAG:
			board.cells[cell] = MineBoard.HIDDEN
		break_plates(cell,board.plates[cell],"pulse")
		reveal(cell, source)

func tick(delta: float) -> void:
	if layer_ready:
		if has("autodescent") and drones_enabled:
			descent_clock += delta
			if descent_clock >= 1.2:
				advance_layer()
		return
	if not board.generated and has("launchpad") and drones_enabled and not (trial>=0 and trial%2==0):
		drone_clock += delta
		if drone_clock >= 1.0:
			probe_one("drone")
	if finished:
		return
	play_seconds += delta
	if not board.generated:
		return
	board_seconds += delta
	energy = minf(capacity(), energy + delta * (0.6 if has("capacitor") else 0.3))
	probe_charge = minf(probe_capacity(), probe_charge + delta / 9.0)
	overclock = maxf(0, overclock - delta)
	overdrive_seconds = maxf(0,overdrive_seconds-delta)
	if drone_count() == 0 or not drones_enabled or (trial >= 0 and trial % 2 == 0):
		return
	drone_clock += delta
	var interval := 0.3 if overdrive_seconds>0 else (0.85 if overclock > 0 else 3.0)
	if drone_clock >= interval:
		drone_clock = fmod(drone_clock, interval)
		drone_cycle()

func drone_cycle() -> void:
	for _j in range(drone_count()):
		if finished or layer_ready or board.completed():
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
	if action_depth>0 or finished or layer_ready or not board.completed():
		return
	var correct_flags := 0
	for i in range(board.cells.size()):
		if board.cells[i] == MineBoard.FLAG and board.mines[i] == 1:
			correct_flags += 1
	total_flags += correct_flags
	var flag_reward := correct_flags*8 if has("salvage") else 0
	add_light(flag_reward)
	if has("aurora"):
		energy=capacity()
	if flag_reward>0:
		events.append({"type":"salvage","amount":flag_reward,"flags":correct_flags})
	if stratum+1 < Content.strata_for(index,trial):
		layer_ready = true
		descent_clock = 0
		add_light(40+region()*30)
		# First-time layer completions feed research, so branches do not grind on light alone.
		if stratum%3 == 2:
			cores += 1
		events.append({"type":"layer_complete"})
		return
	finished = true
	var rating := 3 if strikes == 0 else (2 if strikes <= 2 else 1)
	var bonus := 70 + index * 12
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
	last_reward = {"bonus":bonus+flag_reward,"cores":reward_cores,"rating":rating,"flags":correct_flags,"earned":board_earned,"seconds":board_seconds,"region_end":index % Content.REGION_LENGTH == 15 and trial < 0}
	events.append({"type":"complete","reward":last_reward.duplicate()})

func to_dict() -> Dictionary:
	return {"version":2,"stratum":stratum,"layer_ready":layer_ready,"excavations":excavations,"manual_excavations":manual_excavations,"index":index,"trial":trial,"credits":credits,"cores":cores,"upgrades":upgrades,"medals":medals,"trial_medals":trial_medals,"total_light":total_light,"total_reveals":total_reveals,"total_flags":total_flags,"total_drone":total_drone,"total_strikes":total_strikes,"play_seconds":play_seconds,"board_seconds":board_seconds,"energy":energy,"probe_charge":probe_charge,"drone_clock":drone_clock,"overclock":overclock,"overdrive_seconds":overdrive_seconds,"descent_clock":descent_clock,"chain":chain,"strikes":strikes,"manual_actions":manual_actions,"board_earned":board_earned,"finished":finished,"completed_campaign":completed_campaign,"drones_enabled":drones_enabled,"last_reward":last_reward,"paid_flags":paid_flags,"seen_intro":seen_intro,"livery":livery,"board":board.to_dict()}

static func from_dict(data: Dictionary) -> GameSession:
	if not MineBoard.integer_value(data.get("version"),1,2) or not data.get("board") is Dictionary:
		return null
	var loaded_board := MineBoard.from_dict(data.board)
	if loaded_board == null:
		return null
	for key in ["index","credits","cores","total_light","total_reveals","total_flags","total_drone","total_strikes","strikes","chain"]:
		if not MineBoard.integer_value(data.get(key)):
			return null
	for key in ["stratum","excavations","manual_excavations","manual_actions","board_earned"]:
		if not MineBoard.integer_value(data.get(key,0)):
			return null
	for key in ["play_seconds","energy","probe_charge"]:
		if not MineBoard.number_value(data.get(key)):
			return null
	for key in ["board_seconds","drone_clock","overclock","overdrive_seconds","descent_clock"]:
		if not MineBoard.number_value(data.get(key,0)):
			return null
	for key in ["finished","completed_campaign","drones_enabled","seen_intro","layer_ready"]:
		if data.has(key) and not data[key] is bool:
			return null
	if not MineBoard.integer_value(data.get("trial",-1),-1,11) or not MineBoard.integer_value(data.get("livery",0),0,2):
		return null
	if not data.get("upgrades") is Array or not data.get("paid_flags",[]) is Array:
		return null
	if not valid_medals(data.get("medals")) or not valid_medals(data.get("trial_medals"),11):
		return null
	if not data.get("last_reward",{}) is Dictionary:
		return null
	if data.get("finished",false) and not valid_reward(data.get("last_reward",{})):
		return null
	var result := GameSession.new()
	for key in ["stratum","layer_ready","excavations","manual_excavations","index","trial","credits","cores","medals","trial_medals","total_light","total_reveals","total_flags","total_drone","total_strikes","play_seconds","board_seconds","energy","probe_charge","drone_clock","overclock","overdrive_seconds","descent_clock","chain","strikes","manual_actions","board_earned","finished","completed_campaign","drones_enabled","last_reward","seen_intro","livery"]:
		if data.has(key):
			result.set(key, data[key].duplicate(true) if data[key] is Dictionary or data[key] is Array else data[key])
	for id in data.upgrades:
		if not id is String or Content.upgrade(id).is_empty():
			return null
		if not result.upgrades.has(id):
			result.upgrades.append(id)
	for cell in data.get("paid_flags", []):
		if not MineBoard.integer_value(cell,0,loaded_board.cells.size()-1):
			return null
		if not result.paid_flags.has(int(cell)):
			result.paid_flags.append(int(cell))
	result.board = loaded_board
	result.energy = clampf(result.energy, 0, result.capacity())
	result.probe_charge = clampf(result.probe_charge, 0, result.probe_capacity())
	if (result.finished or result.layer_ready) != loaded_board.completed() or result.stratum < 0 or result.stratum >= Content.strata_for(result.index,result.trial):
		return null
	if result.finished and result.layer_ready:
		return null
	if result.layer_ready and result.stratum+1>=Content.strata_for(result.index,result.trial):
		return null
	result.events.clear()
	return result

static func valid_medals(value: Variant, maximum: int = 9_000_000_000_000_000) -> bool:
	if not value is Dictionary:
		return false
	for key in value:
		if not key is String or key.length()>16 or not key.is_valid_int():
			return false
		if not MineBoard.integer_value(key.to_int(),0,maximum) or not MineBoard.integer_value(value[key],1,3):
			return false
	return true

static func valid_reward(value: Dictionary) -> bool:
	for key in ["bonus","cores","flags","earned"]:
		if not MineBoard.integer_value(value.get(key)):
			return false
	return MineBoard.integer_value(value.get("rating"),1,3) and MineBoard.number_value(value.get("seconds")) and value.get("region_end") is bool

func probe_capacity() -> float:
	return 2.0 if has("reservoir") else 1.0

func excavation_power(source: String) -> int:
	if has("legacy"):
		return 6
	if source == "manual" and has("drill"):
		return 3
	if source == "drone" and has("excavator"):
		return 3
	if source in ["tool","echo"] and has("perforator"):
		return 4
	return 1

func advance_layer() -> bool:
	if not layer_ready:
		return false
	stratum += 1
	layer_ready = false
	var spec := Content.contract(index,trial,stratum)
	board.setup(spec.width,spec.height,spec.mines,spec.seed,spec.crust,spec.form)
	drone_clock = 0
	if not has("legacy"):
		chain = 0
	energy = minf(capacity(),energy+4)
	probe_charge = maxf(1,probe_charge)
	paid_flags.clear()
	events.append({"type":"new_layer"})
	return true
