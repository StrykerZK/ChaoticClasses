extends Control

@export var game_scene: PackedScene

var peer = ENetMultiplayerPeer.new()

func _ready() -> void:
	$Start.hide()
	$Host.disabled = true
	$Join.disabled = true
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
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
	peer.create_client("localhost", 51077)
	multiplayer.multiplayer_peer = peer
	
	# Add Compression if needed
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)

func peer_connected(pid):
	print("Player " + str(pid) + " has joined!")

func peer_disconnected(pid):
	print("Player " + str(pid) + " has disconnected.")
	StageManager.player_list.erase(pid)
	var players = get_tree().get_nodes_in_group("players")
	for i in players:
		if i.name == str(pid):
			i.queue_free()

func connected_to_server():
	print("Connected to Server!")
	send_player_information.rpc_id(1, $NameInput.text, multiplayer.get_unique_id(), "Base")

func connection_failed():
	pass

@rpc("any_peer")
func send_player_information(name, id, class_title):
	if !StageManager.player_list.has(id):
		StageManager.player_list[id] = {
			"name": name,
			"id": id,
			"class": class_title
		}
	if multiplayer.is_server():
		for i in StageManager.player_list:
			send_player_information.rpc(StageManager.player_list[i].name, i, StageManager.player_list[i].class)

@rpc("call_local","reliable")
func start_game():
	get_tree().change_scene_to_packed(game_scene)

#func exit_game(pid):
#	multiplayer.peer_disconnected.connect(del_player)
#	del_player(pid)

func _on_start_button_pressed():
	start_game.rpc()

func _on_back_pressed() -> void:
	get_tree().reload_current_scene()

func _on_name_input_text_changed(new_text: String):
	if new_text != "":
		$Host.disabled = false
		$Join.disabled = false
	else:
		$Host.disabled = true
		$Join.disabled = true

func _on_host_pressed() -> void:
	host()
	send_player_information($NameInput.text, multiplayer.get_unique_id(), "Base")
	$Start.show()
