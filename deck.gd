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

## ランダムデッキ生成機
func deck_creator() -> void:
	var monster_id_list: Array[int] = [0] # 選ばれたモンスターのIDを登録と0だけ
	var monster_id: int = 0
	for mon in monster: # 全モンスターからランダムに選ぶ。iは0-2が入りモンスターの位置を表す。
		# Global.enemy_deck[i]["id"] は敵モンスター[i]枠目のモンスターidが入ります
		while monster_id in monster_id_list: # 被りがでなくなるまで繰り返す
			# ID-1とID0は対象外、randi()で割った値は0を含むので+1して修正
			monster_id = randi() % (len(Global.monster_data) - 2) + 1
		monster_id_list.append(monster_id)
		
		mon.evolution_forms = Global.monster_data[monster_id]
		mon.monster = Global.monster_data[monster_id][0].duplicate()
		
		mon.monster.random_action_selector(
			mon.action, mon.chance)

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
