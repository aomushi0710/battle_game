class_name SaveManager
## 各種データのセーブとロードを行うクラス

## データとキーを引数として、暗号化及び複合化を行ったデータを返す関数
static func xor_encrypt(data: PackedByteArray, key: String) -> PackedByteArray:
	var result := PackedByteArray()
	var key_bytes = key.to_utf8_buffer()
	var key_len = key_bytes.size()
	for i in range(data.size()):
		result.append(data[i] ^ key_bytes[i % key_len])
	return result

## [Dictionary]型のデータとファイルパスを引数として、データをファイルにセーブする関数
static func save_file(data: Dictionary, path: String, key: String = "I'm watching you") -> void:
	var buffer := PackedByteArray() ## バイト列に変換されたデータ
	buffer = var_to_bytes(data)

	var encrypted := xor_encrypt(buffer, key) ## バイト列を暗号化したデータ

	var file := FileAccess.open(path, FileAccess.WRITE) ## 保存先ファイル
	if file:
		file.store_buffer(encrypted)
		file.close()
	else:
		printerr("セーブ先のファイルが存在しません")

## ファイルパスを引数として、データをファイルからロードして[Dictionary]型で返す関数
static func load_file(path: String, key: String = "I'm watching you") -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ) ## 読込元ファイル
	if not file:
		printerr("セーブファイルが開けません")
		return {}
	var encrypted := file.get_buffer(file.get_length()) ## バイト列を暗号化したデータ
	file.close()

	var decrypted := xor_encrypt(encrypted, key) ## バイト列を復号化したデータ

	var result = bytes_to_var(decrypted) ## バイト列から変換されたデータ
	if typeof(result) != TYPE_DICTIONARY:
		printerr("セーブデータが破損しています")
		return {}
	
	return result

## ファイルパスを引数として、そのファイルを削除する関数
static func delete_file(path: String) -> void:
	if FileAccess.file_exists(path):
		var err := DirAccess.remove_absolute(path)
		
		if err != OK:
			printerr("セーブデータの削除に失敗しました: %s" % err)
		else:
			print("セーブデータを削除しました")
	else:
		printerr("セーブデータが存在しません: %s" % path)

## [SaveData]をセーブする関数
static func save_game() -> void:
	var path: String ## セーブデータファイルパス
	if Global.VERSION_BETA == true:
		path = Global.save_data_path_beta
	else:
		path = Global.save_data_path
	
	save_file(Global.save_data.to_dictionary(), path)

## [SaveData]をロードする関数
static func load_game() -> void:
	var path: String ## セーブデータファイルパス
	if Global.VERSION_BETA == true:
		path = Global.save_data_path_beta
	else:
		path = Global.save_data_path
	
	var dict := load_file(path)
	dict = cheat_check(dict)
	# セーブデータが存在しない時、新規セーブデータ作成
	if dict == {}:
		Global.save_data = SaveData.new()
		save_game()
		
		var scene = Global.get_tree().current_scene
		if not scene:
			printerr("シーンが存在しません")
			return
		
		Global.accept_dialog.display_dialog(
				"セーブデータが存在しません！\n新たなセーブデータを作成しました。", 
				"新規セーブデータ作成"
		)
	
	# 現在のバージョン以降のデータの場合、オートセーブを切り、既存データの上書きされるのを防ぐ
	elif (
		not Global.is_version_older(dict["version"]) and 
		dict["version"] != Global.version
	):
		Global.auto_save = false # オートセーブを切る
		Global.save_data = SaveData.new()
		
		Global.accept_dialog.display_dialog(
			"現在のバージョン ver %s " % Global.version + 
			"\n以降に作成されたデータのため、ロードできません。\n\n" + 
			"仮のセーブデータをロードしました。" + 
			"\n現在のバージョンでもプレイ可能ですが、進行状況はセーブされません。" + 
			"\nまた、既存データの破損については一切の責任を負いません！"
		)
	# TODO 過去のバージョンのデータだった場合、互換性があるかチェックし、
	# データのバージョンを更新する処理を実装する必要あり。
	else:
		Global.save_data = SaveData.from_dictionary(dict)
	
	load_deck(0, false) # ゲーム起動時のロードはダイアログを表示しない

## [SaveData]に不正な改変が行われていないかを検証し、問題なければそのままデータを返す関数
static func cheat_check(data: Dictionary) -> Dictionary:
	return data

