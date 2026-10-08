extends RefCounted

# Adversarial, checksum-valid saves exercise the semantic loader rather than
# only checksum rejection. The host test runner supplies its normal check().
# All files remain beneath an isolated test_runs directory.
static func run(check: Callable) -> void:
	var store := SaveStore.new()
	check.call(store.directory != "user://", "save validation suite requires isolated test arguments")
	if store.directory == "user://":
		return
	store.directory = ProjectSettings.globalize_path("res://test_runs/save_validation_%d_%d/" % [OS.get_process_id(), Time.get_ticks_usec()])
	var directory_error := DirAccess.make_dir_recursive_absolute(store.directory)
	check.call(directory_error == OK, "create isolated adversarial save directory")
	if directory_error != OK:
		return

	var source := GameSession.new()
	source.index = 20
	source.start_board()
	source.reveal(40)
	source.credits = 1234
	source.cores = 7
	source.total_light = 2000000
	var baseline := source.to_dict()
	check.call(not source.finished and not source.layer_ready, "adversarial baseline is an active plated field")
	check.call(GameSession.from_dict(_json_copy(baseline)) != null, "ordinary JSON-number save remains accepted")
	var backup := baseline.duplicate(true)
	backup.credits = 876543
	check.call(_write_payload(store.path("expedition.backup.json"), backup), "write known-good isolated backup")
	check.call(_write_payload(store.path("expedition.json"), baseline), "write known-good isolated primary")
	var healthy := store.load_session()
	check.call(healthy != null and healthy.credits == 1234 and store.notice.is_empty(), "valid primary takes precedence over backup")

	var cases: Array[Dictionary] = []
	for malformed in [null, [], "not a session", 42, true]:
		cases.append({"name":"non-dictionary payload %s" % str(malformed), "payload":malformed})
	for key in ["version", "index", "credits", "cores", "total_light", "total_reveals", "total_flags", "total_drone", "total_strikes", "strikes", "chain"]:
		for value in [null, [], {}, "2", true, 2.5]:
			_add_case(cases, "%s rejects %s" % [key, str(value)], baseline, [key], value)
		var missing := baseline.duplicate(true)
		missing.erase(key)
		cases.append({"name":"missing required " + key, "payload":missing})
	for key in ["index", "credits", "cores", "total_light", "total_reveals", "total_flags", "total_drone", "total_strikes", "strikes", "chain", "stratum", "excavations", "manual_excavations", "manual_actions", "board_earned"]:
		_add_case(cases, "negative " + key, baseline, [key], -1)
	for key in ["stratum", "excavations", "manual_excavations", "manual_actions", "board_earned", "livery"]:
		for value in [[], "0", 0.5]:
			_add_case(cases, "%s rejects %s" % [key, str(value)], baseline, [key], value)
	for key in ["play_seconds", "board_seconds", "energy", "probe_charge", "drone_clock", "overclock"]:
		for value in [null, [], {}, "1.0", true, -0.5]:
			_add_case(cases, "%s rejects %s" % [key, str(value)], baseline, [key], value)
	for key in ["finished", "completed_campaign", "drones_enabled", "seen_intro", "layer_ready"]:
		for value in [null, [], "false", 1]:
			_add_case(cases, "%s requires a boolean (%s)" % [key, str(value)], baseline, [key], value)
	for value in [-2, 12, 0.5, [], "0", true]:
		_add_case(cases, "invalid trial %s" % str(value), baseline, ["trial"], value)
	for value in [-1, 3, 0.5]:
		_add_case(cases, "invalid livery %s" % str(value), baseline, ["livery"], value)
	_add_case(cases, "stratum exceeds this site's depth", baseline, ["stratum"], Content.strata_for(source.index))
	_add_case(cases, "unsupported save version", baseline, ["version"], 999)
	_add_case(cases, "active field cannot claim finished", baseline, ["finished"], true)
	_add_case(cases, "active field cannot claim layer complete", baseline, ["layer_ready"], true)

	for key in ["upgrades", "paid_flags"]:
		for value in [null, {}, "lens", true]:
			_add_case(cases, "%s must be an array (%s)" % [key, str(value)], baseline, [key], value)
	for value in [["missing_upgrade"], [4], [{}], [null]]:
		_add_case(cases, "invalid upgrade entries %s" % str(value), baseline, ["upgrades"], value)
	for value in [[-1], [source.board.cells.size()], [0.5], ["0"], [{}], [null]]:
		_add_case(cases, "invalid paid-flag entries %s" % str(value), baseline, ["paid_flags"], value)
	for key in ["medals", "trial_medals", "last_reward"]:
		for value in [null, [], "record", true]:
			_add_case(cases, "%s must be a dictionary (%s)" % [key, str(value)], baseline, [key], value)
	for value in [{"0":[]}, {"0":"3"}, {"0":0}, {"0":4}, {"0":1.5}, {"-1":3}, {"invalid":3}]:
		_add_case(cases, "invalid campaign medal %s" % str(value), baseline, ["medals"], value)
	for value in [{"0":[]}, {"0":"3"}, {"0":0}, {"0":4}, {"0":1.5}, {"-1":3}, {"12":3}, {"invalid":3}]:
		_add_case(cases, "invalid trial medal %s" % str(value), baseline, ["trial_medals"], value)

	for value in [null, [], true, "board"]:
		_add_case(cases, "board must be a dictionary (%s)" % str(value), baseline, ["board"], value)
	for key in ["width", "height", "mine_count", "seed", "crust"]:
		for value in [null, [], {}, "12", true, 4.5]:
			_add_case(cases, "board %s rejects %s" % [key, str(value)], baseline, ["board", key], value)
	for value in [3, 33]:
		_add_case(cases, "invalid board width %d" % value, baseline, ["board", "width"], value)
	for value in [3, 25]:
		_add_case(cases, "invalid board height %d" % value, baseline, ["board", "height"], value)
	for value in [-1, 0, source.board.cells.size()]:
		_add_case(cases, "invalid mine count %d" % value, baseline, ["board", "mine_count"], value)
	for value in [-1, 13]:
		_add_case(cases, "invalid crust %d" % value, baseline, ["board", "crust"], value)
	for value in [null, [], "true", 1]:
		_add_case(cases, "generated requires boolean (%s)" % str(value), baseline, ["board", "generated"], value)
	for key in ["mines", "clues", "cells", "pockets", "plates"]:
		for value in [null, {}, "array", true]:
			_add_case(cases, "%s requires array (%s)" % [key, str(value)], baseline, ["board", key], value)
		var short_array: Array = baseline.board[key].duplicate()
		short_array.pop_back()
		_add_case(cases, key + " length mismatch", baseline, ["board", key], short_array)
		for value in [-1, 99, 0.5, "0", true, null, {}]:
			_add_case(cases, "%s invalid cell %s" % [key, str(value)], baseline, ["board", key, 0], value)

	var safe_cell := -1
	var open_cell := -1
	var mine_cell := -1
	for i in range(source.board.cells.size()):
		if source.board.mines[i] == 0 and safe_cell < 0:
			safe_cell = i
		if source.board.cells[i] == MineBoard.OPEN and open_cell < 0:
			open_cell = i
		if source.board.mines[i] == 1 and mine_cell < 0:
			mine_cell = i
	check.call(safe_cell >= 0 and open_cell >= 0 and mine_cell >= 0, "state-corruption fixtures have safe/open/mined cells")
	if safe_cell >= 0 and open_cell >= 0 and mine_cell >= 0:
		_add_case(cases, "HIT on safe tile would make field impossible", baseline, ["board", "cells", safe_cell], MineBoard.HIT)
		_add_case(cases, "OPEN mine is impossible", baseline, ["board", "cells", mine_cell], MineBoard.OPEN)
		_add_case(cases, "opened tile cannot retain plating", baseline, ["board", "plates", open_cell], 1)
		_add_case(cases, "crystal pocket cannot occupy a mine", baseline, ["board", "pockets", mine_cell], 1)
		_add_case(cases, "clue does not match actual adjacent mines", baseline, ["board", "clues", open_cell], (int(baseline.board.clues[open_cell]) + 1) % 9)

	var unopened := GameSession.new().to_dict()
	for state in [MineBoard.OPEN, MineBoard.HIT]:
		_add_case(cases, "ungenerated board rejects cell state %d" % state, unopened, ["board", "cells", 0], state)
	for key in ["mines", "clues", "pockets", "plates"]:
		_add_case(cases, "ungenerated board rejects populated " + key, unopened, ["board", key, 0], 1)
	unopened.board.cells[0] = MineBoard.FLAG
	check.call(GameSession.from_dict(_json_copy(unopened)) != null, "flag before first opening remains a valid save")

	var complete := GameSession.new()
	var guard := 0
	while not complete.finished and guard < 1000:
		guard += 1
		complete.probe_one("tool")
	check.call(complete.finished, "completion fixture reached its reward")
	if complete.finished:
		var completed := complete.to_dict()
		check.call(GameSession.from_dict(_json_copy(completed)) != null, "normal completed field remains loadable")
		_add_case(cases, "finished and layer_ready are mutually exclusive", completed, ["layer_ready"], true)
		_add_case(cases, "completed board requires a completion marker", completed, ["finished"], false)
		var invalid_descent := completed.duplicate(true)
		invalid_descent.finished = false
		invalid_descent.layer_ready = true
		cases.append({"name":"final stratum cannot offer descent", "payload":invalid_descent})
		_add_case(cases, "completed field requires reward summary", completed, ["last_reward"], {})
		for key in ["bonus", "cores", "rating", "flags", "earned", "seconds", "region_end"]:
			var missing_reward := completed.duplicate(true)
			missing_reward.last_reward.erase(key)
			cases.append({"name":"completed reward missing " + key, "payload":missing_reward})
			_add_case(cases, "completed reward malformed " + key, completed, ["last_reward", key], [])
		for value in [0, 4, 1.5]:
			_add_case(cases, "invalid reward rating %s" % str(value), completed, ["last_reward", "rating"], value)
		for key in ["bonus", "cores", "flags", "earned", "seconds"]:
			_add_case(cases, "negative reward " + key, completed, ["last_reward", key], -1)

	# Compatibility cases prevent strict validation from breaking real old saves.
	var old := baseline.duplicate(true)
	old.version = 1
	for key in ["stratum", "layer_ready", "excavations", "manual_excavations"]:
		old.erase(key)
	old.board.erase("plates")
	old.board.erase("crust")
	check.call(GameSession.from_dict(_json_copy(old)) != null, "version1 save without depth fields migrates")
	var historical_tree := baseline.duplicate(true)
	historical_tree.upgrades = ["lens", "drone", "pair", "fleet"]
	check.call(GameSession.from_dict(_json_copy(historical_tree)) != null, "historical ownership is not rejected for new prerequisites")
	var older_v2 := baseline.duplicate(true)
	older_v2.erase("manual_excavations")
	check.call(GameSession.from_dict(_json_copy(older_v2)) != null, "older version2 save without new counter migrates")
	var duplicate_upgrade := baseline.duplicate(true)
	duplicate_upgrade.upgrades = ["lens", "lens"]
	var deduplicated := GameSession.from_dict(_json_copy(duplicate_upgrade))
	check.call(deduplicated != null and deduplicated.upgrades.count("lens") == 1, "duplicate known upgrades normalize safely")

	var backup_text := FileAccess.get_file_as_string(store.path("expedition.backup.json"))
	for entry in cases:
		var wrote := _write_payload(store.path("expedition.json"), entry.payload)
		check.call(wrote, "write malformed primary: " + entry.name)
		if not wrote:
			continue
		var primary_text := FileAccess.get_file_as_string(store.path("expedition.json"))
		var recovered := store.load_session()
		check.call(recovered != null and recovered.credits == 876543, "backup fallback: " + entry.name)
		check.call(not store.notice.is_empty(), "recovery notice: " + entry.name)
		check.call(FileAccess.get_file_as_string(store.path("expedition.json")) == primary_text, "recovery preserves invalid primary: " + entry.name)
		check.call(FileAccess.get_file_as_string(store.path("expedition.backup.json")) == backup_text, "recovery preserves valid backup: " + entry.name)

	# NaN/Infinity are not portable JSON values; inspect direct dictionaries too.
	for key in ["play_seconds", "board_seconds", "energy", "probe_charge", "drone_clock", "overclock", "index", "stratum", "manual_excavations"]:
		for value in [INF, -INF, NAN]:
			var malformed := baseline.duplicate(true)
			malformed[key] = value
			check.call(GameSession.from_dict(malformed) == null, "reject nonfinite " + key)
	for key in ["width", "height", "mine_count", "seed", "crust"]:
		for value in [INF, -INF, NAN]:
			var malformed := baseline.duplicate(true)
			malformed.board[key] = value
			check.call(GameSession.from_dict(malformed) == null, "reject nonfinite board " + key)
	check.call(_write_payload(store.path("expedition.json"), baseline), "restore healthy isolated primary after adversarial corpus")
	var final_load := store.load_session()
	check.call(final_load != null and final_load.credits == 1234 and store.notice.is_empty(), "loader returns to healthy primary after recovery corpus")

static func _add_case(cases: Array[Dictionary], name: String, base: Dictionary, path: Array, value: Variant) -> void:
	var changed := base.duplicate(true)
	var cursor: Variant = changed
	for i in range(path.size() - 1):
		cursor = cursor[path[i]]
	cursor[path[path.size() - 1]] = value
	cases.append({"name":name, "payload":changed})

static func _json_copy(data: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(data))

static func _write_payload(filename: String, payload: Variant) -> bool:
	var encoded := JSON.stringify(payload)
	var envelope := JSON.stringify({"payload":encoded, "sha256":encoded.sha256_text()})
	var file := FileAccess.open(filename, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(envelope)
	file.flush()
	file.close()
	return true
