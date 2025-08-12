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
		
		for j: int in len(Global.deck1.action[i]):
			var e := 0 # evolution用index
			var m := 0 # middle_evolution湯index
			match Global.deck1.action[i][j].id:
				10002: # 進化Ⅱが残っている場合
					Global.deck1.action[i][j] = Global.deck1.evolution[i][e] # 元に戻す
					e += 1
				10001: # 進化Ⅰが残っている場合
					Global.deck1.action[i][j] = Global.deck1.middle_evolution[i][m]
					m += 1
	
	for i in range(3):
		Global.enemy_deck.monster[i] = Global.enemy_deck.monster_dict[i][0]
		Global.enemy_deck.effect[i].clear()
	$"../buttle/result_rect".hide()
	$"../buttle/result_rect/lose".hide()
	$"../buttle/result_rect/win".hide()
	Global.deck_creator(Global.enemy_deck) # 敵デッキ生成
	get_tree().change_scene_to_file(Global.deck_scene)
