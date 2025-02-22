extends Sprite2D

var transparency: float = 0.8

func _ready() -> void:
	create_tween().tween_property(self,"transparency",0.0,0.2)

func _process(delta: float) -> void:
	modulate.a = transparency
	if modulate.a <= 0:
		queue_free()
