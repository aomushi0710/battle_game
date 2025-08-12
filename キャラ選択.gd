extends Node2D

var deck_scene = preload("res://デッキセレクト.tscn")

# スライムのモンスターIDは1
func _on_スライム_button_up():
	# ボタンが押された時、１枠目に空きがあり、2枠目3枠目に同じモンスターがいなければ、１枠目にモンスターを登録
	if Global.now_picking == 1:
		Global.picked_monster1 = 1
	if Global.now_picking == 2:
		Global.picked_monster2 = 1
	if Global.now_picking == 3:
		Global.picked_monster3 = 1
	get_tree().change_scene_to_file(deck_scene)
