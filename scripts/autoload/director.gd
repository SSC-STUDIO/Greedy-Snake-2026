extends Node
## 过场导演：全屏淡变包住切场景，步骤数组驱动短过场。
## 不改 Engine.time_scale（那是 Juice 的领地），不设 tree.paused。
## process_mode ALWAYS：暂停菜单打开时挂起步进，关闭后接着演。

signal finished

var playing: bool = false

var _locked: bool = false
var _suspended: bool = false
var _steps: Array = []
var _index: int = 0
var _busy: bool = false
var _skip: bool = false
var _wait_left: float = 0.0
var _caption_phase: int = 0
var _caption_hold: float = 0.0
var _fading: bool = false
var _headless: bool = false
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _caption: Caption
var _fade_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_headless = DisplayServer.get_name() == "headless"
	_build_overlay()


func is_input_locked() -> bool:
	return _locked


func set_input_locked(v: bool) -> void:
	_locked = v
	_apply_player_lock()


func suspend() -> void:
	_suspended = true


func resume() -> void:
	_suspended = false


func abort() -> void:
	_steps.clear()
	_index = 0
	_busy = false
	_skip = false
	_wait_left = 0.0
	_caption_phase = 0
	playing = false
	_locked = false
	_apply_player_lock()
	if _caption:
		_caption.hide_line()
	var cam := _camera()
	if cam:
		cam.release()


func play(script: Array) -> void:
	if playing:
		return
	_steps = script.duplicate()
	_index = 0
	_busy = false
	_skip = false
	playing = true
	_locked = true
	_apply_player_lock()
	if _steps.is_empty():
		_finish()


func skip_step() -> void:
	if playing and not _suspended:
		_skip = true


func fade_to(scene_path: String, duration: float = 0.55) -> void:
	if _fading:
		return
	_fading = true
	abort()
	await _tween_fade(1.0, duration)
	if scene_path != "":
		get_tree().change_scene_to_file(scene_path)
		await get_tree().process_frame
		await get_tree().process_frame
	await _tween_fade(0.0, duration * 0.85)
	_fading = false


func fade_in(duration: float = 0.45) -> void:
	await _tween_fade(0.0, duration)


func _build_overlay() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 92
	_fade_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.color = Color(0.02, 0.01, 0.03, 0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade_rect)
	_caption = Caption.new()
	add_child(_caption)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept") and playing and not _suspended:
		_skip = true
	if not playing:
		return
	if _suspended or get_tree().paused:
		return
	if _busy:
		_tick_busy(delta)
		return
	_run_next()


func _tick_busy(delta: float) -> void:
	if _caption_phase == 1:
		if _skip:
			_caption.reveal()
			_skip = false
		if not _caption.is_typing():
			_caption_phase = 2
			_wait_left = _caption_hold
		return
	if _wait_left > 0.0:
		if _skip:
			_wait_left = 0.0
			_skip = false
		else:
			_wait_left = maxf(0.0, _wait_left - delta)
		if _wait_left <= 0.0:
			if _caption_phase == 2:
				_caption.hide_line()
				_caption_phase = 0
			_busy = false


func _run_next() -> void:
	if _index >= _steps.size():
		_finish()
		return
	var step: Dictionary = _steps[_index]
	_index += 1
	var kind := StringName(step.get("kind", ""))
	match kind:
		&"lock":
			_locked = true
			_apply_player_lock()
		&"unlock":
			_locked = false
			_apply_player_lock()
		&"wait":
			_busy = true
			_wait_left = float(step.get("seconds", 0.3))
		&"caption":
			_busy = true
			_caption_phase = 1
			_caption_hold = float(step.get("hold", 1.5))
			_caption.show_line(String(step.get("text", "")), float(step.get("cps", 22.0)))
			if _headless:
				_caption.reveal()
		&"cam_focus":
			var cam := _camera()
			var duration := float(step.get("duration", 0.55))
			if cam:
				cam.focus(step.get("target"), float(step.get("zoom", GameCamera.ZOOM)), duration)
			_busy = true
			_wait_left = duration
		&"cam_release":
			var cam := _camera()
			if cam:
				cam.release()
		&"sfx":
			Sfx.play(StringName(step.get("key", "ui_select")))
		&"anim":
			var node: Variant = step.get("node")
			var anim := String(step.get("anim", "idle"))
			if node is FrameAnimSprite:
				(node as FrameAnimSprite).play(anim, true)
		&"fade_out":
			_busy = true
			_wait_left = float(step.get("duration", 0.45))
			_tween_fade(1.0, _wait_left)
		&"fade_in":
			_busy = true
			_wait_left = float(step.get("duration", 0.45))
			_tween_fade(0.0, _wait_left)
		_:
			pass


func _finish() -> void:
	playing = false
	_busy = false
	_locked = false
	_apply_player_lock()
	if _caption:
		_caption.hide_line()
	finished.emit()


func _apply_player_lock() -> void:
	if not is_inside_tree():
		return
	for node in get_tree().get_nodes_in_group("player"):
		if node is Player:
			(node as Player).cutscene_locked = _locked


func _camera() -> GameCamera:
	for node in get_tree().get_nodes_in_group("game_camera"):
		if node is GameCamera:
			return node as GameCamera
	return null


func _tween_fade(alpha: float, duration: float) -> void:
	if _fade_rect == null:
		return
	if _headless or duration <= 0.01:
		_fade_rect.color.a = alpha
		return
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_fade_rect, "color:a", alpha, maxf(0.05, duration))
	await _fade_tween.finished
