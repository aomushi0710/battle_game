extends Resource
class_name Deck

@export var monster: Array[DeckMonster] = [DeckMonster.new(), DeckMonster.new(), DeckMonster.new()]

@export var name: String ## デッキ名


func evolution_forms_setting() -> void:
	for mon in monster:
		mon.evolution_forms = Global.monster_data[mon.monster.id]

## デッキ内のモンスターに進化技が登録されているかを調べ、あれば対応する配列に格納する関数
func evolution_check() -> void:
	for mon in monster:
		mon.second_form_action.clear()
		mon.third_form_action.clear()
		
		if len(mon.evolution_forms) >= 2:
			var second_form: Monster = mon.evolution_forms[Monster.Form.第二形態]
			for act in mon.action:
				if act in second_form.actions:
					mon.second_form_action.append(act)
			
			if len(mon.evolution_forms) >= 3:
				var third_form: Monster = mon.evolution_forms[Monster.Form.第三形態]
				for act in mon.action:
					if act in third_form.actions:
						mon.third_form_action.append(act)

## ランダムデッキ生成関数[br]
## プレイヤーのデッキを生成時([code]if is_player[/code])、
##セーブデータから使用可能なモンスターとそのレベルを読み込んで編成します。[br]
## そうでなければ、敵のデッキを[param id_table]内のIDを持つモンスターからランダムに選び、
##レベルを[param min_level]～[param max_level]に設定して編成します。[br]
## [param id_table]が空の場合は全てのモンスターからランダムに選ばれる
func deck_creator(
		is_player: bool = true,
		id_table: Array[int] = [],
		min_level: int = 1, 
		max_level: int = 1, 
) -> void:
	## 実際にランダム選択の候補となるモンスターIDの一覧。[br]
	## ALERT [code]keys()[/code]や[code]fillter()[/code]を利用するので、
	##型は[Array]とし、[Array][lb][int][rb]のようなネストができない。
	var candidate_ids: Array[int]
	if is_player:
		candidate_ids = Global.save_data.monster_levels.keys()
	else:
		candidate_ids = id_table.duplicate()
		if candidate_ids.is_empty():
			candidate_ids = Global.monster_data.keys().filter(func(i): return i > 0)
	
	if len(candidate_ids) < 3:
		push_error("デッキに必要なモンスター数が不足しています！")
		return
	
	for mon in monster: # 3枠全てに対して
		var id = candidate_ids.pick_random()
		candidate_ids.erase(id)
		
		mon.evolution_forms = Global.monster_data[id]
		mon.monster = Global.monster_data[id][0].duplicate()
		if is_player:
			mon.level = Global.save_data.monster_levels[id]
		else:
			mon.level = randi_range(min_level, max_level)
		
		mon.monster.random_action_selector(mon.action, mon.chance)

## バトル終了時に呼び出され、置き換えられた進化技を元に戻す関数[br]
## 第一形態に戻す・エフェクトを空にする・
func battle_finished() -> void:
	for i in range(3):
		monster[i].monster = monster[i].evolution_forms[0]
		
		for j: int in len(monster[i].action):
			var second := 0 ## second_form_action用index
			var third := 0 ## third_form_action用index
			match monster[i].action[j].id:
				10001: # 進化Ⅰが残っている場合
					monster[i].action[j] = monster[i].second_form_action[second]
					second += 1
				10002: # 進化Ⅱが残っている場合
					monster[i].action[j] = monster[i].third_form_action[third]
					third += 1
