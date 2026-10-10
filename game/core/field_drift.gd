class_name FieldDrift
extends RefCounted

# A separate deterministic stream owns movement. Worked ground never moves;
# focus protection includes a halo so every clue inside the frame stays true.
var enabled := false
var period := 12.0
var strength := 1
var remaining := 12.0
var sequence := 0
var focus := -1
var radius := 2
var stasis := 0.0
var converged := false
var surveyed: PackedByteArray = []
var anchors: PackedByteArray = []
var traces: PackedByteArray = []
var grace: PackedFloat32Array = []

func setup(board: MineBoard, index: int, trial: int) -> void:
	enabled = index >= 32 and trial < 0
	strength = clampi(1 + (index-32)/16, 1, 4)
	period = 14.0 - strength*2.0
	remaining = period
	surveyed.resize(board.cells.size())
	anchors.resize(board.cells.size())
	traces.resize(board.cells.size())
	grace.resize(board.cells.size())

func area(board: MineBoard, cell: int, extent: int) -> Array[int]:
	var result: Array[int] = []
	if cell < 0 or cell >= board.cells.size():
		return result
	for y in range(maxi(0,cell/board.width-extent),mini(board.height,cell/board.width+extent+1)):
		for x in range(maxi(0,cell%board.width-extent),mini(board.width,cell%board.width+extent+1)):
			result.append(y*board.width+x)
	return result

func set_focus(board: MineBoard, cell: int, extent: int) -> void:
	if cell < 0 or cell >= board.cells.size() or (cell == focus and radius == extent):
		return
	for n in area(board,focus,radius+1):
		grace[n] = 1.5
	focus = cell
	radius = extent

func anchor_area(board: MineBoard, cell: int, extent: int) -> bool:
	var changed := false
	for n in area(board,cell,extent):
		changed = changed or anchors[n] == 0
		anchors[n] = 1
	return changed

func tick(board: MineBoard, delta: float) -> bool:
	if not enabled or not board.generated or converged:
		return false
	for i in range(grace.size()):
		grace[i] = maxf(0,grace[i]-delta)
	if stasis > 0:
		var frozen_time := minf(stasis,delta)
		stasis -= frozen_time
		delta -= frozen_time
	remaining -= delta
	if remaining > 0:
		return false
	# At most one visible wave per frame, including after a long OS stall.
	remaining = period
	return true

func move_mines(board: MineBoard) -> Dictionary:
	sequence += 1
	var blocked: Dictionary = {}
	for n in area(board,focus,radius+1):
		blocked[n] = true
	for i in range(board.cells.size()):
		if grace[i] > 0 or surveyed[i] > 0 or board.cells[i] != MineBoard.HIDDEN or board.pockets[i] > 0:
			blocked[i] = true
		if anchors[i] > 0:
			blocked[i] = true
			for n in board.neighbours(i):
				blocked[n] = true
	var rng := RandomNumberGenerator.new()
	rng.seed = board.board_seed ^ 0x44524946 ^ (sequence * 104729)
	var sources: Array[int] = []
	for i in range(board.cells.size()):
		if board.mines[i] == 1 and not blocked.has(i):
			sources.append(i)
	for j in range(sources.size()-1,0,-1):
		var k := rng.randi_range(0,j)
		var temp := sources[j]
		sources[j] = sources[k]
		sources[k] = temp
	var moves: Array = []
	var old_clues := board.clues.duplicate()
	for source in sources:
		if moves.size() >= strength:
			break
		if blocked.has(source):
			continue
		var targets: Array[int] = []
		for n in board.neighbours(source):
			if absi(n%board.width-source%board.width)+absi(n/board.width-source/board.width) == 1 and not blocked.has(n) and board.mines[n] == 0:
				targets.append(n)
		if targets.is_empty():
			continue
		var target := targets[rng.randi_range(0,targets.size()-1)]
		board.mines[source] = 0
		board.mines[target] = 1
		blocked[source] = true
		blocked[target] = true
		moves.append([source,target])
	var changed: Array[int] = []
	if not moves.is_empty():
		for i in range(board.cells.size()):
			var count := 0
			for n in board.neighbours(i):
				count += board.mines[n]
			board.clues[i] = count
			if board.cells[i] == MineBoard.OPEN and count != old_clues[i]:
				changed.append(i)
	return {"moves":moves,"clues":changed}

func to_dict() -> Dictionary:
	return {"enabled":enabled,"remaining":remaining,"sequence":sequence,"focus":focus,"radius":radius,"stasis":stasis,"converged":converged,"surveyed":Array(surveyed),"anchors":Array(anchors),"traces":Array(traces),"grace":Array(grace)}

static func restore(data: Dictionary, board: MineBoard, index: int, trial: int) -> FieldDrift:
	var result := FieldDrift.new()
	result.setup(board,index,trial)
	if not data.get("enabled") is bool or not data.get("converged") is bool:
		return null
	if data.enabled and not result.enabled:
		return null
	for key in ["remaining","stasis"]:
		if not MineBoard.number_value(data.get(key)) or data[key] > 14:
			return null
	if not MineBoard.integer_value(data.get("sequence")) or not MineBoard.integer_value(data.get("focus"),-1,board.cells.size()-1) or not MineBoard.integer_value(data.get("radius"),2,3):
		return null
	for key in ["surveyed","anchors","traces","grace"]:
		if not data.get(key) is Array or data[key].size() != board.cells.size():
			return null
		for value in data[key]:
			if key == "grace":
				if not MineBoard.number_value(value) or value > 1.5:
					return null
			elif not MineBoard.integer_value(value,0,1):
				return null
	for i in range(board.cells.size()):
		if data.traces[i] == 1 and (board.mines[i] != 0 or data.surveyed[i] != 1):
			return null
	for key in ["enabled","remaining","sequence","focus","radius","stasis","converged"]:
		result.set(key,data[key])
	result.surveyed = PackedByteArray(data.surveyed)
	result.anchors = PackedByteArray(data.anchors)
	result.traces = PackedByteArray(data.traces)
	result.grace = PackedFloat32Array(data.grace)
	return result
