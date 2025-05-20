extends VBoxContainer

var button = preload("res://技セレクトボタン.tscn")
var monster_data = Global.monster_data
var monster_id = Global.selected_monster

signal select

func _on_tree_entered() -> void:
	if 1 in monster_data[monster_id]: # 進化が存在するモンスターの時
		for action in monster_data[monster_id][1].actions:
			_on_set_button(action)
	else:
		queue_free()

func _on_set_button(action: Action) -> void:
	var instance = button.instantiate()
	instance.action = action
	instance.text = action.name
	instance.button_up.connect(func():_on_button_toggled(action))
	add_child(instance)

func _on_button_toggled(action: Action):
	select.emit(action)
