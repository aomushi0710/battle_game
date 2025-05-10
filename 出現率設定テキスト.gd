extends VBoxContainer

var ui = preload("res://出現率設定text.tscn")
var probability = 0

func _on_セレクト_set_text(list):
	queue_free()
	print("emited!")
	print(list)
	for key in Global.selected_action.keys():
		var label = ui.instantiate()
		label.text = "[img=15]" + Global.actions_data[key]["type"] + "[/img]"
		label.text += Global.actions_data[key]["name"] + "[color=red]" + str(Global.selected_action[key]) + "%[/color]"
		add_child(label)
		
func _on_slider_value_changed(value):
	probability = value
	
