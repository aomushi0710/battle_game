class_name BattleMonster
extends TextureButton

const DAMAGE_TEXT = preload("res://damage_text.tscn")
const EFFECT_ICON = preload("res://effect_icon.tscn")
var tween: Tween
var parent: Node ## 常にbattleノードを参照するように調整される変数
var player: bool ## true:味方 false:敵
var index: int
var field: bool ## モンスターが場に出ている時[code]true[/code]
var data: Monster: ## モンスターの現在の状態 INFO バトル中に更新される場合あり
	set(value):
		data = value
		ui_update()

var effect_list: Array[MonsterEffect] = [] ## エフェクトが格納される配列　INFO 初期値はなし(空)
var death: bool = false
var text_setter_callback: Callable ## dialogのtext_setter
var chance_range: Array[int] ## 抽選に用いる範囲
var generated_action: Array[Action] ## 乱数による抽選で生成された技の配列
var available_action: Array[Action] ## 実際に表示される選択可能な技の配列

signal monster_ready ## モンスターが行動可能になった時発行されます


func _ready() -> void:
	setup()
	if index == 0:
		field = true
	else:
		field = false
	hide()


func parent_getter() -> void:
	parent = get_parent()
	while parent.name != "battle":
		parent = parent.get_parent()

## UI全般の更新を行う関数
func ui_update() -> void:
	$HP.max_value = data.maxHP
	$HP.value = data.HP
	$HP/text.text = "HP %3d/%3d" % [data.HP, data.maxHP]
	
	$MP.max_value = data.maxMP
	$MP.value = data.MP
	$MP/text.text = "MP %3d/%3d" % [data.MP, data.maxMP]
	
	$SPD.monster = data
	
	$name/element.monster = data.get_monsterform()
	$name/name.text = "[b][i]%s[/i][/b]" % data.get_monsterform().name
	texture_normal = data.get_monsterform().image

# バトル開始時セットアップ
func setup() -> void:
	# 初期値を設定
	data.HP = data.maxHP
	data.MP = data.maxMP / 5
	
	ui_update()
	# 進化技、中間進化技の置換は技がランダムで選ばれる処理の中で行われるようにする
	
	# chance_range 生成
	var sum_range = 0
	for i in len(data.chance):
		var range = data.chance[i]
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
		"[color=red]%s はやられてしまった！[/color]\n" % 
		data.get_monsterform().name + 
		"次にフィールドに出すモンスターを\n選んでください。"])
		await parent.changed
		bench_set() # 死んだモンスターをベンチにセット
		parent.player_monster = parent.player_deck[parent.player_next_index] # 次のモンスターを設定
		parent.player_monster.field_set() # 次のモンスターをフィールドにセット
		parent.player_monster.get_node("SPD").set_process(true) # 交代後のモンスターを再開
	# フィールドにいる敵モンスターを倒した時、ランダムに次を選ぶ
	elif player == false and self == enemy_monster:
		await text_setter_callback.call(0, true, [
		"[color=red]%s を倒した！[/color]\n" % data.get_monsterform().name + 
		"次にフィールドに出すモンスターを\n相手が選んでいる..."])
		await get_tree().create_timer(1).timeout # 考えるフリ
		parent.enemy_next_index = parent.random_index(false)
		bench_set()
		parent.enemy_monster = parent.enemy_deck[parent.enemy_next_index]
		parent.enemy_monster.field_set()
	else:
		if player == true:
			await text_setter_callback.call(0, true, [
			"[color=red]%s はやられてしまった！[/color]\n" % 
			data.get_monsterform().name])
		else:
			await text_setter_callback.call(0, true, [
			"[color=red]%s を倒した！[/color]\n" % 
			data.get_monsterform().name])
	get_tree().paused = false

