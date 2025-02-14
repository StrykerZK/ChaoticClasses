extends Node

@export var player_scene: PackedScene

var peer = ENetMultiplayerPeer.new()
var player_list = []

func host():
	peer.create_server(51077)
	multiplayer.multiplayer_peer = peer
	
	multiplayer.peer_connected.connect(
		func(pid):
			player_list.append(pid)
			print("Player " + str(pid) + " has joined!")
			add_player(pid)
	)
	
	multiplayer.peer_disconnected.connect(
		func(pid):
			print("Player " + str(pid) + " has left.")
			get_node(str(pid)).queue_free()
			player_list.erase(pid)
	)
	
	add_player(multiplayer.get_unique_id())
	player_list.append(multiplayer.get_unique_id())
	$VBoxContainer.visible = false
	
func join():
	peer.create_client("localhost", 51077)
	multiplayer.multiplayer_peer = peer
	$VBoxContainer.visible = false
	
	multiplayer.server_disconnected.connect(
		func(pid):
			print("Connection to server lost.")
			$VBoxContainer.visible = true
	)

func add_player(pid):
	var player = player_scene.instantiate()
	player.name = str(pid)
	add_child(player)
