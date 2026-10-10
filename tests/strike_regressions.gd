extends RefCounted

# Independent regressions for escrow, attempt failure, and the v2 -> v3 migration.
# Fixtures spell out their mines and recompute clues; no fake clue arithmetic.
static func run(check: Callable) -> void:
	_escrow_and_failure(check)
	_shield_and_chord(check)
	_nested_completion(check)
	_retry(check)
	_legacy_migration(check)
	_malformed_fields(check)
	_first_choice(check)

static func _fixture(index: int = 20, positions: Array = [8,10,12,17,22,26,36,38,40]) -> GameSession:
	var s := GameSession.new()
	s.index = index
	s.board.setup(7,7,positions.size(),73)
	s.board.generated = true
	for cell in positions:
		s.board.mines[cell] = 1
	for cell in range(s.board.cells.size()):
		for n in s.board.neighbours(cell):
			s.board.clues[cell] += s.board.mines[n]
	s.credits = 321
	s.cores = 5
	s.total_light = 1000
	s.events.clear()
	return s

static func _events(s: GameSession, type: String) -> int:
	var count := 0
	for event in s.events:
		count += 1 if event.type == type else 0
	return count

static func _json(data: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(data))

static func _state(s: GameSession) -> String:
	# JSON loads all numeric Dictionary values as floats. Normalize both sides
	# so serialization formatting is not mistaken for a gameplay mutation.
	return JSON.stringify(_json(s.to_dict()))

static func _clear(s: GameSession) -> void:
	# This helper tests settlement, not the player's solving strategy.
	for _step in range(s.board.cells.size()+1):
		if s.finished or s.failed:
			return
		s.probe_one("tool")

static func _escrow_and_failure(check: Callable) -> void:
	var s := _fixture()
	s.upgrades.assign(["lens","chain","cross","drone","oracle","legacy","reservoir"])
	s.chain = 21
	s.board_earned = 105
	s.reveal(8)
	check.call(s.damage == 1 and s.strikes == 1 and not s.failed, "first unshielded strike leaves one hull segment")
	check.call(s.board_earned == 52, "first strike discards half cargo, rounded against farming")
	check.call(s.chain == 0 and s.energy == 0, "first strike resets chain and drains energy")
	check.call(s.credits == 321 and s.total_light == 1000 and s.cores == 5, "strike never removes banked resources")
	var restored := GameSession.from_dict(_json(s.to_dict()))
	check.call(restored != null and restored.damage == 1 and restored.board_earned == 52, "surviving damage and escrow survive JSON reload")
	s.reveal(10)
	check.call(s.failed and not s.finished and s.damage == 2, "second unshielded strike fails attempt")
	check.call(s.board_earned == 0 and s.credits == 321 and s.cores == 5, "failure discards escrow and awards no permanent resources")
	check.call(s.last_reward.is_empty() and not s.medals.has("20"), "failure creates no clear reward or medal")
	check.call(_events(s,"failed") == 1 and _events(s,"complete") == 0, "failure emitted exactly once without completion")
	var baseline := _state(s)
	for action in ["reveal","flag","chord","probe","break","drone","tick","light","complete","advance","trial","next"]:
		match action:
			"reveal": s.reveal(24)
			"flag": s.flag(24)
			"chord": s.chord(24)
			"probe": s.probe_one("tool")
			"break": s.break_plates(24,6,"manual")
			"drone": s.drone_cycle()
			"tick": s.tick(300)
			"light": s.add_light(100000)
			"complete": s.check_completion()
			"advance": check.call(not s.advance_layer(), "failed field cannot descend")
			"trial": check.call(not s.begin_trial(0), "failed campaign field cannot escape into a trial")
			"next": s.next_board()
		check.call(_state(s) == baseline, "failed-state guard: " + action)
	for tool in ["probe","cross","line","nova","overdrive"]:
		check.call(not s.use_tool(tool,24), "failed attempt rejects " + tool)
		check.call(_state(s) == baseline, "failed tool leaves state unchanged: " + tool)
	check.call(s.action_depth == 0, "rejected nested actions restore action depth")
	restored = GameSession.from_dict(_json(s.to_dict()))
	check.call(restored != null and _state(restored) == baseline, "failed attempt round-trips exactly")
	var escrow := _fixture(0)
	escrow.upgrades.assign(["lens"])
	escrow.credits = 0
	escrow.cores = 1
	escrow.board_earned = 10000
	check.call(not escrow.buy("cross") and not escrow.has("cross"), "unbanked cargo cannot purchase equipment")
	escrow.board.plates[0] = 2
	escrow.break_plates(0,1,"manual")
	check.call(escrow.board_earned == 10001 and escrow.credits == 0, "plate yield enters escrow only")
	_clear(escrow)
	check.call(escrow.finished and escrow.credits == escrow.board_earned and escrow.credits > 10001, "successful field banks all remaining cargo and bonus once")
	var settled := _state(escrow)
	for _j in range(3):
		escrow.check_completion()
	check.call(_state(escrow) == settled and _events(escrow,"complete") == 1, "clear settlement is idempotent")

