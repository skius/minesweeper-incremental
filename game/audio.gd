class_name GameAudio
extends Node

var music_volume: float = 0.35
var sfx_volume: float = 0.65
var sfx_players: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer
var tones: Dictionary = {}
var cursor: int = 0
var last_reveal: float = -1
var time: float = 0

func _ready() -> void:
	for i in range(12):
		var player := AudioStreamPlayer.new()
		add_child(player)
		sfx_players.append(player)
	for key in ["reveal","flag","strike","upgrade","complete","tool","click","pocket"]:
		tones[key] = synth(key)
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.stream = ambient()
	music_player.volume_db = linear_to_db(maxf(0.0001,music_volume))
	music_player.play()

func _process(delta: float) -> void:
	time += delta
	if music_player:
		music_player.volume_db = linear_to_db(maxf(0.0001,music_volume))

func play(kind: String, pitch: float = 1) -> void:
	if sfx_volume < 0.001 or not tones.has(kind):
		return
	if kind == "reveal" and time-last_reveal < 0.055:
		return
	if kind == "reveal":
		last_reveal = time
	var player := sfx_players[cursor%sfx_players.size()]
	cursor += 1
	player.stream = tones[kind]
	player.pitch_scale = pitch
	player.volume_db = linear_to_db(maxf(0.0001,sfx_volume)) - 5
	player.play()

func synth(kind: String) -> AudioStreamWAV:
	var duration: float = {"complete":1.6,"upgrade":0.9,"strike":0.4,"tool":0.5,"pocket":0.45}.get(kind,0.14)
	var hz: float = {"reveal":523.25,"flag":349.23,"strike":95.0,"upgrade":523.25,"complete":261.63,"tool":392.0,"click":740.0,"pocket":880.0}.get(kind,440.0)
	var rate := 22050
	var bytes := PackedByteArray()
	bytes.resize(int(duration*rate)*2)
	for i in range(bytes.size()/2):
		var t := float(i)/rate
		var attack := minf(1,t/0.007)
		var envelope := attack*pow(maxf(0,1-t/duration),2)
		var value := sin(TAU*hz*t)*0.22
		value += sin(TAU*hz*2*t)*0.035
		if kind in ["upgrade","complete"]:
			value = 0
			for k in range(4):
				var nt := t-k*0.10
				if nt >= 0:
					var frequency: float = hz*[1.0,1.25,1.5,2.0][k]
					value += sin(TAU*frequency*nt)*exp(-nt*3)*0.13
		elif kind == "strike":
			value = sin(TAU*(hz*t-50*t*t))*0.3 + sin(t*7131)*sin(t*1731)*0.13
		elif kind == "tool":
			value = sin(TAU*(hz*t+430*t*t))*0.19
		var sample := int(clampf(value*envelope,-1,1)*32767)
		bytes.encode_s16(i*2,sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	return stream

func ambient() -> AudioStreamWAV:
	# Original 32-second ambient loop; whole-cycle oscillators and edge fades
	# avoid discontinuities. A restrained harmonic bed leaves clue sounds clear.
	var rate := 22050
	var seconds := 32.0
	var bytes := PackedByteArray()
	bytes.resize(int(rate*seconds)*2)
	var notes := [130.8128,164.8138,195.9977,246.9417,261.6256,329.6276]
	for i in range(bytes.size()/2):
		var t := float(i)/rate
		var value := 0.0
		for j in range(notes.size()):
			var freq := roundf(notes[j]*seconds)/seconds
			var breath := 0.5+0.5*sin(TAU*t/seconds+j*0.8)
			value += sin(TAU*freq*t)*0.020*breath
		var beat := int(t/2)%8
		var nt := fmod(t,2.0)
		var melody: float = [523.25,659.25,587.33,783.99,659.25,523.25,493.88,392.0][beat]
		value += sin(TAU*melody*nt)*0.028*minf(1,nt*15)*exp(-nt*2.2)
		var fade := minf(1,minf(t,seconds-t)/0.7)
		bytes.encode_s16(i*2,int(clampf(value*fade,-1,1)*32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = int(rate*seconds)
	return stream
