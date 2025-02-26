extends Hitbox


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area_entered.connect(Callable(self,"_on_area_entered"))
	body_entered.connect(Callable(self,"_on_body_entered"))
	deflection = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
