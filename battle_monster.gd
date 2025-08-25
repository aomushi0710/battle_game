class_name BattleMonster
extends TextureButton

const DAMAGE_TEXT = preload("res://damage_text.tscn")
const EFFECT_ICON = preload("res://effect_icon.tscn")
var tween: Tween
var parent: Node ## 常にbattleノードを参照するように調整される変数
var player: bool ## true:味方 false:敵
var index: int
var field: bool ## モンスターが場に出ている時[code]true[/code]
var monster_dict ## モンスターの全形態を格納する辞書
var monster: Monster ## モンスターの現在の状態 INFO バトル中に更新される場合あり
var action_list: Array ## 設定された技を格納する配列
var middle_evolution_list: Array ## 設定された中間進化技を格納する配列
var evolution_list: Array ## 設定された進化技を格納する配列
var chance_list: Array ## 技の出現確率を格納する配列
var effect_list: Array[MonsterEffect] = [] ## エフェクトが格納される配列　INFO 初期値はなし(空)
var death: bool = false
var text_setter_callback: Callable ## dialogのtext_setter
var chance_range: Array[int] ## 抽選に用いる範囲
var picked_action: Array[Action] ## 抽選され選ばれた技の配列
@onready var popup_position: Vector2i = $effect_detail.position

signal monster_ready ## モンスターが行動可能になった時発行されます


func _ready() -> void:
	if index == 0:
		field = true
	else:
		field = false
	hide()


func parent_getter() -> void:
	parent = get_parent()
	while parent.name != "battle":
		parent = parent.get_parent()

# バトル開始時セットアップ
func setup(dict: Dictionary, mon: Monster, act_list: Array, 
mid_evol_list: Array, evol_list: Array, chan_list: Array) -> void:
	# 引数から全て代入
	monster_dict = dict
	monster = mon
	action_list = act_list
	middle_evolution_list = mid_evol_list
	evolution_list = evol_list
	chance_list = chan_list
	# 初期値を設定
	monster.HP = monster.maxHP
	monster.MP = monster.maxMP / 5
	
	$HP.max_value = monster.maxHP
	$HP.value = monster.HP
	$HP/text.text = "HP %3d/%3d" % [monster.HP, monster.maxHP]
	
	$MP.max_value = monster.maxMP
	$MP.value = monster.MP
	$MP/text.text = "MP %3d/%3d" % [monster.MP, monster.maxMP]
	
	$SPD.max_value = Global.spd_gauge
	$SPD.value = 0
	$SPD.monster = monster
	
	$name/element.selected(monster)
	$name/name.text = "[b][i]%s[/i][/b]" % monster.name
	self.texture_normal = monster.image
	# 進化技、中間進化技の置換
	if evolution_list.is_empty() == false: # 進化技が存在する場合
		var evol_index = [] # TODO この変数は必要のない可能性があるので、今後調査する
		for i in len(action_list):
			if action_list[i] in evolution_list: # 進化技の時
				# 進化技を進化Ⅱに置き換える
				action_list[i] = Global.action_data[10002].duplicate()
				action_list[i].mp = monster_dict[2].cost # 進化に必要なmp量設定
				evol_index.append(i) # 置き換えた技の位置indexを保存
		
	if middle_evolution_list.is_empty() == false: # 中間進化技も存在する場合
		var middle_evol_index = [] # TODO この変数は必要のない可能性があるので、今後調査する
		for i in len(action_list):
			if action_list[i] in middle_evolution_list: # 進化技の時
				# 進化技を進化Ⅰに置き換える
				action_list[i] = Global.action_data[10001].duplicate()
				action_list[i].mp = monster_dict[1].cost
				middle_evol_index.append(i) # 置き換えた技の位置indexを保存
	# chance_range 生成
	var sum_range = 0
	for i in len(chance_list):
		var range = chance_list[i]
		if i == 0:
			range -= 1
		sum_range += range # ex.1:10% 2:20% 3:30% 4:40%なら、[9,29,59.99]となり、
		chance_range.append(sum_range) # 乱数0~9の範囲で1が、10~29で2、30~59で3、60~99で4

