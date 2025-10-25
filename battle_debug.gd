extends Control


func _on_enter_button_up() -> void:
	var text = $log_window/LineEdit.text
	$log_window/LineEdit.text = ""
	
	if text == "stop":
		for node in [$"../buttle", $"../enemies"]:
			for childlen in node.get_children():
				for child in childlen.get_children():
					for chi in child.get_children():
						chi.set_process(false)
		$log_window/log.text += "\nstop"
	
	elif text == "start":
		for node in [$"../buttle", $"../enemies"]:
			for childlen in node.get_children():
				for child in childlen.get_children():
					for chi in child.get_children():
						chi.set_process(true)
		$log_window/log.text += "\nstart"
	
	elif text == "player_deck_action":
		for actions in Global.player_deck.action:
			$log_window/log.text += "\n"
			for action: Action in actions:
				$log_window/log.text += action.name + ","
	
	elif text == "enemy_deck_action":
		for actions in Global.enemy_deck.action:
			$log_window/log.text += "\n"
			for action: Action in actions:
				$log_window/log.text += action.name + ","
	
	else:
		$log_window/log.text += "存在しないコマンドです\n"


func _on_debug_toggled(toggled_on: bool) -> void:
	if toggled_on == true:
		$"../log_window".hide()
		$log_window.show()
	else:
		$log_window.hide()
		$"../log_window".show()
