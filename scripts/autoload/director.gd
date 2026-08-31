extends Node
## Director autoload: fade transitions + sequenced cutscenes.
## Never touches Engine.time_scale. Pause hangs us via suspend() / tree.paused,
## not by us setting paused ourselves.

signal finished
signal step_started(index: int, step: Dictionary)
signal step_finished(index: int, step: Dictionary)

const FADE_DEFAULT := 0.45
## 进行中的剧本之外还能再排这么多条。满了丢掉最旧的并打日志，避免故事监听静默丢过场。
const PLAY_QUEUE_MAX := 8

var playing: bool = false
## 结局选择层打开时为 true：暂停菜单忽略 Esc，关掉后也不解 tree.paused。
var choice_hold: bool = false
## 最近一次 fade_to 实际采用的目标（含排队覆盖）。测试可读。
var last_fade_target: String = ""

var _locked: bool = false
var _suspended: bool = false
var _queue: Array = []
var _script_queue: Array = []
var _index: int = -1
var _waiting: bool = false
var _wait_kind: String = ""
var _step_timer: float = 0.0
var _fading: bool = false
var _queued_fade_path: String = ""
var _queued_fade_duration: float = FADE_DEFAULT
var _fade_layer: CanvasLayer
var _fade: ColorRect
var _caption_layer: CanvasLayer
var _caption: Caption
var _fade_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()


func _build_overlay() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.name = "DirectorFade"
	_fade_layer.layer = 100
	_fade_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_fade_layer)
	_fade = ColorRect.new()
	_fade.name = "Fade"
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade)

	_caption_layer = CanvasLayer.new()
	_caption_layer.name = "DirectorCaption"
	_caption_layer.layer = 12
	add_child(_caption_layer)
	_caption = Caption.new()
	_caption.name = "Caption"
	_caption_layer.add_child(_caption)


func caption() -> Caption:
	return _caption


func is_input_locked() -> bool:
	return _locked


func suspend() -> void:
	_suspended = true


func resume() -> void:
	_suspended = false


func is_fading() -> bool:
	return _fading


## fade_to(scene) or fade_to(scene, duration_seconds). Always fades to black.
## 正在淡变时不丢第二次请求：只保留最后一个目标，当前淡出结束后切过去。
func fade_to(scene: String, duration: float = FADE_DEFAULT) -> void:
	# 切场必须掐掉进行中的过场，否则 lock/字幕会跟着 Autoload 进下一幕。
	if playing:
		abort()
	if _fading:
		_queued_fade_path = scene
		_queued_fade_duration = duration
		return
	_fading = true
	_fade.color = Color(0, 0, 0, _fade.color.a)
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	if DisplayServer.get_name() == "headless":
		# 留一帧给紧随其后的第二次 fade_to 排队，避免测试里同步跑完。
		await get_tree().process_frame
		_on_fade_out_done(scene, duration)
		return
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = _fade_layer.create_tween()
	_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_tween.tween_property(_fade, "color:a", 1.0, maxf(0.05, duration))
	_fade_tween.tween_callback(_on_fade_out_done.bind(scene, duration))


func fade_in(duration: float = FADE_DEFAULT) -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	if _fade.color.a < 0.01:
		_fade.color.a = 1.0
	if DisplayServer.get_name() == "headless":
		_fade.color.a = 0.0
		_on_fade_in_done()
		return
	_fade_tween = _fade_layer.create_tween()
	_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_tween.tween_property(_fade, "color:a", 0.0, maxf(0.05, duration))
	_fade_tween.tween_callback(_on_fade_in_done)


func play(script: Array) -> void:
	if playing:
		if _script_queue.size() >= PLAY_QUEUE_MAX:
			var dropped: Array = _script_queue.pop_front()
			push_warning("Director: play queue full (%d), dropped oldest script (%d steps)" \
					% [PLAY_QUEUE_MAX, dropped.size()])
		_script_queue.append(script.duplicate())
		return
	_queue = script.duplicate()
	_index = -1
	playing = true
	_waiting = false
	_wait_kind = ""
	_advance()


func skip_step() -> void:
	if not playing or _suspended or get_tree().paused:
		return
	if _wait_kind == "caption" and _caption != null and _caption.is_busy():
		_caption.skip()
		if _caption.is_busy():
			_caption.skip()
		return
	if _waiting:
		_step_timer = 0.0
		_complete_wait()


