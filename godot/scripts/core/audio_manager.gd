extends Node

## Lightweight procedural audio. It supplies distinct UI/combat/boss cues
## without shipping placeholder audio files, and keeps a small player pool.

var players: Array[AudioStreamPlayer] = []
var tone_cache: Dictionary = {}
var pool_index := 0
var music_running := false
var boss_music := false
var music_clock := 0.0
var music_step := 0
const TAU_VALUE := PI * 2.0

func _ready() -> void:
	for i in range(8):
		var player := AudioStreamPlayer.new()
		player.name = "AudioVoice_%02d" % i
		add_child(player)
		players.append(player)

func _process(delta: float) -> void:
	if not music_running:
		return
	music_clock -= delta
	if music_clock > 0.0:
		return
	music_clock = 0.78 if boss_music else 1.24
	var notes: Array = [73.42, 87.31, 98.0, 110.0, 82.41, 65.41] if boss_music else [146.83, 174.61, 196.0, 220.0, 164.81, 130.81]
	play_tone(notes[music_step % notes.size()], 0.58 if boss_music else 0.86, 0.045 if boss_music else 0.028, 1, true)
	if music_step % 4 == 0:
		play_tone(notes[music_step % notes.size()] * 2.0, 0.18, 0.022, 0, true)
	music_step += 1

func set_mix(music: float, sfx: float, ambient: float) -> void:
	for player in players:
		player.volume_db = linear_to_db(maxf(0.001, sfx))

func _sfx_volume() -> float:
	return float(SaveManager.setting("sfx", 0.8))

func _music_volume() -> float:
	return float(SaveManager.setting("music", 0.6))

func play_tone(frequency: float, duration: float, level: float, wave: int = 0, is_music: bool = false) -> void:
	if is_music and _music_volume() <= 0.01:
		return
	if not is_music and _sfx_volume() <= 0.01:
		return
	var key := "%d_%d_%d" % [int(frequency), int(duration * 1000.0), wave]
	var stream: AudioStreamWAV = tone_cache.get(key)
	if stream == null:
		stream = _make_tone(frequency, duration, wave)
		tone_cache[key] = stream
	var player: AudioStreamPlayer = players[pool_index % players.size()]
	pool_index += 1
	player.stream = stream
	player.volume_db = linear_to_db(maxf(0.001, (level * (_music_volume() if is_music else _sfx_volume()))))
	player.play()

func _make_tone(frequency: float, duration: float, wave: int) -> AudioStreamWAV:
	const MIX_RATE := 22050
	var sample_count := maxi(1, int(duration * MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for i in range(sample_count):
		var t := float(i) / float(MIX_RATE)
		var phase := TAU_VALUE * frequency * t
		var raw := sin(phase)
		if wave == 1:
			raw = sign(sin(phase)) * 0.72
		elif wave == 2:
			raw = (fmod(frequency * t, 1.0) * 2.0 - 1.0) * 0.62
		var attack := clampf(t / 0.015, 0.0, 1.0)
		var release := clampf((duration - t) / 0.08, 0.0, 1.0)
		var value := int(clampf(raw * attack * release, -1.0, 1.0) * 26000.0)
		bytes.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	return stream

func ui() -> void:
	play_tone(420.0, 0.07, 0.09)
	play_tone(680.0, 0.09, 0.05, 0, false)

func build() -> void:
	play_tone(260.0, 0.12, 0.13, 1)
	play_tone(520.0, 0.18, 0.08)

func upgrade() -> void:
	play_tone(280.0, 0.12, 0.12, 0)
	play_tone(760.0, 0.22, 0.12, 2)

func hit(kind: String = "physical") -> void:
	if kind == "magic":
		play_tone(740.0, 0.08, 0.07)
	elif kind == "frost":
		play_tone(930.0, 0.1, 0.06, 1)
	elif kind == "electric":
		play_tone(520.0, 0.09, 0.08, 2)
	else:
		play_tone(150.0, 0.07, 0.055, 1)

func ability() -> void:
	play_tone(170.0, 0.18, 0.1, 2)
	play_tone(820.0, 0.28, 0.11)

func wave() -> void:
	play_tone(220.0, 0.16, 0.11, 1)
	play_tone(330.0, 0.22, 0.08, 0, false)

func coin() -> void:
	play_tone(770.0, 0.08, 0.08)
	play_tone(1100.0, 0.12, 0.06, 0)

func boss() -> void:
	play_tone(82.0, 0.58, 0.16, 2)
	play_tone(128.0, 0.65, 0.13, 1)

func victory() -> void:
	var notes: Array = [440.0, 554.0, 659.0, 880.0]
	for i in range(notes.size()):
		play_tone(notes[i], 0.34, 0.09, 0)

func defeat() -> void:
	play_tone(290.0, 0.16, 0.11, 1)
	play_tone(62.0, 0.55, 0.13, 2)

func start_music(is_boss: bool = false) -> void:
	music_running = true
	boss_music = is_boss
	music_clock = 0.05
	music_step = 0

func stop_music() -> void:
	music_running = false
