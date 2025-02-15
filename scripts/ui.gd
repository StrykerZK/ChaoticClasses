extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func game_over(id):
	if id == 1:
		$Label.text = StageManager.player_list[1].name + " won!"
	else:
		$Label.text = StageManager.player_list[id].name + " won!"
	$Label.add_theme_font_size_override("font_size", 60)
	$Label.add_theme_color_override("font_color",Color.MINT_CREAM)
	$Label.anchor_bottom = true
	$Label.show()
	