static func _shield_and_chord(check: Callable) -> void:
	var s := _fixture()
	s.upgrades.assign(["shield","chain"])
	s.board_earned = 101
	s.chain = 17
	s.energy = 7
	s.reveal(8)
	check.call(s.strikes == 1 and s.damage == 0 and s.board_earned == 101, "Shield preserves cargo and hull on first strike")
	check.call(s.chain == 17 and s.energy == 7, "Shield preserves chain and charge")
	s.reveal(10)
	check.call(not s.failed and s.damage == 1 and s.board_earned == 50, "Shield is consumed and second strike damages hull")
	s.reveal(12)
	check.call(s.failed and s.damage == 2 and s.strikes == 3 and s.board_earned == 0, "third shielded-build strike fails attempt")
	var guarded := _fixture(0)
	guarded.upgrades.assign(["shield","bounty"])
	guarded.reveal(8)
	_clear(guarded)
	check.call(guarded.finished and guarded.last_reward.rating == 2 and guarded.last_reward.cores == 1, "absorbed strike still forfeits perfect medal and Bounty core")
	# Two wrong flags are one mistaken chord, not two separate mistakes.
	var chord := _fixture(20,[0,16,18])
	chord.board.cells[24] = MineBoard.OPEN
	chord.board.cells[23] = MineBoard.FLAG
	chord.board.cells[25] = MineBoard.FLAG
	check.call(chord.board.clues[24] == 2 and chord.board.chord_targets(24).has(16) and chord.board.chord_targets(24).has(18), "wrong-flag chord fixture has two hidden mines with truthful clue")
	chord.chord(24)
	check.call(chord.strikes == 1 and chord.damage == 1 and not chord.failed, "one mistaken chord stops at its first strike")

static func _nested_fixture(damaged: bool) -> GameSession:
	var s := _fixture()
	for cell in range(s.board.cells.size()):
		s.board.cells[cell] = MineBoard.HIDDEN if s.board.mines[cell] else MineBoard.OPEN
	s.board.cells[18] = MineBoard.HIDDEN
	s.board.plates[17] = 1
	s.upgrades.assign(["seismic"])
	s.manual_excavations = 5
	s.excavations = 5
	s.board_earned = 105
	if damaged:
		s.board.cells[8] = MineBoard.HIT
		s.strikes = 1
		s.total_strikes = 1
		s.damage = 1
	return s