func abort() -> void:
	_set_lock(false)
	var cam := _camera()
	if cam != null:
		cam.release()
	if _caption != null:
		_caption.clear()
	_queue.clear()
	_script_queue.clear()
	_index = -1
	_waiting = false
	_wait_kind = ""
	var was := playing
	playing = false
	if was:
		finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not playing or _suspended or get_tree().paused:
		return
	if event.is_action_pressed("ui_accept"):
		skip_step()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _suspended or get_tree().paused:
		return
	if not playing or not _waiting:
		return
	if _wait_kind == "caption":
		if _caption == null or not _caption.is_busy():
			_complete_wait()
		return
	_step_timer -= delta
	if _step_timer <= 0.0:
		_complete_wait()


func _advance() -> void:
	_index += 1
	if _index >= _queue.size():
		_finish_play()
		return
	var step := _as_step(_queue[_index])
	step_started.emit(_index, step)
	_run_step(step)


func _as_step(raw) -> Dictionary:
	if raw is Dictionary:
		return raw
	return {"kind": String(raw)}


func _kind_of(step: Dictionary) -> String:
	return String(step.get("kind", step.get("op", "")))


func _seconds_of(step: Dictionary, fallback: float = 0.3) -> float:
	return float(step.get("seconds", step.get("sec", fallback)))


func _run_step(step: Dictionary) -> void:
	var kind := _kind_of(step)
	match kind:
		"lock":
			_set_lock(true)
			_finish_step(step)
			_advance()
		"unlock":
			_set_lock(false)
			_finish_step(step)
			_advance()
		"wait":
			_begin_wait(_seconds_of(step), "wait")
		"caption":
			if _caption != null:
				_caption.enqueue(String(step.get("text", "")),
						float(step.get("hold", Caption.DEFAULT_HOLD)))
			_begin_wait(0.0, "caption")
		"cam_focus":
			var cam := _camera()
			var dur := float(step.get("duration", 0.8))
			if cam != null:
				cam.focus(step.get("target"), float(step.get("zoom", GameCamera.ZOOM)), dur)
			_begin_wait(dur, "cam")
		"cam_release":
			var cam := _camera()
			var dur := float(step.get("duration", 0.35))
			if cam != null:
				cam.release()
			_begin_wait(dur, "cam")
		"sfx":
			Sfx.play(StringName(step.get("id", "ui_select")))
			_finish_step(step)
			_advance()
		"anim":
			_play_anim(step)
			_begin_wait(_seconds_of(step, 0.2), "anim")
		_:
			_finish_step(step)
			_advance()


func _begin_wait(sec: float, kind: String) -> void:
	_waiting = true
	_wait_kind = kind
	_step_timer = maxf(0.0, sec)


func _complete_wait() -> void:
	if not playing:
		return
	_waiting = false
	_wait_kind = ""
	if _index >= 0 and _index < _queue.size():
		_finish_step(_as_step(_queue[_index]))
	_advance()


func _finish_step(step: Dictionary) -> void:
	step_finished.emit(_index, step)


func _finish_play() -> void:
	playing = false
	_waiting = false
	_wait_kind = ""
	# 队列里还有下一条：保持 lock，避免两段过场之间漏一帧输入/灌毒/AI。
	if not _script_queue.is_empty():
		var next: Array = _script_queue.pop_front()
		play(next)
		return
	_set_lock(false)
	finished.emit()


func _on_fade_out_done(scene: String, duration: float) -> void:
	var target := scene
	var dur := duration
	if _queued_fade_path != "":
		target = _queued_fade_path
		dur = _queued_fade_duration
		_queued_fade_path = ""
	last_fade_target = target
	if target != "" and not _is_test_runner():
		get_tree().change_scene_to_file(target)
	fade_in(dur)


func _on_fade_in_done() -> void:
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fading = false
	if _queued_fade_path != "":
		var next := _queued_fade_path
		var next_dur := _queued_fade_duration
		_queued_fade_path = ""
		fade_to(next, next_dur)


func _is_test_runner() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	return String(scene.scene_file_path).ends_with("run_tests.tscn")


func _set_lock(locked: bool) -> void:
	_locked = locked
	if not is_inside_tree():
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null:
		player.cutscene_locked = locked


func _camera() -> GameCamera:
	if not is_inside_tree():
		return null
	return get_tree().get_first_node_in_group("game_camera") as GameCamera


func _play_anim(step: Dictionary) -> void:
	var node = step.get("node")
	var anim := String(step.get("name", ""))
	if node == null or anim == "" or not is_instance_valid(node):
		return
	if node is FrameAnimSprite:
		(node as FrameAnimSprite).play(anim, true)
	elif node.has_method("play"):
		node.play(anim)
