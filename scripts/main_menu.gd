extends Control

@export var main_game: PackedScene

func _enter_tree() -> void:
	$TitleMenu.show()
	$PlayMenu.hide()

func _process(delta: float) -> void:
	pass

func start_game() -> void:
	$TitleMenu.hide()
	$PlayMenu.show()


func _on_settings_pressed() -> void:
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()
