class_name CorePickup
extends Interactable
## World drop for a Rust-Core.

var core: RustCore


func _ready() -> void:
	super._ready()
	if core == null:
		core = AbilityCatalog.tether_core()
	prompt = "E 拾取 %s" % core.display_name
	ensure_rect(Vector2(10, 10), core.tint)


func interact(actor: Node) -> void:
	if actor is Player and core:
		(actor as Player).collect_core(core)
		queue_free()
