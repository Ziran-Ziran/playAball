extends SceneTree
var failures: int = 0
var checks: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)
func run() -> void:
	check(ResourceLoader.exists("res://scripts/roguelite/audio_director.gd"), "Event audio director exists")
	if failures > 0:
		quit(1)
		return
	var audio = load("res://scripts/roguelite/audio_director.gd").new()
	root.add_child(audio)
	await process_frame
	for event: StringName in [&"light", &"heavy", &"kill", &"hurt", &"rice", &"upgrade", &"stage", &"victory", &"defeat", &"launch"]:
		audio.reset_audio()
		check(audio.play_event(event), "Accept event " + event)
		check(not audio.play_event(event), "Rate limit event " + event)
	check(not audio.play_event(&"unknown"), "Unknown event rejected")
	audio.reset_audio()
	var first: int = -1
	var repeats: bool = false
	for i in 12:
		audio.advance(1.0)
		audio.play_event(&"light")
		var variant: int = audio.last_variant[&"light"]
		if first == variant:
			repeats = true
		first = variant
		await create_timer(0.19).timeout
	check(not repeats, "High frequency group never repeats consecutive sample")
	audio.reset_audio()
	for i in 6:
		audio.advance(0.12)
		audio.play_event(&"heavy")
	check(audio.active_voice_count() == 6, "Six ordinary voices maximum")
	audio.advance(0.12)
	check(not audio.play_event(&"heavy"), "Ordinary sounds leave key voice reserve")
	check(audio.play_event(&"hurt"), "Damage cue survives ordinary saturation")
	check(audio.play_event(&"upgrade"), "Confirmation survives ordinary saturation")
	check(audio.active_voice_count() <= 8, "Total voices bounded")
	audio.set_audio_paused(true)
	check(audio.active_voice_count() == 1, "Pause stops battle voices and preserves UI confirmation")
	check(not audio.play_event(&"light"), "Pause rejects battle sounds")
	check(audio.play_event(&"stage"), "Pause allows stage UI cue")
	audio.set_mix(1.0, 1.0, true)
	check(audio.active_voice_count() == 0, "Mute stops current voices")
	check(not audio.play_event(&"upgrade"), "Mute rejects UI sounds")
	audio.set_mix(0.0, 1.0, false)
	audio.set_audio_paused(false)
	check(not audio.play_event(&"hurt"), "Zero SFX volume rejects battle cue")
	audio.reset_audio()
	check(audio.play_event(&"upgrade"), "UI has independent volume")
	audio.reset_audio()
	check(audio.active_voice_count() == 0 and audio.last_variant.is_empty(), "Reset clears voices and old event memory")
	audio.set_mix(0.65, 0.7, false)
	for i in 6:
		audio.advance(0.12)
		audio.play_event(&"light")
	audio.advance(0.12)
	check(audio.play_event(&"heavy"), "Heavy impact displaces light under ordinary budget saturation")
	check(audio.active_voice_count() == 6, "Heavy priority still preserves two key voices")
	check(audio._voices.back().priority == 1, "Heavy priority between light and critical cues")
	audio.reset_audio()
	var hashes: Dictionary = {}
	for event: StringName in audio.palette.events:
		for variant in audio.palette.variant_count(event):
			var stream: AudioStreamWAV = audio.palette.stream_for(event, variant)
			check(stream.data.size() > 0, "PCM exists %s %d" % [event, variant])
			var signature: int = hash(stream.data)
			check(not hashes.has(signature), "Distinct PCM %s %d" % [event, variant])
			hashes[signature] = true
			var peak: int = 0
			for i in range(0, stream.data.size(), 2):
				peak = maxi(peak, absi(stream.data.decode_s16(i)))
			check(peak < 20000, "Sample headroom %s %d" % [event, variant])
	audio.queue_free()
	print("Audio checks: %d, failures: %d" % [checks, failures])
	quit(0 if failures == 0 else 1)
