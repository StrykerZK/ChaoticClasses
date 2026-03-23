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
		host(51077)

func host(port):
	# Host server
	var error = peer.create_server(port, 3) # Change client number
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
	$HostPortInput.hide()
	$NameInput.editable = false
	$IPInput.editable = false
	$PortInput.editable = false
	$PlayerPanel.show()

func peer_connected(pid):
	print("Player " + str(pid) + " has joined!")

func peer_disconnected(pid):
	# If in game, remove disconnected player
	if StageManager.game_state != "Menu" or StageManager.game_state != "Lobby":
		print("Player " + str(pid) + " has disconnected.")
		remove_player_information.rpc(pid)
		var players = get_tree().get_nodes_in_group("players")
		for i in players:
			if i.name == str(pid):
				i.queue_free()
		if StageManager.player_count <= 1:
			back_to_main_menu()
			await $/root/Main/Game.tree_exited
			if multiplayer.is_server():
				peer_disconnected(pid)
			else:
				$Back.pressed.emit()
	else: # If in Main Menu or Lobby
		if multiplayer.is_server():
			remove_player_information.rpc(pid)
			if StageManager.player_count <= 1:
				$Start.hide()

func connected_to_server():
	send_player_information.rpc_id(1, $NameInput.text, multiplayer.get_unique_id())
	update_player_panel.rpc_id(1)

func connection_failed():
	pass

func server_disconnected():
	if is_instance_valid($/root/Main/Game):
		$/root/Main/Game.queue_free()
	else:
		$Back.pressed.emit()

@rpc("any_peer","call_local")
func remove_player_information(id):
	StageManager.remove_player_information(id)
	update_player_panel()

@rpc("any_peer")
func send_player_information(player_name, id):
	if !StageManager.player_list.has(id):
		StageManager.player_list[id] = {
			"player_name": player_name,
			"number": StageManager.player_list.size() + 1,
			"id": id,
			"class": "base",
			"score": 0,
			"health": 200.0,
			"target": Vector2.ZERO
		}
		StageManager.player_count += 1
	if multiplayer.is_server():
		announce_player_information()

func announce_player_information():
	for i in StageManager.player_list:
		send_player_information.rpc(StageManager.player_list[i].player_name, i)

@rpc("call_local","reliable")
func start_game():
	var main_game = game_scene.instantiate()
	get_tree().current_scene.hide_main_menu()
	$/root/Main.add_child(main_game)

@rpc("any_peer")
func update_player_panel():
	var names = StageManager.get_all_player_names()
	while names.size() < 4:
		names.append("")
	$PlayerPanel/PlayerList/Player1Label.text = names[0]
	$PlayerPanel/PlayerList/Player2Label.text = names[1]
	$PlayerPanel/PlayerList/Player3Label.text = names[2]
	$PlayerPanel/PlayerList/Player4Label.text = names[3]
	
	if multiplayer.is_server():
		update_player_panel.rpc()
		if StageManager.player_count >= 2:
			$Start.show()

#func exit_game(pid):
#	multiplayer.peer_disconnected.connect(del_player)
#	del_player(pid)

func back_to_main_menu():
	get_parent().show()
	$/root/Main/Game.queue_free()

func _on_start_button_pressed():
	start_game.rpc()

func _on_back_pressed() -> void:
	StageManager.clear_list()
	multiplayer.multiplayer_peer = null
	get_tree().reload_current_scene()

func _on_name_input_text_changed(new_text: String):
	if new_text != "":
		$Host.disabled = false
		$Join.disabled = false
		$HostPortInput.show()
		$IPInput.show()
		$PortInput.show()
	else:
		$Host.disabled = true
		$HostPortInput.hide()
		$IPInput.hide()
		$PortInput.hide()

func _on_host_pressed() -> void:
	if $HostPortInput.text.is_empty():
		$HostPortInput.text = str(default_port)
	host(int($HostPortInput.text))
	send_player_information($NameInput.text, multiplayer.get_unique_id())
	$NameInput.editable = false
	$Host.disabled = true
	$Join.disabled = true
	$HostPortInput.hide()
	$IPInput.hide()
	$PortInput.hide()
	$PlayerPanel.show()
	update_player_panel()

func _on_ip_input_text_changed(new_text: String) -> void:
	pass

func _on_port_input_text_changed(new_text: String) -> void:
	pass
