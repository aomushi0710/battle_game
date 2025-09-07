extends RefCounted
class_name Deck

var monster_dict = [null ,null ,null] ## monsterの全ての形態が辞書として登録される
var monster = [null, null, null] ## monsterの現在の状態が全て入る
var action = [[],[],[]]
var second_form_action = [[],[],[]] ## 第二形態の技を登録
var third_form_action = [[],[],[]] ## 第三形態の技を登録
var chance = [[],[],[]] ## 各技の出現確率を登録
var skill = [0, 0, 0] ## スキルパターン(index)を格納
var effect = [{},{},{}] ## 各モンスターのエフェクト状態を登録

## デッキ内のモンスターに進化技が登録されているかを調べ、あれば対応する配列に格納する関数
func evolution_check() -> void:
	second_form_action = [[],[],[]] # 初期化
	third_form_action = [[],[],[]]
	for i in range(3):
		var current_monster = monster_dict[i] # Dictionary型
		var current_action = action[i] # Array[Action]型
		
		if len(current_monster) >= 2:
			var second_form: Monster = current_monster[Monster.Form.第二形態]
			for act in current_action:
				if act in second_form.actions:
					second_form_action[i].append(act)
			
			if len(current_monster) >= 3:
				var third_form: Monster = current_monster[Monster.Form.第三形態]
				for act in current_action:
					if act in third_form.actions:
						third_form_action[i].append(act)

# カスタムクラスのduplicate
func duplicate() -> Deck:
	var deck = Deck.new()
	deck.monster_dict = monster_dict.duplicate()
	deck.monster = monster.duplicate()
	deck.action = action.duplicate()
	deck.second_form_action = second_form_action.duplicate()
	deck.third_form_action = third_form_action.duplicate()
	deck.chance = chance.duplicate()
	deck.skill = skill.duplicate()
	deck.effect = effect.duplicate()
	return deck
