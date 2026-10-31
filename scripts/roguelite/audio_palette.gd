extends Resource
## 原创软瞬态、木质共鸣与和弦；只负责音色，不决定游戏结果。
@export_range(0.0, 1.0) var sample_gain: float = 0.46
var events: Array[StringName] = [&"light", &"heavy", &"kill", &"hurt", &"rice", &"upgrade", &"stage", &"victory", &"defeat", &"launch"]
var _cache: Dictionary = {}

func variant_count(event: StringName) -> int:
	return 3 if event in [&"light", &"heavy", &"kill", &"launch"] else 2

func stream_for(event: StringName, variant: int) -> AudioStreamWAV:
	var key := "%s_%d" % [event, variant]
	if _cache.has(key):
		return _cache[key]
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var duration: float = 0.17
	var base: float = 220.0
	match event:
		&"light":
			base = [230.0, 310.0, 185.0][variant % 3]
			duration = [0.09, 0.12, 0.16][variant % 3]
		&"heavy":
			base = [78.0, 105.0, 62.0][variant % 3]
			duration = [0.23, 0.19, 0.28][variant % 3]
		&"kill":
			base = [260.0, 330.0, 390.0][variant % 3]
			duration = 0.19
		&"hurt":
			base = 155.0 + variant * 23.0
			duration = 0.3
		&"rice":
			base = 440.0 + variant * 40.0
			duration = 0.28
		&"upgrade":
			base = 330.0 + variant * 30.0
			duration = 0.48
		&"stage":
			base = 294.0 + variant * 20.0
			duration = 0.62
		&"victory":
			base = 330.0 + variant * 22.0
			duration = 0.95
		&"defeat":
			base = 196.0 + variant * 17.0
			duration = 0.75
		&"launch":
			base = [140.0, 175.0, 210.0][variant % 3]
			duration = 0.18
	var data := PackedByteArray()
	var count: int = int(duration * stream.mix_rate)
	data.resize(count * 2)
	var random := RandomNumberGenerator.new()
	random.seed = hash(key)
	var smooth_noise: float = 0.0
	for i in count:
		var t: float = float(i) / stream.mix_rate
		var u: float = t / duration
		var attack: float = minf(t / 0.004, 1.0)
		var envelope: float = attack * pow(1.0 - u, 2.5)
		smooth_noise = lerpf(smooth_noise, random.randf_range(-1.0, 1.0), 0.22)
		var sample: float = 0.0
		match event:
			&"light":
				# 三种共鸣组合，而非一个音频改变播放速度；低通噪声避免尖锐点击。
				var ratio: float = [1.47, 2.09, 1.81][variant % 3]
				var sweep: float = 24.0 if event == &"heavy" else 9.0
				sample = sin(TAU * (base * t + sweep * duration * (1.0 - exp(-t / duration)))) * 0.68
				sample += sin(TAU * base * ratio * t) * exp(-t * (24.0 + variant * 8)) * 0.23
				sample += smooth_noise * exp(-t * 65.0) * 0.2
			&"heavy":
				# 快下坠的低频冲击＋短中频硬瞬态，软饱和增加打击而不堆尖锐高频。
				var drop_time: float = [0.019, 0.013, 0.026][variant % 3]
				var start_hz: float = [230.0, 290.0, 185.0][variant % 3]
				var phase: float = base * t + (start_hz - base) * drop_time * (1.0 - exp(-t / drop_time))
				var body: float = sin(TAU * phase) * exp(-t * 8.0) * 1.15
				var knock: float = sin(TAU * (410.0 + variant * 135.0) * t) * exp(-t * 95.0) * 0.85
				var grit: float = smooth_noise * exp(-t * 80.0) * 1.5
				sample = tanh((body + knock + grit) * 2.1) * 0.93
			&"hurt":
				sample = sin(TAU * (base * t - 65.0 * t * t)) * 0.65 + smooth_noise * 0.25
			&"launch":
				sample = smooth_noise * sin(PI * u) * 0.65 + sin(TAU * (base * t + 240.0 * t * t)) * 0.35
			&"kill":
				var burst: float = smooth_noise * exp(-t * 34.0) * 2.2
				var crack: float = sin(TAU * (base * 1.8 * t - 650.0 * t * t)) * exp(-t * 50.0) * 0.7
				var thud: float = sin(TAU * (95.0 * t + 1.8 * (1.0 - exp(-t * 45.0)))) * exp(-t * 15.0)
				sample = tanh((burst + crack + thud) * 1.6) * 0.88
			&"defeat":
				sample = (sin(TAU * base * t) + sin(TAU * base * 1.19 * t)) * 0.36
			_:
				# 每个音符从零相位独立渐入/衰减，避免直接切换频率产生点击。
				var ratios: Array[float] = [1.0, 1.25, 1.5]
				if event in [&"upgrade", &"victory"]:
					envelope = attack * pow(1.0 - u, 1.1)
				for note_index in 3:
					var elapsed: float = t - duration * 0.2 * note_index
					if elapsed >= 0.0:
						var note_envelope: float = minf(elapsed / 0.008, 1.0) * exp(-elapsed * 7.0 / duration)
						sample += (sin(TAU * base * ratios[note_index] * elapsed) * 0.48 + sin(TAU * base * ratios[note_index] * 2.0 * elapsed) * exp(-elapsed * 22.0) * 0.13) * note_envelope
		var pcm: int = int(clampf(sample * envelope * sample_gain, -0.58, 0.58) * 32767.0)
		data.encode_s16(i * 2, pcm)
	stream.data = data
	_cache[key] = stream
	return stream
