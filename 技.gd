extends VBoxContainer

var button = preload("res://技セレクトボタン.tscn")
var monster_data = Global.monster_data
var monster_id = Global.selected_monster

signal select

func _on_tree_entered() -> void:
	for action in monster_data[monster_id][0].actions:
		_on_set_button(action)

func _on_set_button(action: Action) -> void:
	var instance = button.instantiate()
	instance.action = action
	instance.text = action.name
	# element_iconはインスタンスされた時に呼ばれるシグナル
	instance.element_icon.connect(func():element_icon(instance, action.element))
	instance.button_up.connect(func():_on_button_toggled(action))
	add_child(instance)

func _on_button_toggled(action: Action):
	select.emit(action)

# ボタン
func element_icon(button: Button, element_list: Array) -> void:
	if len(element_list) == 1: # 属性が1つだけだった場合
		button.icon = element_list[0].icon
		button.set_process(false)
		button.get_child(0).queue_free() # 不要な子ノードなので削除
	else: # 複数の属性を持つ場合
		button.icon = load("res://null.PNG")
		button.set_process(true) # _processを有効化
		
