extends Control

func _ready():
	
	var butto = Global.action_button.instantiate()
	butto.action = Global.action_data[1]
	$element_actions.add_child(butto)
	for i in range(5, 13):
		var button = Global.action_button.instantiate()
		button.action = Global.action_data[i]
		$element_actions.add_child(button)

func _on_モンスターデータ_button_up():
	$ColorRect.hide()
	$ColorRect2.hide()
	$ColorRect3.hide()
	$ColorRect4.show()
	$モンスターデータ.hide()
	$戻る.show()


func _on_戻る_button_up():
	$ColorRect.show()
	$ColorRect2.show()
	$ColorRect3.show()
	$ColorRect4.hide()
	$モンスターデータ.show()
	$戻る.hide()


func _on_coin_set_button_up() -> void:
	Global.coin_setter($SpinBox.value)
