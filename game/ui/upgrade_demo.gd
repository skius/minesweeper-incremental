class_name UpgradeDemo
extends RefCounted

# These are miniature, deterministic game sessions. The preview never invents a
# clue or an upgrade outcome: it records the same actions used by the live game.
var session: GameSession
var frames: Array[Dictionary] = []
var marks: Array[int] = []
var target: int = 24
var action: String = "mouse"
var metric: String = "open"
var note: String = ""
var id: String
var workers: int = 0

func _init(upgrade_id: String) -> void:
	id=upgrade_id
	session=fixture()
	grant(id)
	session.energy=session.capacity()
	prepare()
	workers=session.drone_count() if action=="drone" else 0
	frames.append(snapshot())
	run_action()
	if frames.size()==1:
		frames.append(snapshot())

func grant(upgrade_id: String) -> void:
	if upgrade_id.is_empty() or session.has(upgrade_id):
		return
	grant(Content.upgrade(upgrade_id).pre)
	session.upgrades.append(upgrade_id)

static func fixture() -> GameSession:
	var s := GameSession.new()
	s.board.setup(7,7,9,73)
	s.board.generated=true
	for i in [8,10,12,17,22,26,36,38,40]:
		s.board.mines[i]=1
	for i in range(49):
		for n in s.board.neighbours(i):
			s.board.clues[i]+=s.board.mines[n]
	s.events.clear()
	return s

func seeded(seed_value: int, reveals: Array = [24], flags: Array = []) -> void:
	session.board.setup(7,7,10,seed_value)
	for i in reveals:
		session.board.reveal(i)
	for i in flags:
		session.board.toggle_flag(i)
	session.board.pockets.fill(0)

func finish_fixture() -> void:
	for i in range(session.board.cells.size()):
		session.board.cells[i]=MineBoard.FLAG if session.board.mines[i] else MineBoard.OPEN
	session.board.cells[target]=MineBoard.HIDDEN

