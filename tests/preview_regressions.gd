extends RefCounted

static func run(check: Callable) -> void:
	var results: Dictionary={}
	for item in Content.UPGRADES:
		var demo := UpgradeDemo.new(item.id)
		check.call(demo.frames.size()>=2,"preview has an actual before/after: "+item.id)
		for frame in demo.frames:
			check.call(MineBoard.from_dict(frame.board)!=null,"preview uses valid mine/clue/plate state: "+item.id)
		check.call(demo.session.strikes==0 or item.id in ["shield","sentry"],"preview does not invent unsafe automated play: "+item.id)
		results[item.id]={"before":demo.frames[0],"after":demo.frames.back(),"workers":demo.workers,"marks":demo.marks}
	for id in ["probe2","focus","reservoir","cartogram","cross","diagonal","line","vertical","nova","aftershock","drone","pair","fleet","swarm","logic","oracle","prism","magnet","relay","launchpad","flywheel","chord","synchrony","conductor","aurora"]:
		var result: Dictionary=results[id]
		check.call(result.after.open>result.before.open,"preview visibly exercises "+id)
	check.call(results.swarm.workers==8,"swarm preview shows all eight workers")
	check.call(results.aftershock.marks.size()==49,"event horizon preview demonstrates a true seven by seven footprint")
	check.call(results.nova.marks.size()==25,"nova preview demonstrates a true five by five footprint")
	check.call(results.flagger.after.flags>results.flagger.before.flags,"cartographer preview makes a proved flag")
	check.call(results.conductor.before.flags==0,"conductor preview demonstrates play without flags")
	check.call(results.drill.before.plates-results.drill.after.plates==3,"pick preview breaks three plates")
	check.call(results.excavator.before.plates-results.excavator.after.plates==3,"excavator preview breaks three plates in one visit")
	check.call(results.salvage.after.salvage==72,"reclamation preview quotes flag payout without unrelated site rewards")
	check.call(results.legacy.before.plates-results.legacy.after.plates==6,"legacy preview breaks all six plates")
	check.call(results.supercap.after.capacity==40 and results.supercap.before.capacity<40,"storm preview shows changed storage")
	check.call(results.shield.after.chain==results.shield.before.chain,"shield preview retains the chain")
	check.call(results.sentry.after.open>results.sentry.before.open,"flare preview actually rescues safe ground")
	check.call(results.autodescent.after.open>results.launchpad.after.open,"volley preview adds safe openings beyond launch rail")
	check.call(results.flywheel.after.pulse>=1,"flywheel preview replenishes a free pulse")
	check.call(results.echochamber.after.pulse>=1,"hollow preview replenishes a free pulse")
	check.call(results.battery.after.energy>results.battery.before.energy,"battery preview converts a pocket into energy")
	check.call(results.kinetic.after.energy>results.kinetic.before.energy,"kinetic preview harvests excavated plates")
	check.call(results.crucible.after.energy>results.crucible.before.energy,"furnace preview harvests excavated plates")
	check.call(results.chording.after.open>results.chording.before.open,"chord relay preview opens satisfied neighbours")
	check.call(results.ballast.before.shelter==25 and results.ballast.after.shelter==49,"ballast preview expands the shelter")
	for id in ["mooring","anchor","grounded_pulse","beam_anchor","clue_anchor","deep_anchor"]:
		check.call(results[id].after.anchors>results[id].before.anchors,"preview visibly pins ground: "+id)
	check.call(results.tracer.after.traces>0,"tracer preview leaves a safe wake")
	check.call(results.induction.after.energy>results.induction.before.energy,"dynamo preview harvests real movement")
	check.call(results.interceptor.after.flags>results.interceptor.before.flags,"interceptor preview catches a moving mine")
	check.call(results.backwash.after.open>results.backwash.before.open,"harvester preview opens the wake")
	check.call(results.stasis.after.stasis==12,"stasis preview uses actual timed freeze")
	check.call(results.stasis_engine.before.energy-results.stasis_engine.after.energy==3,"stillwater preview spends half a crossbeam cost")
	check.call(results.deep_anchor.before.plates-results.deep_anchor.after.plates==1,"bedrock preview breaks a plate layer")
	check.call(results.convergence.before.pinned==0 and results.convergence.after.pinned==1,"final stillness preview freezes remaining ground")
