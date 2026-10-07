## [SaveData]及び[Deck]のセーブとロードを行うシングルトン
extends Node

## [code]validate_deck[/code]の実行結果
enum DeckValidationResult {
	UNKNOWN_ERROR = -1, ## 以下のいずれにもあてはまらないエラー
	OK, ## エラーなし
	MIGRATION_REQUIRED, ## サポート対象内ですが補正が必要なデータを読み込もうとしています
	OUTDATED_VERSION_DATA, ## サポート対象外のバージョンのデータを読み込もうとしています
	FUTURE_VERSION_DATA, ## 現在のバージョン以降のデータを読み込もうとしています
	BETA_DATA_IN_MASTER, ## 製品版でβ版データを読み込もうとしています
	MASTER_DATA_IN_BETA, ## β版で製品版データを読み込もうとしています
	INVALID_MONSTER_COUNT, ## 全ての枠にモンスターが登録されていません
	DUPLICATE_MONSTER_ID, ## モンスターがデッキ内で重複しています
}

const SAVE_DATA_PATH: String = "user://savedata.sav"
const SAVE_DATA_PATH_BETA: String = "user://savedata_beta.sav"
const DECK_SAVE_DATA_PATH: String = "user://deck_slot_%02d.res"
const SAVE_KEY: String = "I'm watching you"

const MIN_SUPPORTED_VERSION: String = "4.4.1" ## このバージョン未満のデータはサポート対象外
const MIGRATION_THRESHOLD_VERSION: String = "4.4.1" ## このバージョン未満のデータはサポート対象内ですがデータを自動修正する必要があります

var save_data: SaveData
var is_save_mode: bool = true ## デッキをセーブするモードかどうか
var can_autosave: bool = true ## オートセーブを行うかどうか

# 以下関数内の処理に生成AIのコードを使用しています
## [Dictionary]に変換されたデータとファイルパスを引数として、データをファイルにセーブします
func _save_file(data: Dictionary[StringName, Variant], path: String) -> void:
	var file := FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, SAVE_KEY) ## 保存先ファイル
	if file:
		file.store_var(data)
		file.close()
	else:
		var err := FileAccess.get_open_error()
		printerr("セーブ先のファイルが存在しません。%s (エラーコード: %d)" % [error_string(err), err])

# 以下関数内の処理に生成AIのコードを使用しています
## ファイルパスを引数として、ファイルからロードして[Dictionary]を返します
func load_file(path: String) -> Dictionary[StringName, Variant]:
	if not FileAccess.file_exists(path):
		return {}
	
	var file := FileAccess.open_encrypted_with_pass(path, FileAccess.READ, SAVE_KEY) ## 読込元ファイル
	if not file:
		var err := FileAccess.get_open_error()
		printerr("セーブファイルが開けません。%s (エラーコード: %d)" % [error_string(err), err])
		return {}
	
	var result = file.get_var()
	file.close()
	
	if typeof(result) != TYPE_DICTIONARY:
		printerr("セーブデータが破損しています")
		return {}
	
	var typed_result: Dictionary[StringName, Variant] = {} ## 型付き辞書に変換された辞書
	typed_result.assign(result)
	
	return typed_result

# 以下関数内の処理に生成AIのコードを使用しています
## ファイルパスを引数として、そのファイルを削除します
func _delete_file(path: String) -> void:
	if FileAccess.file_exists(path):
		var err := DirAccess.remove_absolute(path)
		
		if err != OK:
			printerr("セーブデータの削除に失敗しました: %s" % err)
		else:
			print("セーブデータを削除しました")
	else:
		printerr("セーブデータが存在しません: %s" % path)

## [SaveData]をセーブします
func save_game() -> void:
	if not can_autosave:
		return
	
	var path: String ## セーブデータファイルパス
	if Global.IS_BETA:
		path = SAVE_DATA_PATH_BETA
	else:
		path = SAVE_DATA_PATH
	
	_save_file(_resource_to_dict(save_data), path)

