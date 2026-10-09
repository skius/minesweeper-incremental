class_name MineBoard
extends RefCounted

const HIDDEN = 0
const OPEN = 1
const FLAG = 2
const HIT = 3
const SURVEY_FORMS = ["legacy", "shelf", "shaft", "geode"]
var width: int = 8
var height: int = 7
var mine_count: int = 7
var board_seed: int = 1
var generated: bool = false
var mines: PackedByteArray = []
var clues: PackedByteArray = []
var cells: PackedByteArray = []
var pockets: PackedByteArray = []
var plates: PackedByteArray = []
var crust: int = 0
var survey_form: String = "legacy"

func setup(w: int, h: int, count: int, seed_value: int, crust_value: int = 0, form_value: String = "legacy") -> void:
	assert(form_value in SURVEY_FORMS, "Unknown survey form")
	width = w
	height = h
	mine_count = clampi(count, 1, w * h - 10)
	board_seed = seed_value
	generated = false
	crust = crust_value
	survey_form = form_value
	plates.resize(w * h)
	plates.fill(0)
	mines.resize(w * h)
	clues.resize(w * h)
	cells.resize(w * h)
	pockets.resize(w * h)
	mines.fill(0)
	clues.fill(0)
	cells.fill(0)
	pockets.fill(0)

func neighbours(i: int) -> Array[int]:
	var out: Array[int] = []
	var x := i % width
	var y := i / width
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			if x + dx >= 0 and x + dx < width and y + dy >= 0 and y + dy < height:
				out.append((y + dy) * width + x + dx)
	return out