func prepare() -> void:
	match id:
		"lens":
			session.board.reveal(target)
			marks=session.board.neighbours(target)
			action="lens"
			metric=""
		"probe2","focus","reservoir","cartogram":
			action="pulse"
			if id=="focus":
				target=46
			if id=="reservoir":
				session.probe_charge=2
				metric="pulse"
			if id=="cartogram":
				seeded(8,[24])
		"cross","diagonal","line","vertical","nova","aftershock","perforator","harvester","resonance","recycler":
			action="beam"
			var tool := "cross"
			if id in ["line","vertical","recycler"]:
				tool="line"
			elif id in ["nova","aftershock"]:
				tool="nova"
			grant(tool)
			note=tool
			marks=session.tool_cells(tool,target)
			metric="energy"
			if id in ["perforator","aftershock"]:
				session.board.plates.fill(6)
				metric="plates"
			if id=="harvester":
				metric="flags"
			if id=="recycler":
				for i in [21,23,25,27]:
					session.board.reveal(i)
			session.energy=session.capacity()
		"drone","pair","fleet","swarm","excavator","overdrive":
			seeded(2)
			action="drone"
			metric="open"
			if id=="excavator":
				target=session.board.deductions(false).safe[0]
				for i in range(49):
					if session.board.cells[i]==MineBoard.HIDDEN:
						session.board.plates[i]=6
				metric="plates"
			if id=="overdrive":
				session.energy=session.capacity()
				note="10× · 12s"
		"flagger","logic","capacitor":
			seeded(2,[24,2,1,3,8,4,6,13,20,15,22,34,39,40,41,36,37,43,44,45,47])
			action="drone"
			metric="flags" if id=="flagger" else ("energy" if id=="capacitor" else "open")
			if id=="logic":
				marks.assign([43,36,28,35,42])
			if id=="capacitor":
				grant("flagger")
				session.energy=2
		"oracle":
			seeded(3,[24,29,28,35,36,37,38,40,44,43,27,34,6],[21,22,39,42,45,46,13,20,41])
			action="drone"
			metric="energy"
			target=48
			marks.assign([47,48])
		"drill","fracture","seismic","kinetic","crucible","legacy":
			session.board.plates.fill(6)
			metric="plates"
			if id=="fracture":
				session.board.plates[target]=3
				marks=session.board.neighbours(target)
			if id=="seismic":
				session.manual_excavations=5
				marks=session.cross_cells(target)
			if id in ["kinetic","crucible"]:
				session.energy=0
				session.probe_charge=0
				metric="energy"
			if id=="kinetic":
				grant("drill")
			if id=="legacy":
				session.chain=16
		"chain":
			session.chain=7
			metric="chain"
		"shield","sentry":
			target=8
			session.chain=16
			grant("chain")
			metric="chain"
		"prism","battery","bounty","magnet","aurora":
			session.board.pockets[target]=1
			if id in ["prism","magnet"]:
				session.board.plates.fill(1)
				session.board.plates[target]=0
			metric="energy" if id=="battery" else ("light" if id=="bounty" else "open")
			session.energy=0
		"compass":
			session.board.pockets[24]=1
			session.board.pockets[44]=1
			session.board.plates.fill(3)
			marks.assign([24,44])
			action="lens"
			metric=""
		"supercap":
			session.upgrades.erase("supercap")
			session.energy=session.capacity()
			metric="capacity"
			action="battery"
		"flywheel","chord","synchrony","conductor":
			seeded(2)
			if id!="conductor":
				for i in range(49):
					if session.board.mines[i]:
						session.board.toggle_flag(i)
			for i in range(49):
				if not session.board.chord_targets(i).is_empty():
					target=i
					break
			if id=="conductor":
				for i in range(49):
					if session.board.cells[i]!=MineBoard.OPEN:
						continue
					for n in session.board.neighbours(i):
						if session.board.deductions(true).safe.has(n):
							target=i
							break
			marks=session.board.neighbours(target)
			session.probe_charge=0
			if id=="synchrony":
				grant("pair")
			metric="pulse" if id=="flywheel" else "open"
		"echochamber":
			seeded(3,[])
			session.board.generate(target)
			session.probe_charge=0
			metric="pulse"
		"salvage":
			finish_fixture()
			metric="salvage"
		"relay","launchpad":
			session.board.setup(7,7,10,2)
			if id=="launchpad":
				action="drone"
				grant("drone")
		"autodescent":
			session.index=8
			finish_fixture()
			session.reveal(target)
			action="drone"
			metric="layer"
			grant("drone")
	session.events.clear()

func run_action() -> void:
	match id:
		"lens","compass":
			pass
		"probe2","focus","cartogram":
			session.use_tool("probe",target if id=="focus" else -1)
		"reservoir":
			for _i in range(2):
				session.use_tool("probe")
				frames.append(snapshot())
		"cross","diagonal","line","vertical","nova","aftershock","perforator","harvester","resonance","recycler":
			session.use_tool(note,target)
		"drone","pair","fleet","swarm","flagger","logic","oracle","capacitor":
			session.drone_cycle()
		"excavator":
			session.reveal(target,"drone")
		"overdrive":
			session.use_tool("overdrive")
			for _i in range(8):
				session.tick(0.31)
				frames.append(snapshot())
		"flywheel","chord","synchrony","conductor":
			session.chord(target)
		"supercap":
			grant("supercap")
		"autodescent","launchpad":
			session.tick(1.25)
		_:
			session.reveal(target)

func snapshot() -> Dictionary:
	var salvage := 0
	for event in session.events:
		if event.type=="salvage":
			salvage+=event.amount
	return {"board":session.board.to_dict(),"energy":session.energy,"capacity":session.capacity(),"pulse":session.probe_charge,"chain":session.multiplier(),"light":session.credits,"salvage":salvage,"open":session.board.open_count(),"flags":session.board.cells.count(MineBoard.FLAG),"plates":session.board.plates[target] if target<session.board.cells.size() else 0,"layer":session.stratum+1}

func metric_icon() -> String:
	return {"energy":"energy","capacity":"battery","pulse":"pulse","chain":"upgrade:chain","light":"prism","salvage":"prism","open":"lens","flags":"flag","plates":"upgrade:drill","layer":"upgrade:autodescent"}.get(metric,"lens")
