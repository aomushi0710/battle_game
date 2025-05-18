extends Control

var now_showing: int # 0:main 1:action

func _on_action_button_up() -> void:
	now_showing = 1
	hide_main_button()
	
	


func _on_item_button_up() -> void:
	hide_main_button()


func _on_status_button_up() -> void:
	hide_main_button()


func hide_main_button() -> void: # メインボタンを下に退場させる
	var y = 1
	while $main/Action.position.y < 650:
		$main/Action.position.y += y
		$main/Item.position.y += y
		$main/Status.position.y += y
		y += 1
		await get_tree().create_timer(0.01).timeout
	$main/Action.hide()
	$main/Item.hide()
	$main/Status.hide()
