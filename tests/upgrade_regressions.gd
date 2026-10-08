extends RefCounted

static func fixture(index: int = 0) -> GameSession:
	var s := GameSession.new()
	s.index=index
	s.board.setup(4,4,1,13)
	s.board.generated=true
	s.board.mines[5]=1
	for i in range(16):
		for n in s.board.neighbours(i):
			s.board.clues[i]+=s.board.mines[n]
	s.events.clear()
	return s

static func count_event(s: GameSession, type: String) -> int:
	var count := 0
	for event in s.events:
		count+=1 if event.type==type else 0
	return count

static func run(check: Callable) -> void:
	# Root actions settle before rewards, including recursive upgrade effects.
	var seismic := fixture()
	seismic.board.cells.fill(MineBoard.OPEN)
	seismic.board.cells[5]=MineBoard.HIDDEN
	seismic.board.cells[6]=MineBoard.HIDDEN
	seismic.board.plates[5]=1
	seismic.upgrades.assign(["seismic"])
	seismic.manual_excavations=5
	seismic.excavations=5
	seismic.reveal(5)
	check.call(seismic.finished and seismic.strikes==1,"seismic mine target resolves its strike")
	check.call(seismic.last_reward.rating==2 and count_event(seismic,"complete")==1,"recursive seismic clear cannot award a false perfect rating")
	check.call(seismic.action_depth==0,"root action nesting is balanced")
	var mixed := fixture()
	mixed.board.plates.fill(6)
	mixed.upgrades.assign(["seismic"])
	for _i in range(5):
		mixed.reveal(0,"drone")
	mixed.reveal(1,"manual")
	check.call(mixed.manual_excavations==1 and count_event(mixed,"seismic")==0,"drone excavation cannot trigger the manual rhythm")
	for _i in range(4):
		mixed.reveal(2,"manual")
	mixed.reveal(3,"tool")
	mixed.reveal(4,"manual")
	check.call(mixed.manual_excavations==6 and count_event(mixed,"seismic")==1,"tool work cannot consume the sixth manual excavation")
	var restored := GameSession.from_dict(mixed.to_dict())
	check.call(restored!=null and restored.manual_excavations==6,"manual excavation rhythm survives save/reload")
	# Every layer pays exactly once, not just the final layer of a site.
	var salvage := fixture(4)
	salvage.upgrades.assign(["salvage"])
	salvage.board.cells.fill(MineBoard.OPEN)
	salvage.board.cells[5]=MineBoard.FLAG
	salvage.board.cells[6]=MineBoard.HIDDEN
	salvage.reveal(6)
	check.call(salvage.layer_ready and salvage.credits==50,"intermediate layer pays reveal, flag salvage and clear bonus")
	check.call(salvage.total_flags==1 and count_event(salvage,"salvage")==1,"intermediate flags enter lifetime records once")
	var paid := salvage.credits
	salvage.check_completion()
	restored=GameSession.from_dict(salvage.to_dict())
	if restored!=null:
		restored.check_completion()
	check.call(restored!=null and restored.credits==paid,"reloaded layer checkpoint cannot pay salvage twice")
	var harvester := fixture()
	harvester.board.cells.fill(MineBoard.OPEN)
	harvester.board.cells[0]=MineBoard.HIDDEN
	harvester.board.cells[5]=MineBoard.HIDDEN
	harvester.upgrades.assign(["nova","harvester","salvage"])
	harvester.energy=24
	harvester.use_tool("nova",5)
	check.call(harvester.finished and harvester.last_reward.flags==1,"tool clear accounts for flags later in the same footprint")
	# Plate synergies apply to all actual plate destruction, with visible events.
	var fracture := fixture()
	fracture.upgrades.assign(["fracture","crucible"])
	fracture.board.plates[0]=1
	fracture.board.plates[1]=2
	fracture.energy=0
	fracture.reveal(0)
	check.call(fracture.board.plates[1]==1 and is_equal_approx(fracture.energy,1.75),"fault-line plate fragments fuel the furnace")
	check.call(count_event(fracture,"excavate")==2,"fault-line plate damage has explicit visual events")
	var blast := fixture()
	blast.upgrades.assign(["nova","aftershock","crucible"])
	blast.energy=24
	blast.board.plates.fill(4)
	blast.use_tool("nova",5)
	check.call(blast.board.plates.count(0)==16 and count_event(blast,"excavate")==16,"event horizon shatters every plate through the shared rule")
	check.call(blast.energy>8,"event horizon fragments restore furnace energy")
	var recycle := fixture()
	recycle.board.cells.fill(MineBoard.OPEN)
	recycle.board.cells[5]=MineBoard.HIDDEN
	recycle.board.cells[14]=MineBoard.HIDDEN
	recycle.upgrades.assign(["line","recycler"])
	recycle.energy=2.5
	check.call(is_equal_approx(recycle.effective_tool_cost("line",14),2.5),"closed circuit quotes the affordable net price")
	check.call(recycle.use_tool("line",14) and is_zero_approx(recycle.energy),"closed circuit activates below the original energy price")
	# Trials own their seed and region regardless of campaign progress.
	for trial in range(12):
		var early := Content.contract(16,trial)
		var late := Content.contract(96,trial)
		check.call(early.seed==late.seed and early.region==late.region,"trial identity stays fixed: %d" % trial)
	var survey := GameSession.new()
	survey.index=96
	survey.upgrades.assign(["drone","launchpad","autodescent"])
	survey.begin_trial(0)
	survey.tick(10)
	check.call(not survey.board.generated and survey.region()==0,"survey trial parks launch rail and uses its own region")
	var descent := fixture(4)
	descent.upgrades.assign(["autodescent"])
	descent.layer_ready=true
	descent.drones_enabled=false
	descent.tick(10)
	check.call(descent.stratum==0,"pausing fleet also pauses autonomous descent")
	var fleet_build := fixture()
	fleet_build.upgrades.assign(["drone","pair","fleet","swarm","overdrive"])
	check.call(fleet_build.capacity()>=fleet_build.tool_cost("overdrive"),"fleet branch can power its own overdrive without buying another branch")
	fleet_build.trial=0
	check.call(not fleet_build.tool_available("overdrive") and fleet_build.tool_available("probe"),"trial availability is shared by toolbar and rules")
	# The late conductor validates clues, instead of inheriting wrong flag risks.
	var conductor := fixture()
	conductor.board.cells.fill(MineBoard.OPEN)
	conductor.board.cells[5]=MineBoard.HIDDEN
	conductor.board.cells[6]=MineBoard.FLAG
	conductor.board.cells[10]=MineBoard.HIDDEN
	conductor.upgrades.assign(["conductor"])
	conductor.chord(1)
	check.call(conductor.strikes==0 and conductor.board.cells[6]==MineBoard.OPEN,"conductor corrects a false flag and never follows it into a mine")
	var cascade := fixture()
	cascade.board.mine_count=2
	cascade.board.mines[14]=1
	cascade.board.clues.fill(0)
	for i in range(16):
		for n in cascade.board.neighbours(i):
			cascade.board.clues[i]+=cascade.board.mines[n]
	cascade.board.cells.fill(MineBoard.OPEN)
	cascade.board.cells[5]=MineBoard.FLAG
	cascade.board.cells[13]=MineBoard.FLAG
	for i in [6,9,14]:
		cascade.board.cells[i]=MineBoard.HIDDEN
	cascade.upgrades.assign(["chord"])
	cascade.chord(1)
	check.call(cascade.strikes==0 and cascade.board.cells[14]==MineBoard.HIDDEN,"cascade cannot spread an unrelated false flag into a strike")
	var pocket := fixture()
	pocket.board.pockets[0]=1
	pocket.board.plates.fill(6)
	pocket.board.plates[0]=0
	pocket.upgrades.assign(["prism","magnet"])
	pocket.reveal(0)
	check.call(pocket.board.open_count()==4,"pocket echoes and gravity really open three extra safe tiles through deep plates")
	var aurora := fixture(4)
	aurora.board.cells.fill(MineBoard.OPEN)
	aurora.board.cells[5]=MineBoard.HIDDEN
	aurora.board.cells[6]=MineBoard.HIDDEN
	aurora.upgrades.assign(["aurora","supercap"])
	aurora.energy=0
	aurora.reveal(6)
	check.call(aurora.layer_ready and aurora.energy==40,"aurora refills energy at intermediate strata too")
	# A paid overdrive must outperform a free pocket boost and cannot be wasted
	# by activating its button again while it is already running.
	var boost := fixture()
	boost.upgrades.assign(["drone","overdrive"])
	boost.energy=24
	boost.overclock=10
	check.call(boost.use_tool("overdrive") and boost.overdrive_seconds==12,"solar overdrive has its own stronger mode")
	var energy_after: float=boost.energy
	check.call(not boost.use_tool("overdrive") and boost.energy==energy_after,"active overdrive cannot consume a second activation")
	boost.tick(0.31)
	check.call(boost.drone_clock<0.31,"overdrive cycles before the free pocket cadence")
	restored=GameSession.from_dict(boost.to_dict())
	check.call(restored!=null and is_equal_approx(restored.overdrive_seconds,boost.overdrive_seconds),"active overdrive timer survives reload")
	# Predicting actual flood size includes plate and flag barriers.
	var scanner := MineBoard.new()
	scanner.setup(7,7,8,765)
	scanner.generate(24)
	scanner.plates[23]=3
	scanner.cells[25]=MineBoard.FLAG
	var expected := scanner.opening_size(24)
	var opened := scanner.reveal(24).size()
	check.call(expected==opened and scanner.cells[23]==MineBoard.HIDDEN and scanner.cells[25]==MineBoard.FLAG,"deep scanner measures the actual constrained flood")
	for item in Content.UPGRADES:
		if item.pre!="":
			check.call(item.rank>=Content.upgrade(item.pre).rank,"node milestone follows its prerequisite: "+item.id)
