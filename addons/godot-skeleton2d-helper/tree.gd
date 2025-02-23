extends VBoxContainer

signal dropped(path:String)

@export var tree: Tree
@onready var label: Label = $Control/Label

func _on_tree_dropped(path: String) -> void:
	dropped.emit(path)
var count:int = 1
func _on_button_pressed() -> void:
	tree.add_file("res://Image" + str(count).pad_zeros(3) + ".png")
	label.text = JSON.stringify(tree.get_all_itemdata_list(),"\t")
	count += 1
var count2:int = 1
func _on_button_2_pressed() -> void:
	tree.add_dir("Directory" + str(count).pad_zeros(3))
	label.text = JSON.stringify(tree.get_all_itemdata_list(),"\t")
	count2 += 1

func _on_check_button_toggled(toggled_on: bool) -> void:
	tree.toggle_delete(toggled_on)

var save:String = "[]"
func _on_button_3_pressed() -> void:
	var data = JSON.parse_string(save)
	tree.set_all_itemdata_list(data)

func _on_button_4_pressed() -> void:
	save = JSON.stringify(tree.get_all_itemdata_list(),"\t")