## 死亡処理
func dead(player_monster: BattleMonster, enemy_monster: BattleMonster) -> void:
	get_tree().paused = true
	# フラグ立て
	death = true
	if player == true:
		match index:
			0:
				Global.p1_death = true
			1:
				Global.p2_death = true
			2:
				Global.p3_death = true
	else:
		match index:
			0:
				Global.e1_death = true
			1:
				Global.e2_death = true
			2:
				Global.e3_death = true
	effect_list.clear() # エフェクト全消し
	$effect.blink_stop()
	# お墓アニメーション
	tween = get_tree().create_tween().bind_node(self)\
	.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "self_modulate:a", 0, 0.3)
	tween.tween_callback(func(): texture_normal = load("res://image/お墓.PNG"))
	tween.tween_property(self, "self_modulate:a", 1, 0.3)
	await tween.finished
	
	parent = get_parent()
	while parent.name != "battle":
		parent = parent.get_parent()
	$SPD.set_process(false) # 死んだモンスターを停止
	$SPD.value = 0
	# 相手全滅
	if Global.e1_death == true and Global.e2_death == true and Global.e3_death == true:
		parent.battle_finish(true)
		parent.get_node("button").get_node("戻る").disabled = false
		get_tree().paused = false
		return
	# 味方全滅
	elif Global.p1_death == true and Global.p2_death == true and Global.p3_death == true:
		parent.battle_finish(false)
		parent.get_node("button").get_node("戻る").disabled = false
		get_tree().paused = false
		return
	# フィールドにいる味方モンスターがやられた時
	if player == true and self == player_monster:
		text_setter_callback.call(0, false, [
		"[color=red]%s はやられてしまった！[/color]\n" % monster.name + 
		"次にフィールドに出すモンスターを\n選んでください。"])
		await parent.changed
		bench_set() # 死んだモンスターをベンチにセット
		parent.player_monster = parent.player_deck[parent.player_next_index] # 次のモンスターを設定
		parent.player_monster.field_set() # 次のモンスターをフィールドにセット
		parent.player_monster.get_node("SPD").set_process(true) # 交代後のモンスターを再開
	# フィールドにいる敵モンスターを倒した時、ランダムに次を選ぶ
	elif player == false and self == enemy_monster:
		await text_setter_callback.call(0, true, [
		"[color=red]%s を倒した！[/color]\n" % monster.name + 
		"次にフィールドに出すモンスターを\n相手が選んでいる..."])
		await get_tree().create_timer(1).timeout # 考えるフリ
		parent.enemy_next_index = parent.random_index(false)
		bench_set()
		parent.enemy_monster = parent.enemy_deck[parent.enemy_next_index]
		parent.enemy_monster.field_set()
	else:
		if player == true:
			await text_setter_callback.call(0, true, [
			"[color=red]%s はやられてしまった！[/color]\n" % monster.name])
		else:
			await text_setter_callback.call(0, true, [
			"[color=red]%s を倒した！[/color]\n" % monster.name])
	get_tree().paused = false

## 進化技を引数にして、そのIDにあった進化処理を施す
func evolution(id: int) -> Array[String]:
	var pre_monster = monster
	if id == 10001: # 中間進化
		monster = monster_dict[1]
	elif id == 10002: # 進化
		monster = monster_dict[2]
	if player == true:
		Global.deck1.monster[index] = monster
	else:
		Global.enemy_deck.monster[index] = monster
	# hpを引き継ぐ時、進化で伸びたmaxHPの差だけ回復する
	monster.HP = pre_monster.HP
	hp_setter(monster.maxHP - pre_monster.maxHP, false)
	monster.MP = pre_monster.MP
	
	$HP.max_value = monster.maxHP
	$HP/text.text = "HP %3d/%3d" % [monster.HP, monster.maxHP]
	$MP.max_value = monster.maxMP
	$SPD.monster = monster
	$name/element.selected(monster)
	$name/name.text = "[b][i]%s[/i][/b]" % monster.name
	self.texture_normal = monster.image
	
	var act: int = 0 # 進化技リストのindex
	for i: int in len(action_list): # 進化技を置き換え
		if action_list[i].id == id:
			match id:
				10001:
					action_list[i] = middle_evolution_list[act]
				10002:
					action_list[i] = evolution_list[act]
				_:
					print("ERROR:不明なID")
			act += 1
	
	var delete_list = [] # 削除したい技のindexを登録するリスト
	for i in len(picked_action):
		if picked_action[i].id == id: # 進化技のID 10001 or 10002
			delete_list.append(i)
	delete_list.reverse() # indexの並びを逆順にすることで、配列の後ろから要素を削除する
	for i in delete_list:
		picked_action.remove_at(i)
	
	$SoundEffects/evolution.play()
	
	return [
	"[color=red]%s は \n%s に\n進化した！[/color]" % 
	[pre_monster.name, monster.name], 
	"進化によって %s の\n[color=coral]HP[/color]が[color=green]%d[/color]回復した！" % 
	[monster.name, monster.maxHP - pre_monster.maxHP]]

