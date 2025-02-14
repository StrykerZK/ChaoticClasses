extends Node

@export var player_scene: PackedScene

var peer = ENetMultiplayerPeer.new()

var game_manager: Node

func _ready() -> void:
	game_manager = get_node("/root/Main/GameManager")
	
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)

func host():
	# Host server and check for error
	var error = peer.create_server(51077)
	if error != OK:
		print("Cannot host: " + error)
		return
	
	# Add Compression if needed
	# peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.multiplayer_peer = peer
	print("Hosted successfully!")
	send_player_information("Player 1", multiplayer.get_unique_id())
	$VBoxContainer.visible = false
	
func join():
	peer.create_client("localhost", 51077)
	multiplayer.multiplayer_peer = peer
	
	# Add Compression if needed
	# peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	$VBoxContainer.visible = false

func peer_connected(pid):
	print("Player " + str(pid) + " has joined!")

func peer_disconnected(pid):
	print("Player " + str(pid) + " has disconnected.")

func connected_to_server():
	print("Connected to Server!")
	send_player_information.rpc_id(1, "Player 1", multiplayer.get_unique_id())

func connection_failed():
	pass

@rpc("any_peer")
func send_player_information(name, id):
	if !StageManager.player_list.has(id):
		StageManager.player_list[id] = {
			"name": name,
			"id": id,
		}
	if multiplayer.is_server():
		for i in StageManager.player_list:
			send_player_information.rpc(StageManager.player_list[i].name, i)

#func exit_game(pid):
#	multiplayer.peer_disconnected.connect(del_player)
#	del_player(pid)
