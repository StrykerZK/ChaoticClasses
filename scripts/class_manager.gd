extends Node

const SAVE_PATH = "user://stats.json"

var name_list: Array
var armor_data: Array
var damage_data: Array
var speed_data: Array
var dodge_mult_data: Array
var dodge_duration_data: Array
var dodge_count_data: Array

func _ready():
	load_data()

func load_data():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var data = JSON.parse_string(file.get_as_text())
			if data:
				for key in data.keys():
					match key:
						"name":
							name_list = data["name"]
						"armor":
							armor_data = data["armor"]
						"damage":
							damage_data = data["damage"]
						"speed":
							speed_data = data["speed"]
						"dodge mult":
							dodge_mult_data = data["dodge mult"]
						"dodge duration":
							dodge_duration_data = data["dodge duration"]
						"dodge count":
							dodge_count_data = data["dodge count"]
			file.close()

func save_data():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	var data = {
		"name": name_list,
		"armor": armor_data,
		"damage": damage_data,
		"speed": speed_data,
		"dodge mult": dodge_mult_data,
		"dodge duration": dodge_duration_data,
		"dodge count": dodge_count_data
		}
	file.store_string(JSON.stringify(data))
	file.close()

func get_class_data(new_name: String) -> Array:
	var id = 0
	var data_set = []
	
	for i in range(name_list.size()):
		if name_list[i] == new_name:
			id = i
	
	data_set.append(armor_data[id])
	data_set.append(damage_data[id])
	data_set.append(speed_data[id])
	data_set.append(dodge_mult_data[id])
	data_set.append(dodge_duration_data[id])
	data_set.append(dodge_count_data[id])
	
	return data_set