## ベンチにモンスターをセットする時の処理[br]spdゲージは溜まらない
func bench_set() -> void:
	field = false
	$HP/text.hide()
	$MP/text.hide()
	$SPD.hide()
	if player == true:
		reparent(get_parent().get_node("player_deck/player_deck"))
	else:
		reparent(get_parent().get_node("enemy_deck/enemy_deck"))

## フィールドにモンスターをセットする時の処理[br]1f待機後にspdゲージが溜まり始める
func field_set() -> void:
	field = true
	$HP/text.show()
	$MP/text.show()
	$SPD.show()
	reparent(get_parent().get_parent().get_parent())
	scale = Vector2(1, 1)
	if player == true:
		position = Vector2(500, 350)
	else:
		position = Vector2(1164, 350)

## SPDゲージが溜まり行動可能になった時の処理
func spd_max() -> void:
	# picked_action 生成
	if parent.tutorial_mode == false:
		while len(picked_action) < 4: # 4枠全て技で埋まるまで繰り返す
			var result = randi() % 100 # 0~99の100通りの乱数を生成
			for i in len(chance_range):
				if result <= chance_range[i]: # 乱数に応じて出現する技を決定
					picked_action.append(action_list[i])
					break # 対応する技があったら終了
	monster_ready.emit()

## エフェクトアイコンの追加関数
func add_effect(monster_effect: MonsterEffect) -> void:
	effect_list.append(monster_effect)
	var icon = EFFECT_ICON.instantiate()
	icon.effect = monster_effect
	$effect.add_child(icon)
	effect_icon_blink()

## エフェクトアイコンの点滅関数
func effect_icon_blink() -> void:
	if effect_list.is_empty() == false: # 何かエフェクトがあれば
		if $effect.tween == null or $effect.tween and $effect.tween.is_running() == false:
			$effect.blink() # エフェクトがあるがtweenが存在しない、もしくはtweenがあるが点滅していない時
	else:
		if $effect.tween and $effect.tween.is_running():
			$effect.blink_stop() # エフェクトがないのにtweenが存在し、点滅している時

## MP変動処理関数(setter)[br]n:数値 text true:能動的でダイアログ表示 false:受動的でダイアログ非表示
func mp_setter(n: int, text: bool) -> Array[String]:
	var original_n: int = n # マイナスになるため補正されたが、元の数値を利用したい時
	
	if n > 0: # mpが回復した時、水色でアニメーション再生
		if monster.MP >= monster.maxMP: # 既にMPが最大値の時
			if text == true: # 技の効果やアイテムの使用時など何らかの反応が得たい時
				return ["[color=yellow]しかし、%s の" % monster.name + \
				"[color=aqua]MP[/color]は\n減っていなかった...[/color]"]
			else:
				return []
		elif monster.MP + n >= monster.maxMP: # 回復するとMPが最大値を越えてしまう時
			n = monster.maxMP - monster.MP
		damage_effect(n, 2)
	else: # MPを削られた時、色でアニメーション再生
		if monster.MP <= 0: # 何らかの原因で死亡時
			return []
		damage_effect(-n, 2) # 仮で水色
		if monster.MP <= -n: # 残りHPを越えるダメージを受けた時
			n = -monster.MP # MPがマイナスにならないように補正
	
	var mp_text = monster.MP
	monster.MP += n
	tween = get_tree().create_tween().bind_node($MP)\
	.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property($MP, "value", monster.MP, 0.5)
	tween.parallel().tween_method(mp_text_update, mp_text, monster.MP, 0.5)
	
	var return_text: Array[String] # textを表示する処理
	if text == true: # 能動的にmpが変動した場合？
		if n > 0: # mpが回復した時、水色でアニメーション再生
			return_text = [
			"%s の[color=aqua]MP[/color]が[color=aqua]%d[/color]回復した！" % 
			[monster.name, n]]
		else:
			return_text = [
			"%s は [color=aqua]%dMP[/color]を消費した..." % [monster.name, -n]]
		return return_text
	else: # 受動的にmpが変動した場合?
		if n > 0: # spdゲージがたまって、mpが回復した時
			return_text = []
		else: # 相手の技やアイテムなどによってmpを無理やり減らされた時
			return_text = [
			"%s は [color=aqua]%dMP[/color]を失った！" % [monster.name, -original_n]]
		return return_text

