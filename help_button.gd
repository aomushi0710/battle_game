extends Button

func _on_toggled(toggled_on):
	if toggled_on == true:
		$ColorRect.show()
		get_tree().paused = true
	else:
		$ColorRect.hide()
		get_tree().paused = false
