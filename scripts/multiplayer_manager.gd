extends Control

@export var game_scene: PackedScene
@export var default_ip = "localhost"
@export var default_port = 51077

var peer = ENetMultiplayerPeer.new()

func _ready() -> void:
	$Start.hide()
	$Host.disabled = true
	$Join.disabled = true
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	multiplayer.server_disconnected.connect(server_disconnected)
	if "--server" in OS.get_cmdline_args():
		host()

func host():
	# Host server
	var error = peer.create_server(51077, 2) # Change client number
	if error != OK:
		print("Cannot host.")
		return
	
	# Add Compression if needed
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.multiplayer_peer = peer
	print("Hosted successfully!")

func join():
	if $IPInput.text.is_empty():
		$IPInput.text = default_ip
	if $PortInput.text.is_empty():
		$PortInput.text = str(default_port)
	peer.create_client($IPInput.text, int($PortInput.text))
	multiplayer.multiplayer_peer = peer
	
	# Add Compression if needed
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	$Host.disabled = true
	$Join.disabled = true
	$IPInput.editable = false
	$PortInput.editable = false

func peer_connected(pid):
	print("Player " + str(pid) + " has joined!")

func peer_disconnected(pid):
	if get_tree().current_scene.name == "MainMenu":
		$PlayerPanel/PlayerList/Player2Label.text = ""
		$Start.hide()
	else:
		print("Player " + str(pid) + " has disconnected.")
		StageManager.player_list.erase(pid)
		var players = get_tree().get_nodes_in_group("players")
		for i in players:
			if i.name == str(pid):
				i.queue_free()

func connected_to_server():
	send_player_information.rpc_id(1, $NameInput.text, multiplayer.get_unique_id(), "Base")
	update_player_panel.rpc_id(1, $NameInput.text)

func connection_failed():
	pass

func server_disconnected():
	if get_tree().current_scene.name == "MainMenu":
		$Back.pressed.emit()

@rpc("any_peer")
func send_player_information(player_name, id, class_title):
	if !StageManager.player_list.has(id):
		StageManager.player_list[id] = {
			"player_name": player_name,
			"id": id,
			"class": class_title
		}
	if multiplayer.is_server():
		for i in StageManager.player_list:
			send_player_information.rpc(StageManager.player_list[i].player_name, i, StageManager.player_list[i].class)

@rpc("call_local","reliable")
func start_game():
	var main_game = game_scene.instantiate()
	get_tree().current_scene.hide()
	get_tree().root.add_child(main_game)

@rpc("any_peer")
func update_player_panel(p2_name):
	$PlayerPanel/PlayerList/Player2Label.text = p2_name
	$Start.show()


#func exit_game(pid):
#	multiplayer.peer_disconnected.connect(del_player)
#	del_player(pid)

func _on_start_button_pressed():
	start_game.rpc()

func _on_back_pressed() -> void:
	multiplayer.multiplayer_peer = null
	get_tree().reload_current_scene()

func _on_name_input_text_changed(new_text: String):
	if new_text != "":
		$Host.disabled = false
		$Join.disabled = false
		$IPInput.show()
		$PortInput.show()
	else:
		$Host.disabled = true
		$IPInput.hide()
		$PortInput.hide()

func _on_host_pressed() -> void:
	host()
	send_player_information($NameInput.text, multiplayer.get_unique_id(), "Base")
	$NameInput.editable = false
	$Host.disabled = true
	$Join.disabled = true
	$IPInput.hide()
	$PortInput.hide()
	$PlayerPanel.show()
	$PlayerPanel/PlayerList/Player1Label.text = $NameInput.text

func _on_ip_input_text_changed(new_text: String) -> void:
	pass

func _on_port_input_text_changed(new_text: String) -> void:
	pass
