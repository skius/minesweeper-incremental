extends SceneTree

var failures: Array[String] = []
var report: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for profile in [{"name":"experienced","think":3.0,"tools":true},{"name":"considered","think":7.0,"tools":true},{"name":"learner","think":11.0,"tools":true},{"name":"manual","think":5.0,"tools":false}]:
		var s := GameSession.new()
		var actions := 0
		var seconds := 0.0
		var unlocks: Array[String] = []
		var region_times: Array[String] = []
		for field in range(96):
			for item in Content.UPGRADES:
				if s.buy(item.id):
					unlocks.append("%s at field %d (%.1f min)" % [item.id,field+1,seconds/60])
			s.drones_enabled = profile.tools
			s.events.clear()
			s.reveal((s.board.height/2)*s.board.width+s.board.width/2)
			var iterations := 0
			while not s.finished and iterations < 600:
				iterations += 1
				for _sample in range(int(profile.think*5)):
					s.tick(0.2)
				seconds += profile.think
				if s.finished:
					break
				var moves := s.board.deductions(true)
				if profile.tools and s.has("line") and s.energy >= s.tool_cost("line"):
					# Use visible covered-cell density to choose a useful row.
					var best := 0
					var target := 0
					for y in range(s.board.height):
						var covered := 0
						for x in range(s.board.width):
							covered += 1 if s.board.cells[y*s.board.width+x] == MineBoard.HIDDEN else 0
						if covered > best:
							best = covered
							target = y*s.board.width+s.board.width/2
					if best > s.board.width/2:
						if not s.use_tool("line",target):
							logical_action(s,moves)
					else:
						logical_action(s,moves)
				elif profile.tools and s.has("cross") and s.energy >= s.tool_cost("cross") and moves.safe.is_empty():
					var target := 0
					for i in range(s.board.cells.size()):
						if s.board.cells[i] == MineBoard.HIDDEN:
							target = i
							break
					if not s.use_tool("cross",target):
						logical_action(s,moves)
				else:
					logical_action(s,moves)
				actions += 1
				s.events.clear()
			if not s.finished:
				failures.append("%s stalled at %d" % [profile.name,field])
				break
			if s.strikes != 0:
				failures.append("solver/tool strike at %d" % field)
			seconds += 12 # debrief, reading, purchase decisions
			if field%16 == 15:
				region_times.append("%s %.1fm" % [Content.REGIONS[field/16].name,seconds/60])
			s.next_board()
		for item in Content.UPGRADES:
			s.buy(item.id)
		report.append("%s: %.1f minutes; %d manual actions; %d/24 upgrades; %d spare light / %d cores\n  %s\n  %s" % [profile.name,seconds/60,actions,s.upgrades.size(),s.credits,s.cores,"; ".join(region_times),"; ".join(unlocks)])
		print(report.back().split("\n")[0])
		if s.upgrades.size() != 24:
			failures.append("%s cannot afford all equipment" % profile.name)
		if profile.name == "considered":
			var trial_seconds := 0.0
			for number in range(12):
				if not s.begin_trial(number):
					failures.append("trial %d inaccessible" % number)
					continue
				s.reveal((s.board.height/2)*s.board.width+s.board.width/2)
				var attempts := 0
				while not s.finished and attempts < 500:
					attempts += 1
					for _sample in range(35):
						s.tick(0.2)
					trial_seconds += 7
					if s.finished:
						break
					logical_action(s,s.board.deductions(true))
					s.events.clear()
				if not s.finished:
					failures.append("trial %d stalled" % number)
				s.next_board()
			report.append("considered mastery: %.1f minutes; combined %.1f minutes" % [trial_seconds/60,(seconds+trial_seconds)/60])
			print(report.back())
	var file := FileAccess.open("res://test_runs/balance.txt",FileAccess.WRITE)
	file.store_string("\n\n".join(report))
	file.close()
	for line in report:
		print(line.split("\n")[0])
	for failure in failures:
		printerr("FAIL: "+failure)
	print("AFTERLIGHT %s: four full campaign simulations" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)

func logical_action(s: GameSession, moves: Dictionary) -> void:
	if not moves.safe.is_empty():
		s.reveal(moves.safe[0])
	elif not moves.mines.is_empty():
		s.flag(moves.mines[0])
	elif s.probe_charge >= 1:
		s.use_tool("probe")
