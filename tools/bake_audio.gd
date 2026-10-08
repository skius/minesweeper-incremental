extends SceneTree

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/audio")
	var generator := GameAudio.new()
	for region in range(6):
		var wave := generator.ambient(region)
		var error := wave.save_to_wav("res://assets/audio/region_%d.wav" % region)
		if error != OK:
			printerr("Audio bake failed: %d" % error)
			generator.free()
			quit(1)
			return
	generator.free()
	print("AFTERLIGHT PASS: six original procedural ambient tracks baked")
	quit()