## 進化技を引数にして、そのIDにあった進化処理を施す
func evolution(id: int) -> Array[String]:
	var pre_monster_form := data.get_monsterform()
	var pre_maxHP := pre_monster_form.status_calculator(data.level)[0]
	if id == 10001: # 進化Ⅰ
		data.form = Global.Form.第二形態
	elif id == 10002: # 進化Ⅱ
		data.form = Global.Form.第三形態
	
	# hpを引き継ぐ時、進化で伸びたmaxHPの差だけ回復する
	hp_setter(data.maxHP - pre_maxHP, false)
	ui_update()
	
	$SoundEffects/evolution.play()
	
	return [
	"[color=red]%s は \n%s に\n進化した！[/color]" % 
	[pre_monster_form.name, data.get_monsterform().name], 
	"進化によって %s の\n[color=coral]HP[/color]が[color=green]%d[/color]回復した！" % 
	[data.get_monsterform().name, data.maxHP - pre_maxHP]]

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
		while len(generated_action) < 4: # 4枠全て技で埋まるまで繰り返す
			var result = randi_range(0, 99)
			for i in len(chance_range):
				if result <= chance_range[i]: # 乱数に応じて出現する技を決定
					generated_action.append(data.action[i])
					break # 対応する技があったら終了
	
	available_action.assign(generated_action.map(
		func(act: Action): return act.evolution_check(data.data, data.form)))
	
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
func mp_setter(n: int, text: bool) -> String:
	var original_n: int = n # マイナスになるため補正されたが、元の数値を利用したい時
	
	if n > 0: # mpが回復した時、水色でアニメーション再生
		if data.MP >= data.maxMP: # 既にMPが最大値の時
			if text == true: # 技の効果やアイテムの使用時など何らかの反応が得たい時
				return (
					"[color=yellow]しかし、%s の" %
					data.get_monsterform().name +
					"[color=aqua]MP[/color]は\n減っていなかった...[/color]"
				)
			else:
				return ""
		elif data.MP + n >= data.maxMP: # 回復するとMPが最大値を越えてしまう時
			n = data.maxMP - data.MP
		damage_effect(n, 2)
	else: # MPを削られた時、dark_redでアニメーション再生
		if data.MP <= 0: # 何らかの原因で死亡時
			return ""
		damage_effect(-n, 3)
		if data.MP <= -n: # 残りMPを越えるダメージを受けた時
			n = -data.MP # MPがマイナスにならないように補正
	
	var mp_text = data.MP
	data.MP += n
	tween = get_tree().create_tween().bind_node($MP)\
	.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property($MP, "value", data.MP, 0.5)
	tween.parallel().tween_method(mp_text_update, mp_text, data.MP, 0.5)
	
	var return_text: String # textを表示する処理
	if text == true: # 能動的にmpが変動した場合？
		if n > 0: # mpが回復した時、水色でアニメーション再生
			return_text = (
				"%s の[color=aqua]MP[/color]が[color=aqua]%d[/color]回復した！" %
				[data.get_monsterform().name, n]
			)
		else:
			return_text = (
				"%s は [color=aqua]%dMP[/color]を消費した..." %
				[data.get_monsterform().name, -n]
			)
		return return_text
	else: # 受動的にmpが変動した場合?
		if n > 0: # spdゲージがたまって、mpが回復した時
			return_text = ""
		else: # 相手の技やアイテムなどによってmpを無理やり減らされた時
			return_text = (
				"%s は [color=aqua]%dMP[/color]を失った！" %
				[data.get_monsterform().name, -original_n]
			)
		return return_text

## HP変動処理関数(setter)[br]n:数値 text true:ダイアログ表示 false:ダイアログ非表示
func hp_setter(n: int, text: bool) -> String:
	var original_n: int = n # 元の数値を保存したい時に
	
	if n > 0: # hpが回復した)時、緑色でアニメーション再生
		if data.HP >= data.maxHP: # 既にHPが最大値の時
			return (
				"[color=yellow]しかし、%s の" % data.get_monsterform().name +
				"[color=coral]HP[/color]は\n減っていなかった...[/color]"
			)
		elif data.HP + n >= data.maxHP: # 回復するとHPが最大値を越えてしまう時
			n = data.maxHP - data.HP
		damage_effect(n, 0)
		$SoundEffects/heal.play()
	else: # ダメージを受けた時、オレンジ色でアニメーション再生
		if data.HP <= 0: # 何らかの原因で死亡時
			return ""
		damage_effect(-n, 1)
		$SoundEffects/damage.play()
		if data.HP <= -n: # 残りHPを越えるダメージを受けた時
			n = -data.HP # HPがマイナスにならないように補正
	
	var hp_text = data.HP
	data.HP += n
	tween = get_tree().create_tween().bind_node($HP)\
	.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property($HP, "value", data.HP, 0.5)
	tween.parallel().tween_method(hp_text_update, hp_text, data.HP, 0.5)
	
	var return_text: String # textを表示する処理
	if text == true:
		if n > 0: # hpが回復した時、緑色でアニメーション再生
			return_text = (
				"%s の[color=coral]HP[/color]が[color=green]%d[/color]回復した！" %
				[data.get_monsterform().name, n]
			)
		else:
			return_text = (
				"%s は[color=orange]%d[/color]ダメージを受けた！" %
				[data.get_monsterform().name, -original_n]
			)
	
	return return_text

## hp_setterからhp_textの変化アニメーション用 
func hp_text_update(hp: int) -> void:
	$HP/text.text = "HP %3d/%3d" % [hp, data.maxHP]

## hp_setterからhp_textの変化アニメーション用 
func mp_text_update(mp: int) -> void:
	$MP/text.text = "MP %3d/%3d" % [mp, data.maxMP]

## 増減した数値を視覚的に表示するエフェクトアニメーションを再生する関数
func damage_effect(dmg: int, type: int) -> void:
	var text = DAMAGE_TEXT.instantiate() # インスタンス生成
	match type: # type引数の値によって色を変更する
		0: # HP回復処理
			text.self_modulate = Color(Color.GREEN)
		1: # HP減少処理
			text.self_modulate = Color(Color.ORANGE)
		2: # MP回復処理
			text.self_modulate = Color(Color.AQUA)
		3: # MP減少処理
			text.self_modulate = Color(Color.DARK_RED)
		_: # 不明な引数の場合
			text.self_modulate = Color(Color.WHITE)
	
	var font_size: int = 30 + 10 * len(str(dmg)) ## ダメージの桁数からサイズを求める
	text.text = "[font_size=%d][b][i]%d[/i][/b][/font_size]" % [font_size, dmg]
	add_child(text)
