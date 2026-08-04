extends Resource
class_name Deck

@export var name: String ## デッキ名

@export var monster: Array[Monster] = [Monster.new(), Monster.new(), Monster.new()]

## 全てのモンスター選択を解除し、デッキをリセットします。
func clear() -> void:
	monster = [Monster.new(), Monster.new(), Monster.new()]

## デッキ内にモンスターが1体も存在していなければ[code]true[/code]を返します。
func is_empty() -> bool:
	for mon in monster:
		if mon and mon.data:
			return false
	
	return true

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
	clear()
	
	## 実際にランダム選択の候補となるモンスターIDの一覧。[br]
	## ALERT [code]keys()[/code]や[code]fillter()[/code]を利用するので、
	##型は[Array]とし、[Array][lb][int][rb]のようなネストができない。
	var candidate_ids: Array
	if is_player:
		candidate_ids = Global.save_data.monster_levels.keys()
	else:
		candidate_ids = id_table.duplicate()
		if candidate_ids.is_empty():
			candidate_ids = Global.monster_data.keys().filter(
				func(i: int): return i > 0)
	
	if len(candidate_ids) < 3:
		push_error("デッキに必要なモンスター数が不足しています！")
		return
	
	for mon in monster: # 3枠全てに対して
		var id = candidate_ids.pick_random()
		candidate_ids.erase(id)
		
		mon.data = Global.monster_data[id]
		
		if is_player:
			mon.level = Global.save_data.monster_levels[id]
		else:
			mon.level = randi_range(min_level, max_level)
		
		mon.random_action_selector()

## バトル終了時に呼び出され、初期化を行う関数[br]
func battle_finished() -> void:
	for mon in monster:
		mon.form = Global.Form.第一形態
