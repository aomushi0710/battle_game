extends VBoxContainer

var button = preload("res://技セレクトボタン.tscn")
var monster_data = Global.monster_data
var monster_id = Global.selected_monster

signal select(action: Action)

func _on_tree_entered() -> void:
	for action in monster_data[monster_id][0].actions:
		_on_set_button(action)

func _on_set_button(action: Action) -> void:
	var instance = button.instantiate()
	instance.action = action
	instance.text = action.name
	instance.button_up.connect(func():_on_button_toggled(action))
	add_child(instance)

func _on_button_toggled(action: Action):
	select.emit(action)
