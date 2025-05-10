extends TextureProgressBar

var index = 2
var monster_dict = Global.deck1.monster_dict[index]
var monster: Monster = Global.deck1.monster[index]

signal damage_effect

func _on_tree_entered():
	monster = Global.deck1.monster[index]
	$".".max_value = monster.maxMP
	$".".value = monster.MP
	text_update()

func _on_p_1_spd_mp():
	if monster.MP == monster.maxMP: # 既にmpが最大の場合、処理を中断
		return
	var mp_healing: int = 0
	if monster.maxMP - monster.MP < monster.supplyMP: # mpが最大値を越えないようにする
		mp_healing = monster.maxMP - monster.MP
	else:
		mp_healing = monster.supplyMP
	
	monster.MP += mp_healing
	damage_effect.emit(mp_healing,2)
	for i in range(mp_healing): # 少しずつゲージを増やす反復処理
		$".".value += 1
		await get_tree().create_timer(0.5 / mp_healing).timeout
		text_update()

func _on_buttle_mp_1(cost: int) -> void:
	monster.MP -= cost
	for i in range(cost): # 少しずつゲージを減らす反復処理
		$".".value -= 1
		await get_tree().create_timer(0.5 / cost).timeout
		text_update()

func text_update():
	$mp_text.text = " [color=aqua][b]MP[/b] %3d/" % $".".value + "%3d[/color]" % monster.maxMP