## HP変動処理関数(setter)[br]n:数値 text true:ダイアログ表示 false:ダイアログ非表示
func hp_setter(n: int, text: bool) -> Array[String]:
	var original_n: int = n # 元の数値を保存したい時に
	
	if n > 0: # hpが回復した)時、緑色でアニメーション再生
		if monster.HP >= monster.maxHP: # 既にHPが最大値の時
			return [
			"[color=yellow]しかし、%s の[color=coral]HP[/color]は\n減っていなかった...[/color]" % 
			monster.name]
		elif monster.HP + n >= monster.maxHP: # 回復するとHPが最大値を越えてしまう時
			n = monster.maxHP - monster.HP
		damage_effect(n, 0)
		$SoundEffects/heal.play()
	else: # ダメージを受けた時、オレンジ色でアニメーション再生
		if monster.HP <= 0: # 何らかの原因で死亡時
			return []
		damage_effect(-n, 1)
		$SoundEffects/damage.play()
		if monster.HP <= -n: # 残りHPを越えるダメージを受けた時
			n = -monster.HP # HPがマイナスにならないように補正
	
	var hp_text = monster.HP
	monster.HP += n
	tween = get_tree().create_tween().bind_node($HP)\
	.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property($HP, "value", monster.HP, 0.5)
	tween.parallel().tween_method(hp_text_update, hp_text, monster.HP, 0.5)
	
	var return_text: Array[String] # textを表示する処理
	if text == true:
		if n > 0: # hpが回復した時、緑色でアニメーション再生
			return_text = [
			"%s の[color=coral]HP[/color]が[color=green]%d[/color]回復した！" % 
			[monster.name, n]]
		else:
			return_text = [
			"%s は[color=orange]%d[/color]ダメージを受けた！" % [monster.name, -original_n]]
	return return_text

## hp_setterからhp_textの変化アニメーション用 
func hp_text_update(hp: int) -> void:
	$HP/text.text = "HP %3d/%3d" % [hp, monster.maxHP]

## hp_setterからhp_textの変化アニメーション用 
func mp_text_update(mp: int) -> void:
	$MP/text.text = "MP %3d/%3d" % [mp, monster.maxMP]

## 増減した数値を視覚的に表示するエフェクトアニメーションを再生する関数
func damage_effect(dmg: int, type: int) -> void:
	var text = DAMAGE_TEXT.instantiate() # インスタンス生成
	match type: # type引数の値によって色を変更する
		0: # HP回復処理
			text.self_modulate = Color(Color.GREEN,1.0) # 緑色指定
		1: # 被ダメージ処理
			text.self_modulate = Color(Color.ORANGE,1.0) # オレンジ色指定
		2: # MP回復処理
			text.self_modulate = Color(Color.AQUA,1.0) # 青色指定
		_: # 不明な引数の場合
			text.self_modulate = Color(Color.WHITE,1.0) # 白色指定
	text.text = "[b][i]%d[/i][/b]" % dmg
	text.scale = Vector2(0, 0)
	text.position =  Vector2(40 + randi() % 100,randi() % 156) # 端や下側に出現しないように調整
	add_child(text)
	# ダメージエフェクトアニメーション
	tween = get_tree().create_tween().bind_node(text)\
	.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(text, "scale", Vector2(1.5, 1.5), 0.15) # 拡大アニメーション
	tween.tween_property(text, "scale", Vector2(1, 1), 0.05) # 縮小アニメーション
	tween.tween_interval(1.0) # 1秒停止# 移動アニメーション
	tween.tween_property(text, "position:y", text.position.y - 10, 0.1)
	# 移動+透明化アニメーション
	tween.tween_property(text, "position:y", text.position.y - 40, 0.4)
	tween.parallel().tween_property(text, "self_modulate:a", 0, 0.4)
	tween.tween_callback(text.queue_free) # 削除
