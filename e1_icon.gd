extends Control

var index = 0

func _on_p_1_hp_death():
	Global.enemy_deck.effect[index].clear()
	$バフアイコン.self_modulate = Color(0.2353, 0.2353, 0.2353, 1) # アイコンをオフにする
	$バフアイコン.set_process(false)
	$buff_turn.hide()
	$デバフアイコン.self_modulate = Color(0.2353, 0.2353, 0.2353, 1) # アイコンをオフにする
	$デバフアイコン.set_process(false)
	$debuff_turn.hide()
