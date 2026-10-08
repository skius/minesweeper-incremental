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
