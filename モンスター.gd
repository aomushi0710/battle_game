extends Node

const monster = "user://モンスター.txt"

func _ready() -> void:
	# モンスター処理を呼び出す
	_monster()
	
func _monster() -> void:
	# モンスターを辞書型で定義.
	var monster = {}

	# モンスターデータ.	
	var slime = {} # 勇者のデータ.
	slime["id"] = 1
	slime["name"] = "スライム"
	slime["hp"] = 100
	slime["mp"] = 20
