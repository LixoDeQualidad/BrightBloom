# autoload/GameState.gd
extends Node

var player_scene := preload("res://entities/Player.tscn")
var current_spawn_point: String = ""
var transition_layer: CanvasLayer

var visited_rooms: Dictionary = {}   # "Room_01" -> true
var collected_items: Dictionary = {} # "item_id" -> true
var opened_doors: Dictionary = {}    # "door_id" -> true

func _ready() -> void:
	var transition_scene = preload("res://scene/transition.tscn")
	transition_layer = transition_scene.instantiate()
	add_child(transition_layer)  

func change_room(scene_path: String, spawn_point_name: String) -> void:
	current_spawn_point = spawn_point_name
	call_deferred("_do_change_room", scene_path)

func _do_change_room(scene_path: String) -> void:
	await transition_layer.fade_out(0.2)
	get_tree().change_scene_to_file(scene_path)

	# Espera até a nova cena estar de fato carregada
	await get_tree().process_frame
	await get_tree().process_frame

	var root = get_tree().current_scene
	if root == null:
		push_warning("current_scene ainda é null, tentando de novo...")
		await get_tree().process_frame
		root = get_tree().current_scene

	_place_player_at_spawn(root)
	await transition_layer.fade_in(0.2)

func _place_player_at_spawn(root: Node) -> void:
	if root == null:
		push_error("Não foi possível obter current_scene para posicionar o player.")
		return

	var player = root.get_node_or_null("Player")
	var spawn = root.get_node_or_null(current_spawn_point)

	if player == null:
		push_error("Player não encontrado na cena '%s'. Confira o nome do nó." % root.name)
		return
	if spawn == null:
		push_error("Spawn point '%s' não encontrado em '%s'." % [current_spawn_point, root.name])
		return

	player.global_position = spawn.global_position

func mark_room_visited(room_name: String) -> void:
	visited_rooms[room_name] = true

func collect_item(item_id: String) -> void:
	collected_items[item_id] = true

func has_item(item_id: String) -> bool:
	return collected_items.has(item_id)
