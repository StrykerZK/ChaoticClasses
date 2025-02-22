extends Sprite2D

var transparency: float = 1.0

func _ready() -> void:
	create_tween().tween_property(self,"transparency",0.0,0.1)

func _process(delta: float) -> void:
	modulate.a = transparency
	if modulate.a <= 0:
		queue_free()