func generate(first: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = board_seed
	var excluded := neighbours(first)
	excluded.append(first)
	var available: Array[int] = []
	for i in range(width * height):
		if not excluded.has(i):
			available.append(i)
	# Fisher-Yates avoids dependence on the global random stream.
	for i in range(available.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temp := available[i]
		available[i] = available[j]
		available[j] = temp
	for i in range(mine_count):
		mines[available[i]] = 1
	for i in range(width * height):
		var adjacent := 0
		for n in neighbours(i):
			adjacent += mines[n]
		clues[i] = adjacent
		if survey_form == "legacy" and mines[i] == 0 and not excluded.has(i) and rng.randf() < 0.07:
			pockets[i] = 1
	if survey_form == "legacy":
		# Keep the original stream exactly for old, not-yet-opened saves.
		for i in range(cells.size()):
			if not excluded.has(i) and crust > 0 and rng.randf() < 0.48:
				plates[i] = crust
	else:
		_generate_survey_terrain(excluded)
	generated = true

func _generate_survey_terrain(excluded: Array[int]) -> void:
	# Mine positions use their own unchanged shuffle. These independent streams
	# ensure terrain tuning cannot change a puzzle's mines or clue arithmetic.
	var plate_rng := RandomNumberGenerator.new()
	plate_rng.seed = board_seed ^ 0x504C4154
	var pocket_rng := RandomNumberGenerator.new()
	pocket_rng.seed = board_seed ^ 0x504F434B
	var anchors: Array[Vector2] = []
	var bands: Array[Vector2i] = []
	var radius := maxf(2.1, minf(width, height) * 0.225)
	if survey_form in ["shelf", "shaft"]:
		var span := height if survey_form == "shelf" else width
		var thickness := maxi(1, roundi(span * 0.14))
		for band in range(3):
			var jitter := plate_rng.randi_range(-1, 1) if span > 9 else 0
			var start := clampi(roundi((band + 0.5) * span / 3.0 - thickness * 0.5) + jitter, 0, span - thickness)
			bands.append(Vector2i(start, start + thickness))
			var middle := start + (thickness - 1) * 0.5
			if survey_form == "shelf":
				anchors.append(Vector2(1, middle))
				anchors.append(Vector2(width - 2, middle))
			else:
				anchors.append(Vector2(middle, 1))
				anchors.append(Vector2(middle, height - 2))
	else:
		for fraction in [Vector2(0.24,0.27), Vector2(0.76,0.34), Vector2(0.48,0.76)]:
			var p: Vector2 = fraction * Vector2(width - 1, height - 1)
			p += Vector2(plate_rng.randf_range(-0.6,0.6), plate_rng.randf_range(-0.6,0.6))
			anchors.append(p)
	var pocket_candidates: Array[Dictionary] = []
	for i in range(cells.size()):
		if excluded.has(i):
			continue
		var point := Vector2(i % width, i / width)
		var nearest := INF
		for anchor in anchors:
			var delta := (point - anchor).abs()
			var distance := point.distance_to(anchor)
			if survey_form == "shelf":
				distance = delta.x + delta.y * 2.5
			elif survey_form == "shaft":
				distance = delta.x * 2.5 + delta.y
			nearest = minf(nearest, distance)
		if crust > 0:
			if survey_form in ["shelf", "shaft"]:
				var coordinate := int(point.y) if survey_form == "shelf" else int(point.x)
				for band in bands:
					if coordinate >= band.x and coordinate < band.y:
						plates[i] = crust
			elif nearest <= radius:
				plates[i] = mini(6, crust + (1 if nearest <= radius * 0.42 else 0))
		if mines[i] == 0:
			pocket_candidates.append({"cell":i, "score":nearest + pocket_rng.randf_range(0,0.6)})
	# Fixed density, with row/column termini or compact geode clusters. All
	# pockets remain safe and never alter the truthful Minesweeper clues.
	pocket_candidates.sort_custom(func(a,b): return a.score < b.score)
	var count := mini(pocket_candidates.size(), maxi(1, roundi((width * height - mine_count) * 0.07)))
	for j in range(count):
		pockets[pocket_candidates[j].cell] = 1

func reveal(i: int) -> Array[int]:
	var changed: Array[int] = []
	if i < 0 or i >= cells.size() or cells[i] != HIDDEN:
		return changed
	if not generated:
		generate(i)
	if mines[i] == 1:
		cells[i] = HIT
		return [i]
	var pending: Array[int] = [i]
	while not pending.is_empty():
		var next: int = pending.pop_back()
		if cells[next] != HIDDEN or mines[next] == 1 or plates[next] > 0:
			continue
		cells[next] = OPEN
		changed.append(next)
		if clues[next] == 0:
			for n in neighbours(next):
				if cells[n] == HIDDEN:
					pending.append(n)
	return changed

func toggle_flag(i: int) -> bool:
	if i < 0 or i >= cells.size() or cells[i] == OPEN or cells[i] == HIT:
		return false
	cells[i] = HIDDEN if cells[i] == FLAG else FLAG
	return true

func chord_targets(i: int) -> Array[int]:
	var out: Array[int] = []
	if i < 0 or i >= cells.size() or cells[i] != OPEN or clues[i] == 0:
		return out
	var flags := 0
	for n in neighbours(i):
		if cells[n] == FLAG or cells[n] == HIT:
			flags += 1
		elif cells[n] == HIDDEN:
			out.append(n)
	if flags != clues[i]:
		out.clear()
	return out

func safe_remaining() -> int:
	var total := 0
	for i in range(cells.size()):
		if mines[i] == 0 and cells[i] != OPEN:
			total += 1
	return total if generated else width * height - mine_count

func open_count() -> int:
	return cells.count(OPEN)

func completed() -> bool:
	return generated and safe_remaining() == 0

# Deductions only inspect revealed clues, not hidden mine data. Player flags are
# excluded from solver knowledge: an incorrect player flag must not poison a bot.
func deductions(advanced: bool = false) -> Dictionary:
	var known: Dictionary = {}
	for i in range(cells.size()):
		if cells[i] == HIT:
			known[i] = true
	var safe: Dictionary = {}
	var groups: Array = []
	for _pass in range(5):
		groups.clear()
		var previous := known.size() + safe.size()
		for i in range(cells.size()):
			if cells[i] != OPEN:
				continue
			var unknown: Array[int] = []
			var remaining := int(clues[i])
			for n in neighbours(i):
				if known.has(n):
					remaining -= 1
				elif cells[n] != OPEN and not safe.has(n):
					unknown.append(n)
			if unknown.is_empty():
				continue
			if remaining == 0:
				for n in unknown:
					safe[n] = true
			elif remaining == unknown.size():
				for n in unknown:
					known[n] = true
			elif remaining > 0:
				groups.append({"cells":unknown,"mines":remaining})
		if advanced:
			for a in groups:
				for b in groups:
					if a.cells.size() >= b.cells.size():
						continue
					var subset := true
					for n in a.cells:
						if not b.cells.has(n):
							subset = false
							break
					if not subset:
						continue
					var difference: Array[int] = []
					for n in b.cells:
						if not a.cells.has(n):
							difference.append(n)
					var count: int = b.mines - a.mines
					if count == 0:
						for n in difference:
							safe[n] = true
					elif count == difference.size():
						for n in difference:
							known[n] = true
		if previous == known.size() + safe.size():
			break
	var result_safe: Array[int] = []
	var result_mines: Array[int] = []
	for n in safe:
		if cells[n] != OPEN:
			result_safe.append(n)
	for n in known:
		if cells[n] != FLAG and cells[n] != HIT:
			result_mines.append(n)
	return {"safe":result_safe,"mines":result_mines}

func safe_probe() -> int:
	if not generated:
		return (height / 2) * width + width / 2
	# Prefer a frontier tile with a nonzero clue, to create useful information.
	var fallback := -1
	for i in range(cells.size()):
		if mines[i] != 0 or cells[i] == OPEN:
			continue
		if fallback == -1:
			fallback = i
		for n in neighbours(i):
			if cells[n] == OPEN:
				return i
	return fallback

func to_dict() -> Dictionary:
	return {"width":width,"height":height,"mine_count":mine_count,"seed":board_seed,"generated":generated,"mines":Array(mines),"clues":Array(clues),"cells":Array(cells),"pockets":Array(pockets),"plates":Array(plates),"crust":crust,"form":survey_form}

# Pulse may penetrate its target plate, but the flood still respects all other
# plating and flags. Deep scanner compares the actual resulting openings.
func opening_size(target: int) -> int:
	if target<0 or target>=cells.size() or mines[target]!=0 or cells[target]==OPEN:
		return 0
	var visited: Dictionary={}
	var pending: Array[int]=[target]
	while not pending.is_empty():
		var i: int=pending.pop_back()
		if visited.has(i) or mines[i]!=0 or cells[i]==OPEN:
			continue
		if i!=target and (cells[i]!=HIDDEN or plates[i]>0):
			continue
		visited[i]=true
		if clues[i]==0:
			for n in neighbours(i):
				pending.append(n)
	return visited.size()

static func from_dict(data: Dictionary) -> MineBoard:
	if not validate(data):
		return null
	var b := MineBoard.new()
	b.setup(int(data.width), int(data.height), int(data.mine_count), int(data.seed), int(data.get("crust",0)), data.get("form","legacy"))
	b.generated = data.generated
	b.mines = PackedByteArray(data.mines)
	b.clues = PackedByteArray(data.clues)
	b.cells = PackedByteArray(data.cells)
	b.pockets = PackedByteArray(data.pockets)
	b.crust = int(data.get("crust",0))
	if data.has("plates"):
		b.plates = PackedByteArray(data.plates)
	return b

static func validate(data: Dictionary) -> bool:
	for key in ["width","height","mine_count","seed","generated","mines","clues","cells","pockets"]:
		if not data.has(key):
			return false
	for key in ["width","height","mine_count","seed"]:
		if not integer_value(data[key],-9_000_000_000_000_000,9_000_000_000_000_000):
			return false
	if not data.generated is bool or not integer_value(data.get("crust",0),0,12):
		return false
	if not data.get("form", "legacy") is String or data.get("form", "legacy") not in SURVEY_FORMS:
		return false
	var w := int(data.width)
	var h := int(data.height)
	if w < 4 or w > 32 or h < 4 or h > 24 or int(data.mine_count) < 1 or int(data.mine_count) > w * h - 10:
		return false
	for key in ["mines","clues","cells","pockets"]:
		if not data[key] is Array or data[key].size() != w * h:
			return false
		var upper := 8 if key == "clues" else (3 if key == "cells" else 1)
		for value in data[key]:
			if not integer_value(value,0,upper):
				return false
	if data.has("plates"):
		if not data.plates is Array or data.plates.size() != w*h:
			return false
		for value in data.plates:
			if not integer_value(value,0,12):
				return false
	if data.generated:
		var counted_mines := 0
		for value in data.mines:
			counted_mines += int(value)
		if counted_mines != int(data.mine_count):
			return false
		for i in range(w * h):
			if int(data.cells[i]) == OPEN and int(data.mines[i]) == 1:
				return false
			if int(data.cells[i]) == HIT and int(data.mines[i]) == 0:
				return false
			if data.has("plates") and int(data.cells[i]) in [OPEN,HIT] and data.plates[i]>0:
				return false
			if int(data.pockets[i])==1 and int(data.mines[i])==1:
				return false
			var count := 0
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var x := i % w + dx
					var y := i / w + dy
					if (dx != 0 or dy != 0) and x >= 0 and x < w and y >= 0 and y < h:
						count += int(data.mines[y * w + x])
			if count != int(data.clues[i]):
				return false
	else:
		for i in range(w*h):
			if int(data.cells[i]) not in [HIDDEN,FLAG]:
				return false
			if data.mines[i]!=0 or data.clues[i]!=0 or data.pockets[i]!=0 or (data.has("plates") and data.plates[i]!=0):
				return false
	return true

static func integer_value(value: Variant, minimum: int = 0, maximum: int = 9_000_000_000_000_000) -> bool:
	if not (value is int or value is float):
		return false
	if not is_finite(float(value)) or value<minimum or value>maximum:
		return false
	return value==int(value)

static func number_value(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value>=0 and value<=9_000_000_000_000_000
