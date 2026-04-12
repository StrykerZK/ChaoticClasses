extends CanvasLayer

@export var main_game: PackedScene

# menu index (Title = 0, Solo = 1, Multi = 2, Settings = 3)
var menu: int = 0

func _ready() -> void:
	$TitleMenu.show()
	$LobbyMenu.hide()

func _process(delta: float) -> void:
	pass

func _on_singleplayer_pressed() -> void:
	pass

func _on_multiplayer_pressed() -> void:
	$TitleMenu.hide()
	$LobbyMenu.show()
	menu = 4

func _on_settings_pressed() -> void:
	menu = 2

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_back_pressed() -> void:
	match menu:
		1: # Single
			#$SinglePlayerMenu.hide()
			$TitleMenu.show()
			menu = 0
		2: # Multiplayer
			$LobbyMenu.hide()
			$TitleMenu.show()
			menu = 0
		4: # Settings
			#$SettingsMenu.hide()
			$TitleMenu.show()
			menu = 0