static func _nested_completion(check: Callable) -> void:
	for damaged in [false,true]:
		var s := _nested_fixture(damaged)
		check.call(s.board.safe_remaining() == 1 and s.cross_cells(17).has(18), "seismic fixture has one safe target beside its mined drill target")
		s.reveal(17)
		check.call(s.board.completed() and s.board.cells[17] == MineBoard.HIT and s.action_depth == 0, "nested final safe reveal resolves before mined root target settles")
		if damaged:
			check.call(s.failed and not s.finished and s.board_earned == 0 and s.cores == 5 and s.credits == 321, "nested last-safe failure overrides completion and escrow")
			check.call(_events(s,"complete") == 0 and _events(s,"failed") == 1, "nested failure never emits clear reward")
		else:
			check.call(s.finished and not s.failed and s.last_reward.rating == 2, "nested surviving strike receives honest non-perfect clear")
			check.call(_events(s,"complete") == 1 and s.cores == 6, "nested surviving clear settles once after root action")
		var before := _state(s)
		var reloaded := GameSession.from_dict(_json(s.to_dict()))
		check.call(reloaded != null, "nested final-safe state is loadable, including completed geometry with failed attempt")
		if reloaded != null:
			reloaded.check_completion()
			check.call(_state(reloaded) == before, "nested result stays idempotent across reload")

static func _retry(check: Callable) -> void:
	var s := _fixture()
	s.upgrades.assign(["lens","shield","chain","legacy","reservoir","overdrive"])
	check.call(not s.retry_board(), "active field cannot reroll its attempt seed")
	s.board_earned = 100
	s.reveal(8)
	s.reveal(10)
	s.reveal(12)
	check.call(s.failed, "retry fixture failed legitimately")
	s.chain = 24 # Ensure Legacy cannot preserve even a stale chain after failure.
	s.overclock = 8
	s.overdrive_seconds = 11
	s.drone_clock = 2
	s.probe_charge = 0.25
	s.paid_flags.assign([8])
	var old := _json(s.to_dict())
	var clone := GameSession.from_dict(old)
	check.call(clone != null, "failed retry fixture reloads")
	if clone == null:
		return
	check.call(s.retry_board() and clone.retry_board(), "retry is immediately available before and after reload")
	check.call(s.index == 20 and s.attempt == 1 and not s.board.generated and not s.failed and not s.finished, "retry retains site and increments attempt exactly once")
	check.call(s.strikes == 0 and s.damage == 0 and s.board_earned == 0 and s.chain == 0, "retry clears damage, cargo and Legacy chain")
	check.call(s.overclock == 0 and s.overdrive_seconds == 0 and s.drone_clock == 0 and s.paid_flags.is_empty(), "retry clears temporary boosts and paid-flag history")
	check.call(s.probe_charge == 1 and s.energy == s.capacity(), "retry restores initial tool resources")
	check.call(s.credits == old.credits and s.cores == old.cores and s.upgrades == clone.upgrades and s.total_light == old.total_light, "retry preserves banked resources and owned discoveries")
	check.call(s.board.board_seed == Content.contract(20).seed + 15485863 and s.board.board_seed == clone.board.board_seed, "attempt seed is deterministic and owned by this site")
	var first := (s.board.height/2)*s.board.width+s.board.width/2
	s.reveal(first)
	clone.reveal(first)
	check.call(s.board.to_dict() == clone.board.to_dict() and s.strikes == 0, "retry layout reproduces after reload and first opening remains safe")
	var second := GameSession.from_dict(_json(s.to_dict()))
	check.call(second != null and second.attempt == 1 and second.board.to_dict() == s.board.to_dict(), "active retry preserves exact board on save")
	var trial := _fixture(32)
	trial.trial = 1
	trial.reveal(8)
	trial.reveal(10)
	check.call(trial.retry_board() and trial.trial == 1 and trial.index == 32, "failed trial retries without overwriting campaign position")
	check.call(trial.board.board_seed == Content.contract(32,1).seed + 15485863, "trial retry seed belongs to trial rather than campaign")

