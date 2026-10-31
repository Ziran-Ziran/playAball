extends SceneTree
var checks: int = 0
var failures: int = 0
var heard: Array[StringName] = []
func _initialize() -> void:
 call_deferred("run")
 create_timer(25.0).timeout.connect(func(): quit(1))
func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)
func run() -> void:
 var arena = load("res://scenes/roguelite/run.tscn").instantiate()
 root.add_child(arena)
 await process_frame
 var audio = arena.get_node_or_null("AudioDirector")
 check(audio != null, "Run owns routed audio")
 if audio == null:
  quit(1)
  return
 arena.director.set_process(false)
 arena.player.freeze = true
 audio.event_played.connect(func(event: StringName, _variant: int, _db: float): heard.append(event))
 audio.reset_audio()
 check(arena.feedback.audio_director == audio, "Impact feedback uses same audio director")
 arena.feedback.play_impact(Vector2(600, 350), 200.0)
 arena.feedback.play_impact(Vector2(600, 350), 700.0)
 arena.feedback.play_cue(Vector2(600, 350))
 check(heard.has(&"light") and heard.has(&"heavy") and heard.has(&"rice"), "Real feedback routes light/heavy/rice")
 arena.director.health.hurt()
 check(heard.has(&"hurt"), "Health change routes hurt cue")
 check(arena.get_node("RunHUD").health_bar.value == arena.director.health.hp, "Integrated health bar follows actual damage")
 arena.director.register_kill(987654)
 check(heard.has(&"kill"), "Unique kill routes cue")
 arena.launcher.fired.emit(1)
 check(heard.has(&"launch"), "Launch routes its own sound without collision")
 arena.get_node("HUD/Controls/Mute").button_pressed = true
 var count_before: int = heard.size()
 arena.feedback.play_impact(Vector2.ZERO, 900.0)
 arena.director.run_event.emit("upgrade")
 check(heard.size() == count_before and audio.active_voice_count() == 0, "Shared mute stops and suppresses all event audio")
 arena.get_node("HUD/Controls/Mute").button_pressed = false
 audio.reset_audio()
 arena.director.finish(true)
 await process_frame
 check(heard.has(&"victory"), "Victory emits sound even as battle pauses")
 check(audio.active_voice_count() > 0, "Pause transition preserves result cue tail")
 arena.director.restart()
 check(audio.active_voice_count() == 0, "Restart clears prior result and battle voices")
 check(arena.get_node("RunHUD").health_bar.value == arena.director.health.max_hp, "Restart restores full panel")
 arena.queue_free()
 await process_frame
 # Dummy后台混音在线程中回收，退出前让停止队列被消费。
 await create_timer(0.5).timeout
 print("FEEDBACK INTEGRATION CHECKS PASSED: %d checks, %d failures" % [checks, failures])
 quit(1 if failures else 0)
