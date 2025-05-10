extends Node2D



func _on_button_pressed():
	hide()
	get_tree().change_scene("res://メインシーン.tscn")