static func _legacy_migration(check: Callable) -> void:
	for version in [1,2]:
		var old := _fixture(20)
		old.board.cells[8] = MineBoard.HIT
		old.board.cells[10] = MineBoard.HIT
		old.board.cells[12] = MineBoard.HIT
		old.strikes = 3
		old.total_strikes = 9
		old.credits = 7654
		old.total_light = 9999
		old.board_earned = 345
		old.board.plates[0] = 1
		old.upgrades.assign(["lens","cross","salvage"])
		var payload := _json(old.to_dict())
		payload.version = version
		for key in ["damage","failed","attempt"]:
			payload.erase(key)
		payload.stratum = 1
		var snapshot: Dictionary = payload.board.duplicate(true)
		var migrated := GameSession.from_dict(payload)
		check.call(migrated != null, "v%d multi-strike mid-board save migrates" % version)
		if migrated == null:
			continue
		check.call(_json(migrated.to_dict()).board == snapshot, "v%d migration preserves exact mines, clues, flags and partial plating" % version)
		check.call(migrated.credits == 7654 and migrated.total_light == 9999 and migrated.cores == 5, "legacy banked resources are neither confiscated nor duplicated")
		check.call(migrated.strikes == 3 and migrated.total_strikes == 9 and migrated.damage == 0 and not migrated.failed and migrated.board_earned == 0, "legacy hits retain rating statistics without retroactive hull damage or escrow duplication")
		check.call(migrated.stratum == 0 and migrated.attempt == 0, "legacy active stratum becomes one-field expedition")
		var roundtrip := GameSession.from_dict(_json(migrated.to_dict()))
		check.call(roundtrip != null and _state(roundtrip) == _state(migrated), "migrated active save survives new-schema reload")
		_clear(migrated)
		check.call(migrated.finished and migrated.credits == 7654+migrated.board_earned, "legacy completion only banks earnings made after migration")
	# Historical stratum settlement already paid its flag salvage and light.
	var ready := _fixture(20)
	for cell in range(ready.board.cells.size()):
		ready.board.cells[cell] = MineBoard.FLAG if ready.board.mines[cell] else MineBoard.OPEN
	ready.upgrades.assign(["salvage"])
	ready.layer_ready = true
	ready.stratum = 1
	ready.board_earned = 987
	ready.total_flags = 90
	var saved := _json(ready.to_dict())
	saved.version = 2
	for key in ["damage","failed","attempt"]:
		saved.erase(key)
	var migrated := GameSession.from_dict(saved)
	check.call(migrated != null and migrated.finished and not migrated.layer_ready, "completed legacy intermediate stratum immediately becomes a completed site")
	if migrated != null:
		check.call(migrated.board.to_dict() == ready.board.to_dict(), "legacy ready checkpoint retains exact field geometry")
		check.call(migrated.credits == 321+310 and migrated.total_light == 1000+310 and migrated.cores == 6, "ready checkpoint gets new site bonus and cores exactly once")
		check.call(migrated.total_flags == 90 and migrated.last_reward.flags == 0, "already-paid legacy flag salvage and flag totals are not repeated")
		var roundtrip := GameSession.from_dict(_json(migrated.to_dict()))
		check.call(roundtrip != null and _state(roundtrip) == _state(migrated), "ready-checkpoint migration does not repay on new-schema reload")
		if roundtrip != null:
			roundtrip.check_completion()
			check.call(_state(roundtrip) == _state(migrated), "restored migrated clear remains settled")
	var complete := _fixture()
	_clear(complete)
	var completed_payload := _json(complete.to_dict())
	completed_payload.version = 2
	for key in ["damage","failed","attempt"]:
		completed_payload.erase(key)
	var completed_migration := GameSession.from_dict(completed_payload)
	check.call(completed_migration != null and completed_migration.credits == complete.credits and completed_migration.cores == complete.cores and _json(completed_migration.last_reward) == _json(complete.last_reward), "already-complete legacy field never earns a second reward")