## [SaveData]をロードします[br]読み込み元のデータが存在しない場合、新規セーブデータを作成します
func load_game() -> void:
	var path: String ## セーブデータファイルパス
	if Global.IS_BETA:
		path = SAVE_DATA_PATH_BETA
	else:
		path = SAVE_DATA_PATH
	
	var dict: Dictionary[StringName, Variant] = load_file(path)
	# セーブデータが存在しない時、新規セーブデータ作成
	if dict.is_empty():
		save_data = SaveData.new()
		save_game()
		
		# TODO 不要？
		var scene = Global.get_tree().current_scene
		if not scene:
			printerr("シーンが存在しません")
			return
	
	var data: SaveData = _dict_to_resource(SaveData, dict) as SaveData
	# 現在のバージョン以降のデータの場合、オートセーブを切り既存データが上書きされるのを防ぐ
	if not Global.is_version_older(data.version) and data.version != Global.version:
		can_autosave = false
		save_data = SaveData.new()
		
		await DialogManager.set_dialog(preload("res://resource/dialog_data/save_manager/load_from_current_version_onward.tres"), [Global.version])
		await DialogManager.set_dialog(preload("res://resource/dialog_data/save_manager/load_from_current_version_onward_2.tres"))
		DialogManager.hide_dialog()
	
	# TODO 過去のバージョンのデータだった場合、互換性があるかチェックし、
	# データのバージョンを更新する処理を実装する必要あり。
	else:
		save_data = data
	
	load_deck(0)

## [SaveData]を削除します[br]その後新規セーブデータを作成します
func delete_game() -> void:
	var path: String ## セーブデータファイルパス
	if Global.IS_BETA:
		path = SAVE_DATA_PATH_BETA
	else:
		path = SAVE_DATA_PATH
	
	_delete_file(path)
	load_game() # セーブデータ削除後に新規セーブデータを作成するため

## 指定したindexのデッキスロットに現在の[Deck]をセーブします
func save_deck(index: int) -> void:
	_save_file(_resource_to_dict(Global.player_deck), DECK_SAVE_DATA_PATH % index)

## 指定したindexのデッキスロットの[Deck]を返します
func load_deck(index: int) -> Deck:
	return _dict_to_resource(Deck, load_file(DECK_SAVE_DATA_PATH % index)) as Deck

## 指定したindexのデッキスロットのセーブデータを削除します
func delete_deck(index: int) -> void:
	_delete_file(DECK_SAVE_DATA_PATH % index)

## 引数の[Deck]が有効な状態であるかどうかを検証し、その結果を返します
func validate_deck(deck: Deck) -> DeckValidationResult:
	# 読み込み不可
	if Global.is_version_older(deck.version, MIN_SUPPORTED_VERSION):
		return DeckValidationResult.OUTDATED_VERSION_DATA
	
	if not Global.is_version_older(deck.version) and deck.version != Global.version:
		return DeckValidationResult.FUTURE_VERSION_DATA
	
	if deck.is_beta != Global.IS_BETA:
		if deck.is_beta:
			return DeckValidationResult.BETA_DATA_IN_MASTER
		else:
			return DeckValidationResult.MASTER_DATA_IN_BETA
	
	if deck.has_empty_slot() or deck.monster.size() != 3:
		return DeckValidationResult.INVALID_MONSTER_COUNT
	
	if deck.has_duplicate_monster():
		return DeckValidationResult.DUPLICATE_MONSTER_ID
	
	# 読み込み可能 データの自動修正処理は別途実装すること
	if Global.is_version_older(deck.version, MIGRATION_THRESHOLD_VERSION):
		return DeckValidationResult.MIGRATION_REQUIRED
	
	return DeckValidationResult.OK

# 以下関数内の処理に生成AIのコードを使用しています
## [Resource]を[Dictionary]に変換します
func _resource_to_dict(res: Resource) -> Dictionary[StringName, Variant]:
	var dict: Dictionary[StringName, Variant] = {}
	for prop: Dictionary in res.get_property_list():
		var usage: int = prop["usage"] as int
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) and (usage & PROPERTY_USAGE_STORAGE):
			var prop_name: StringName = prop["name"] as StringName
			dict[prop_name] = res.get(prop_name)
			
	return dict

# 以下関数内の処理に生成AIのコードを使用しています
## [Dictionary]を[param resource_script]で指定したカスタムリソース型に変換します
func _dict_to_resource(resource_script: Script, dict: Dictionary[StringName, Variant]) -> Resource:
	var res: Resource = resource_script.new()
	for key: StringName in dict:
		if key in res:
			res.set(key, dict[key])
	
	return res
