extends Control

const monster_scene = preload("res://battle_monster.tscn")
var next_index: int = 0 # 次にチェンジするモンスターのindex
var player_monster: Monster
var enemy_monster: Monster

# 味方と敵のデッキを準備　TODO　敵側の処理が未実装 deck を判別する条件文で作る
func _on_tree_entered() -> void:
	for deck in [Global.deck1, Global.enemy_deck]:
		for i in len(deck.monster):
			var monster = monster_scene.instantiate()
			monster.setup(deck.monster_dict[i], deck.monster[i], deck.action[i], 
			deck.middle_evolution[i], deck.evolution[i], deck.chance[i])
			match deck:
				Global.deck1:
					monster.name = "player%d" % (i + 1)
					if i == 0:
						self.add_child(monster)
						monster.position = Vector2(396.8, 192)
						# ここから均等に真ん中から距離を置く
					else:
						$player_deck/player_deck.add_child(monster)
				Global.enemy_deck:
					monster.name = "enemy%d" % (i + 1)
					if i == 0:
						self.add_child(monster)
						monster.position = Vector2(576, 192)
						# ここから均等に真ん中から距離を置く
					else:
						$enemy_deck/enemy_deck.add_child(monster)
	
	next_index = 2
	_on_change_button_up()
	
	player_monster = Global.deck1.monster[0] # 先発モンスター
	enemy_monster = Global.enemy_deck.monster[0]


func _on_change_button_up() -> void:
	match next_index:
		0, 1:
			next_index += 1
		2:
			next_index = 0
	$button/change.texture_normal = Global.deck1.monster[next_index].image
