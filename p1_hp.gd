extends TextureProgressBar

var index = 0
var monster_dict: Dictionary = Global.player_deck.monster_dict[index]
var monster: Monster = Global.player_deck.monster[index]
var dmg_text = preload("res://damage_text.tscn")

signal death

func _on_tree_entered():
	monster = Global.player_deck.monster[index]
	$".".max_value = monster.maxHP
	$".".value = monster.HP
	text_update()

func text_update():
	$hp_text.text = " [color=red][b]HP[/b] %3d/" % int($".".value) + \
	"%3d[/color]" % monster.maxHP

func _on_enemies_damage_1(dmg: int) -> void:
	if dmg == 0: # ダメージなし処理
		return
	var hp = monster.HP # 減らす前のHPを保持
	monster.HP -= dmg
	if monster.HP < 0: # hpを負の数にしない
		monster.HP = 0
	
	$"/root/Node2D/log_window/log".text += monster.name + \
	" は[color=red]%d[/color]ダメージを受けた！\n" % dmg
	
	if hp <= dmg: # 死亡時処理
		death.emit()
		$"../p1_spd".set_process(false)
		$"/root/Node2D/buttle//player1".color = Color(0,0,0,0.8)
		$"/root/Node2D/buttle//player1/player1".texture_normal = load("res://お墓.PNG")
		$"/root/Node2D/log_window/log".text += "[color=red]" + monster.name + \
		" はやられてしまった！[/color]\n"
	
	damage_effect(dmg,1)
	if dmg > hp: # 現在HPを越えるダメージを受けた時、ゲージ減少速度を調整
		dmg = hp
	for i in range(dmg): # 少しずつゲージを減らす反復処理
		$".".value -= 1
		await get_tree().create_timer(0.5 / dmg).timeout
		text_update()
	$".".value = monster.HP # ズレ修正
	text_update()

func _on_buttle_healing_1(heal: int) -> void:
	var hp = monster.HP
	if hp == monster.maxHP: # hpが既に最大だった場合
		$"/root/Node2D/log_window/log".text += "[color=yellow]しかしHPは減っていなかった！[/color]\n"
		return
	elif hp + heal > monster.maxHP: # 回復量が減っているhpよりも多かった場合
		heal = monster.maxHP - hp
	
	monster.HP += heal
	if monster.HP > monster.maxHP: # hpが最大値を越えないように
		monster.HP = monster.maxHP
	
	damage_effect(heal,0)
	$"/root/Node2D/log_window/log".text += monster.name + \
	"はHPが[color=green]%d[/color]回復した！\n" % heal
	for i in range(heal):
		$".".value += 1
		await get_tree().create_timer(0.5 / heal).timeout
		text_update()
	$".".value = monster.HP # ズレ修正
	text_update()

func damage_effect(dmg: int, type: int) -> void:
	var text = dmg_text.instantiate() # インスタンス生成
	var color = Color(0,0,0,0)
	if type == 0: # HP回復処理
		text.text = "[b][i][color=green] %d[/color][/i][/b]" % dmg
		color = Color(Color.GREEN,1.0) # 緑色指定
	elif type == 1: # 被ダメージ処理
		text.text = "[b][i] %d[/i][/b]" % dmg # ダメージエフェクト文字
		color = Color(Color.ORANGE,1.0) # オレンジ色指定
	elif type == 2: # MP回復処理
		text.text = "[b][i] %d[/i][/b]" % dmg # ダメージエフェクト文字
		color = Color(Color.AQUA,1.0) # 青色指定
	get_parent().add_child(text) # child指定
	text.position =  Vector2(25 + randi() % 100,randi() % 156) # 端や下側に出現しないように調整
	text.self_modulate = color # 色適用
	text.show()
	await get_tree().create_timer(1.0).timeout # 1秒停止
	for i in range(50):
		text.position.y -= 1 #上に移動
		if i > 10: # 少し移動してから
			color.a -= 0.025 # 徐々に透明化
			text.self_modulate = color # 変更点を適用
		await get_tree().create_timer(0.01).timeout
	text.queue_free() # 削除
	
func reload(heal: int) -> void:
	_on_tree_entered() # 更新
	_on_buttle_healing_1(heal) # 進化HP回復処理
