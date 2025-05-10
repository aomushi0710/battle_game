extends Button

func _on_button_up():
	Global.p1_death = false
	Global.p2_death = false
	Global.p3_death = false
	Global.e1_death = false
	Global.e2_death = false
	Global.e3_death = false
	get_tree().paused = false
	for i in range(3):
		Global.deck1.monster[i] = Global.deck1.monster_dict[i][0]
		Global.deck1.effect[i].clear()
	for i in range(3):
		Global.enemy_deck.monster[i] = Global.enemy_deck.monster_dict[i][0]
		Global.enemy_deck.effect[i].clear()
	$"../buttle/result_rect".hide()
	$"../buttle/result_rect/lose".hide()
	$"../buttle/result_rect/win".hide()
	get_tree().change_scene_to_packed(Global.deck_scene)
