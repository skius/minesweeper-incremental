extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var failures: Array[String]=[]
	var report: Array[Dictionary]=[]
	for trial in range(12):
		var s := GameSession.new()
		s.index=96
		for item in Content.UPGRADES:
			s.upgrades.append(item.id)
		s.start_board()
		if not s.begin_trial(trial):
			failures.append("Trial did not open: %d" % trial)
		var steps := 0
		while not s.finished and steps<2000:
			steps+=1
			s.tick(1)
			preload("res://tests/player_policy.gd").act(s)
			s.events.clear()
		if not s.finished or s.strikes>0:
			failures.append("Trial stalled or struck a charge: %d" % trial)
		if trial%2==0 and s.total_drone>0:
			failures.append("Survey trial allowed fleet work: %d" % trial)
		report.append({"trial":trial,"steps":steps,"finished":s.finished,"strikes":s.strikes,"drones":s.total_drone})
	var file := FileAccess.open("res://test_runs/trials.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	for message in failures:
		printerr("FAIL: "+message)
	print("AFTERLIGHT %s: twelve mastery trials with visible-information play" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)
