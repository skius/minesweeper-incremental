extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var results: Array = []
	for tier in ["early","mid","complete"]:
		var s:=GameSession.new()
		s.index=48
		var cutoff: int={"early":15,"mid":48,"complete":96}[tier]
		for item in Content.UPGRADES:
			if item.rank<=cutoff:
				s.upgrades.append(item.id)
		s.start_board()
		var seconds:=0.0
		var actions:=0
		while not s.layer_ready and not s.finished and seconds<5000:
			for i in range(5):
				s.tick(0.2)
			seconds+=1
			if not s.layer_ready and not s.finished and preload("res://tests/player_policy.gd").act(s):
				actions+=1
			s.events.clear()
		results.append({"equipment":tier,"seconds":seconds,"actions":actions,"safe_tiles":s.board.open_count(),"drone_tiles":s.total_drone,"strikes":s.strikes})
		print("%s equipment: %.0fs, %d inputs to excavate the same stratum" % [tier,seconds,actions])
	var ok: bool=results[2].seconds<results[0].seconds*0.5 and results[2].strikes==0 and results[1].seconds<results[0].seconds
	var file:=FileAccess.open("res://test_runs/power_curve.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"  "))
	file.close()
	print("AFTERLIGHT %s: equipment overpowers earlier excavation challenges" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
