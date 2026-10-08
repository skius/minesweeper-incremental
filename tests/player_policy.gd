extends RefCounted

# Decisions use public tile states, plating and logical deductions only. No mine map.
static func act(s: GameSession) -> bool:
	if not s.board.generated:
		s.reveal(s.board.height/2*s.board.width+s.board.width/2)
		return true
	var b := s.board
	var best_tool := ""
	var best_cell := -1
	var best_gain := 3.0
	for id in ["cross","line","nova"]:
		if not s.tool_available(id) or s.energy < s.minimum_tool_cost(id):
			continue
		# Sample the entire field on a coarse lattice, including its edges.
		for y in range(0,b.height,2):
			for x in range(0,b.width,2):
				var target := y*b.width+x
				var cost := s.effective_tool_cost(id,target)
				if s.energy<cost:
					continue
				var gain := 0.0
				for n in s.tool_cells(id,target):
					if b.cells[n] == MineBoard.HIDDEN:
						gain += 1.0 if b.plates[n] <= s.excavation_power("tool") else 0.45
				# Prefer efficient shapes, rather than spending all energy on a tiny patch.
				gain *= 6.0/cost
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
	if s.tool_available("overdrive") and s.overdrive_seconds <= 0 and s.energy >= s.tool_cost("overdrive") and moves.safe.size() >= 8:
		return s.use_tool("overdrive")
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
