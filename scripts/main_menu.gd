extends Control

@export var main_game: PackedScene

func _ready() -> void:
	$TitleMenu.show()
	$PlayMenu.hide()

func _process(delta: float) -> void:
	pass

func start_game() -> void:
	$TitleMenu.hide()
	$PlayMenu.show()


func _on_settings_pressed() -> void:
	pass


func _on_quit_pressed() -> void:
	get_tree().quit()