static func _malformed_fields(check: Callable) -> void:
	var baseline := _json(_fixture().to_dict())
	var cases: Array[Dictionary] = []
	for key in ["damage","attempt"]:
		for value in [null,[],{},"1",true,0.5,-1,INF,-INF,NAN]:
			var data := baseline.duplicate(true)
			data[key] = value
			check.call(GameSession.from_dict(data) == null, "new save rejects malformed %s: %s" % [key,str(value)])
		for value in [null,[],{},"1",true,0.5,-1]:
			var data := baseline.duplicate(true)
			data[key] = value
			cases.append({"name":key+" type/range "+str(value),"payload":data})
	for value in [null,[],{},"false",0,1]:
		var data := baseline.duplicate(true)
		data.failed = value
		cases.append({"name":"failed requires boolean "+str(value),"payload":data})
	for fields in [{"damage":3},{"attempt":100000001},{"damage":1,"strikes":0},{"failed":true,"damage":0},{"damage":2,"strikes":2,"failed":false},{"failed":true,"damage":2,"strikes":2,"board_earned":1},{"failed":true,"finished":true,"damage":2,"strikes":2},{"layer_ready":true},{"stratum":1}]:
		var data := baseline.duplicate(true)
		data.merge(fields,true)
		cases.append({"name":"inconsistent failure state "+str(fields),"payload":data})
	for key in ["damage","failed","attempt"]:
		var data := baseline.duplicate(true)
		data.erase(key)
		cases.append({"name":"v3 requires "+key,"payload":data})
	var unopened := _json(GameSession.new().to_dict())
	unopened.damage = 2
	unopened.strikes = 2
	unopened.failed = true
	cases.append({"name":"ungenerated field cannot already be failed","payload":unopened})
	for entry in cases:
		check.call(GameSession.from_dict(entry.payload) == null, "reject " + entry.name)
	# Exercise checksum-valid failure payloads through real backup recovery.
	var store := SaveStore.new()
	check.call(store.directory != "user://", "strike save suite requires isolated test arguments")
	if store.directory == "user://":
		return
	store.directory = ProjectSettings.globalize_path("res://test_runs/strike_validation_%d_%d/" % [OS.get_process_id(),Time.get_ticks_usec()])
	check.call(DirAccess.make_dir_recursive_absolute(store.directory) == OK, "create isolated strike validation directory")
	var backup := baseline.duplicate(true)
	backup.credits = 876543
	check.call(_write_payload(store.path("expedition.backup.json"),backup), "write isolated valid strike backup")
	var backup_text := FileAccess.get_file_as_string(store.path("expedition.backup.json"))
	for entry in cases:
		check.call(_write_payload(store.path("expedition.json"),entry.payload), "write checksum-valid malformed strike payload")
		var primary_text := FileAccess.get_file_as_string(store.path("expedition.json"))
		var recovered := store.load_session()
		check.call(recovered != null and recovered.credits == 876543 and not store.notice.is_empty(), "malformed strike state falls back to backup: "+entry.name)
		check.call(FileAccess.get_file_as_string(store.path("expedition.json")) == primary_text and FileAccess.get_file_as_string(store.path("expedition.backup.json")) == backup_text, "failure-state recovery preserves both source files")

static func _first_choice(check: Callable) -> void:
	for struck in [false,true]:
		var s := GameSession.new()
		s.reveal(15)
		if struck:
			for cell in range(s.board.cells.size()):
				if s.board.mines[cell]:
					s.reveal(cell)
					break
		_clear(s)
		check.call(s.finished and not s.failed and s.credits >= 124 and s.cores == 1, "surviving first field funds Lens and one meaningful starting choice")
		check.call(s.buy("lens") and s.buy("cross") and not s.buy("drone"), "first reward buys exactly one core-bearing starting tool")

static func _write_payload(filename: String, payload: Dictionary) -> bool:
	var encoded := JSON.stringify(payload)
	var file := FileAccess.open(filename,FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"payload":encoded,"sha256":encoded.sha256_text()}))
	file.flush()
	file.close()
	return true
