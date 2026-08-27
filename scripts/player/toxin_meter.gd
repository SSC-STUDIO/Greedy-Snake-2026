class_name ToxinMeter
extends Node
## Orange sludge fills this meter. At full, the host starts taking overflow damage.

signal overflow_tick

@export var max_toxin: float = 100.0
@export var drain_per_second: float = 8.0
@export var overflow_interval: float = 0.55

var toxin: float = 0.0
var _overflow_clock: float = 0.0
var _exposing: bool = false


func _process(delta: float) -> void:
	if not _exposing and toxin > 0.0:
		toxin = maxf(0.0, toxin - drain_per_second * delta)
		GameEvents.toxin_changed.emit(toxin, max_toxin)

	if toxin >= max_toxin - 0.01:
		_overflow_clock += delta
		if _overflow_clock >= overflow_interval:
			_overflow_clock = 0.0
			overflow_tick.emit()
	else:
		_overflow_clock = 0.0

	_exposing = false


func expose(amount: float) -> void:
	_exposing = true
	toxin = clampf(toxin + amount, 0.0, max_toxin)
	GameEvents.toxin_changed.emit(toxin, max_toxin)


func purify(fraction: float) -> void:
	toxin = maxf(0.0, toxin - max_toxin * fraction)
	GameEvents.toxin_changed.emit(toxin, max_toxin)


func is_full() -> bool:
	return toxin >= max_toxin - 0.01
