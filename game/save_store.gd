class_name SaveStore
extends RefCounted

var directory: String = "user://"
var notice: String = ""
var last_error: String = ""

func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--test-data="):
			directory = arg.trim_prefix("--test-data=").replace("\\", "/").trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(directory)

func path(name_value: String) -> String:
	return directory.path_join(name_value)

func exists() -> bool:
	return FileAccess.file_exists(path("expedition.json")) or FileAccess.file_exists(path("expedition.backup.json"))

func write_session(session: GameSession) -> bool:
	last_error = ""
	var data := session.to_dict()
	var encoded := JSON.stringify(data)
	var envelope := JSON.stringify({"payload":encoded,"sha256":encoded.sha256_text()})
	var file := FileAccess.open(path("expedition.tmp"), FileAccess.WRITE)
	if file == null:
		last_error = "Could not open save file. Check free space and folder permissions."
		return false
	file.store_string(envelope)
	file.flush()
	file.close()
	if read_file(path("expedition.tmp")) == null:
		last_error = "Save verification failed. Your previous save is intact."
		return false
	var primary := path("expedition.json")
	if FileAccess.file_exists(primary) and read_file(primary) != null:
		var copy_error := DirAccess.copy_absolute(primary, path("expedition.backup.json"))
		if copy_error != OK:
			last_error = "Could not update the backup save. Your previous save is intact."
			return false
	var err := DirAccess.rename_absolute(path("expedition.tmp"), primary)
	if err != OK:
		last_error = "Could not replace save file (%d). Your backup is intact." % err
		return false
	return true

func read_file(filename: String) -> GameSession:
	if not FileAccess.file_exists(filename):
		return null
	var file := FileAccess.open(filename, FileAccess.READ)
	if file == null or file.get_length() > 4_000_000:
		return null
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return null
	var envelope = parser.data
	if not envelope is Dictionary or not envelope.get("payload") is String or not envelope.get("sha256") is String:
		return null
	if envelope.payload.sha256_text() != envelope.sha256:
		return null
	if parser.parse(envelope.payload) != OK:
		return null
	var data = parser.data
	if not data is Dictionary:
		return null
	return GameSession.from_dict(data)

func load_session() -> GameSession:
	notice = ""
	var session := read_file(path("expedition.json"))
	if session != null:
		return session
	session = read_file(path("expedition.backup.json"))
	if session != null:
		notice = "The last save was unreadable. Your backup expedition has been restored."
	elif exists():
		notice = "Neither save could be read. Existing files have been kept; start a new expedition to continue."
	return session

func settings_default() -> Dictionary:
	return {"music":0.35,"sfx":0.65,"motion":1.0,"particles":true,"fullscreen":false,"contrast":false,"auto_pause":true,"flag_mode":false}

func load_settings() -> Dictionary:
	var result := settings_default()
	if FileAccess.file_exists(path("settings.json")):
		var parser := JSON.new()
		if parser.parse(FileAccess.get_file_as_string(path("settings.json"))) != OK:
			return result
		var data = parser.data
		if data is Dictionary:
			for key in result:
				if not data.has(key):
					continue
				if result[key] is bool and data[key] is bool:
					result[key] = data[key]
				elif result[key] is float and (data[key] is float or data[key] is int):
					result[key] = clampf(float(data[key]), 0, 1)
	return result

func write_settings(settings: Dictionary) -> bool:
	var file := FileAccess.open(path("settings.json"), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(settings))
	file.close()
	return true
