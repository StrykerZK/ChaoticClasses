extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.dw
func _process(delta: float) -> void:
	pass


func _on_quit_pressed() -> void:
	var game_node = get_node_or_null("../..")
	if is_instance_valid(game_node):
		game_node.back_to_main_menu()
	#get_tree().quit()