## [DeckSaveData]をセーブする関数
static func save_deck(slot: int, show_dialog: bool = true) -> void:
	var has_empty_slot = Global.player_deck.monster.any(
		func(m): return m.data == null
	)
	
	if Global.player_deck.monster.size() < 3 or has_empty_slot:
		Global.accept_dialog.display_dialog(
				"デッキをセーブするには、全ての枠を埋めてください！")
		return
	
	# 技のArray[Action]を技のIDのArray[int]に変換
	var action_id: Array[Array] = [[],[],[]] ## 技がIDに変換されたもの
	for i in range(3): # 全てのモンスターの技のIDのリストを生成
		action_id[i] = Global.player_deck.monster[i].action.map(
			func(act: Action): return act.data.id
		)
	
	var deck_data := {
		"name": Global.player_deck.name,
		
		"first":{
			"id": Global.player_deck.monster[0].data.id, # Monster -> int
			"action": action_id[0], # Array[Action] -> Array[int]
			"chance": Global.player_deck.monster[0].chance, # Array[int]
		},
		"second":{
			"id": Global.player_deck.monster[1].data.id,
			"action": action_id[1],
			"chance": Global.player_deck.monster[1].chance,
		},
		"third":{
			"id": Global.player_deck.monster[2].data.id,
			"action": action_id[2],
			"chance": Global.player_deck.monster[2].chance,
		},
		
		"version": Global.version,
		"beta": Global.VERSION_BETA
	}
	
	save_file(deck_data, "user://deck_slot_%d.txt" % slot)
	if show_dialog:
		Global.accept_dialog.display_dialog(
				"デッキのセーブが完了しました！", 
				"✅セーブ完了✅"
		)

## [DeckSaveData]をロードする関数
static func load_deck(slot: int, show_dialog: bool = true) -> void:
	var deck_data := load_file("user://deck_slot_%d.txt" % slot)
	deck_data = deck_cheat_check(slot, deck_data)
	
	if deck_data.is_empty():
		return
	# β版で正式版、正式版でβ版のデータをロードしようとした時
	elif deck_data["beta"] != Global.VERSION_BETA:
		if Global.VERSION_BETA == true: # β版
			Global.accept_dialog.display_dialog(
					"βバージョンで保存されたデータではないためロードできません。")
		else: # 正式リリース版
			Global.accept_dialog.display_dialog(
					"βバージョンで保存されたデータはロードできません")
		return
	
	# ALERT βver4.4.0以下のデータはバージョン管理の型が違うので互換性がない
	# ただしβ版のみのため、正式リリース後は不要
	elif deck_data["version"] is float:
		Global.accept_dialog.display_dialog(
				"バージョン管理方法の変更に伴い、\n" + 
				"β ver 4.4.0以下で保存されたデータのためロードできません。"
		)
		return
	
	# 現在のバージョン以降のデータの場合
	elif (
		not Global.is_version_older(deck_data["version"]) and 
		deck_data["version"] != Global.version
	):
		Global.accept_dialog.display_dialog(
				"現在のバージョン ver %s " % Global.version + 
				"以降に作成されたデータのため、\nロードできません。"
		)
		return
	
	#elif deck_data["version"] >= 3.0 and deck_data["version"] < 4.4: # ver3.0~
		#accept_dialog.display_dialog(
			#"過去のバージョンで保存されたデータをロードしました。\n" + 
			#"ロードされたデータを再度セーブするとデータのバージョンも更新されます。\n" + 
			#"[color=yellow]⚠️一度更新したバージョンは元に戻せません⚠️[/color]", "")
	else:
		if show_dialog:
			Global.accept_dialog.display_dialog(
					"デッキのロードが完了しました！", 
					"✅ロード完了✅"
			)
	# TODO 過去のバージョンのデータだった場合、互換性があるかチェックし、
	# データのバージョンを更新する処理を実装する必要あり。
	
	# 復元処理
	var index: Array[String] = ["first", "second", "third"]
	Global.player_deck = Deck.new() # 初期化
	
	Global.player_deck.name = deck_data["name"]
	for i in range(3):
		var pos: Dictionary = deck_data[index[i]] # deck_data["first"]など
		
		var actions: Array[Action] ## セーブデータのidから、復元された技のリスト
		
		# id セーブデータから取得したActionData型のID
		# act セーブデータのモンスターIDに対応した
		# MonsterDataのactionプロパティから取得したAction型のリソース
		# これらのActionData型のIDが一致するものだけを復元
		for id: int in pos["action"]:
			for act: Action in Global.monster_data[pos["id"]].action:
				if id == act.data.id:
					actions.append(act)
					break
		
		Global.player_deck.monster[i].data = Global.monster_data[pos["id"]]
		Global.player_deck.monster[i].action = actions
		Global.player_deck.monster[i].chance = pos["chance"]
		
	save_deck(0, false) # デッキをロードしたことをセーブして記録する

## [DeckSaveData]に不正な改変が行われていないかを検証し、問題なければそのままデータを返す関数
static func deck_cheat_check(slot: int, data: Dictionary) -> Dictionary:
	if data.is_empty():
		return data
	
	# デッキ内にモンスターが重複している
	if (data["first"]["id"] == data["second"]["id"] or 
		data["first"]["id"] == data["third"]["id"] or 
		data["second"]["id"] == data["third"]["id"]):
		delete_file("user://deck_slot_%d.txt" % slot)
		OS.alert("セーブデータ%dが削除されました。" % slot, \
		"デッキに同じモンスターを入れられないのは知っているだろう？")
		return {}
	
	else: # チートなし
		return data
