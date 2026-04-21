extends Node

signal player_connected(pid)
signal player_disconnected(pid)
signal connected_to_server
signal connection_failed
signal server_disconnected

var peer = ENetMultiplayerPeer.new()

func _ready() -> void:
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(func(): connected_to_server.emit())
	multiplayer.connection_failed.connect(func(): connection_failed.emit())
	multiplayer.server_disconnected.connect(func(): server_disconnected.emit())
	
	if "--server" in OS.get_cmdline_args():
		host(51077)

func host(port: int): # HOST SERVER
	var error = peer.create_server(port, 3) # Change client number
	if error != OK:
		print("Cannot host.")
		return false

	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.multiplayer_peer = peer
	
	print("Hosted successfully!")
	return true

func join(ip: String, port: int):
	peer.create_client(ip, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.multiplayer_peer = peer

func peer_connected(pid):
	print("Player " + str(pid) + " has joined!")

func peer_disconnected(pid):
	pass
