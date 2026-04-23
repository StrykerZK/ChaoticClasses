extends Node

signal player_connected(pid)
signal player_disconnected(pid)
signal connected_to_server
signal connection_failed
signal server_disconnected
signal connection_timed_out

var peer: ENetMultiplayerPeer

var default_ip = "localhost"
var default_port = 51077

var connection_timeout: float = 5.0 # Wait before giving up

func _ready() -> void:
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(func(): connected_to_server.emit())
	multiplayer.connection_failed.connect(func(): 
		connection_failed.emit()
		print("CONN FAILED"))
	multiplayer.server_disconnected.connect(func(): server_disconnected.emit())
	
	if "--server" in OS.get_cmdline_args():
		host(51077)

func host(port: int) -> bool: # HOST SERVER
	var peer = ENetMultiplayerPeer.new()
	
	var error = peer.create_server(port, 3) # Change client number
	if error != OK:
		print("Cannot host.")
		return false

	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.multiplayer_peer = peer
	
	print("Hosted successfully!")
	return true

func host_solo() -> bool: # HOST SOLO SERVER w/ 1 PLAYER
	var peer = ENetMultiplayerPeer.new()
	
	var error: Error = peer.create_server(default_port, 1)
	if error != OK:
		print("Cannot host.")
		return false
	
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.multiplayer_peer = peer
	
	print("Solo Server started locally!")
	return true

func join(ip: String, port: int) -> void:
	var peer = ENetMultiplayerPeer.new()
	
	peer.create_client(ip, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.multiplayer_peer = peer
	start_connection_watchdog()

func peer_connected(pid):
	print("Player " + str(pid) + " has joined!")

func peer_disconnected(pid):
	pass

func start_connection_watchdog() -> void:
	await get_tree().create_timer(connection_timeout).timeout
	
	if multiplayer.multiplayer_peer == null: return
	
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTING:
		print("Connection timed out. Forcing disconnect.")
		connection_timed_out.emit()
		multiplayer.multiplayer_peer = null

func clear():
	multiplayer.multiplayer_peer = null
