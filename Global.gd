extends Node2D

## 現在のバージョンがβ版であるかどうかを表す定数[br]
## [code]true[/code]はベータ版、[code]false[/code]は正式リリース版であることを示す
const VERSION_BETA: bool = true

var monster_data = {}
var action_data = {}
var item_data = {}

func _ready() -> void:
	directory_load("res://monster/", monster_data, true)
	directory_load("res://action/", action_data)
	directory_load("res://item/", item_data)
	
	load_game()

const main_scene = "res://メインシーン.tscn"
const deck_scene = "res://デッキセレクト.tscn"
const chara_scene = "res://キャラ選択.tscn"
const select_scene = "res://技セレクト.tscn"
const battle_scene = "res://バトル.tscn"
const debug_scene = "res://debug.tscn"
const deck_save_scene = "res://デッキセーブデータ.tscn"
const new_battle_scene = "res://新バトル.tscn"
const tutorial_scene = "res://tutorial.tscn"
const shop_scene = "res://shop.tscn"

const game_button = preload("res://game_button.tscn")
const inventory_scene = preload("res://inventory.tscn")
const action_button = preload("res://action_button.tscn")
const ability_description = preload("res://ability_description.tscn")
const damage_text = preload("res://damage_text.tscn")

const save_data_path: String = "user://savedata.sav"
const save_data_path_beta: String = "user://savedata_beta.sav"

@onready var picked_monster = [0,0,0]
@onready var deck1 := Deck.new()
@onready var enemy_deck := Deck.new()
@onready var current_deck := Deck.new()
@onready var target = 3 ## 現在攻撃対象に選択中のモンスターの位置(0~2:指定indexのモンスターを攻撃 3:未選択)
@onready var support_target = 3 ## 味方から技を受ける場合の位置(0~2:指定indexのモンスターを攻撃 3:未選択)

@onready var now_picking = 3 ## 現在選択中のモンスターの位置　3：未選択 0～2：選択中
@onready var selected_monster = 0 ## 現在選択中のモンスターID(特性・技セレクトで使用)
@onready var strategy = 0

@onready var deck_name: String
@onready var save_mode := true ## true:デッキセーブ時 false:デッキロード時

@onready var auto_save: bool = true ## true:オートセーブ false:セーブされない
@onready var save_data: SaveData
@onready var coin: int ## 所持コイン数
@onready var inv = {"item": {}} ## 所持アイテム一覧 item:バトルアイテム

const spd_gauge = 5000
const spd_correction = 30 ## spdゲージ増加量補正 SPD * spd_correction

@onready var p1_death = false ## 死亡フラグ false:生存 true:死亡
@onready var p2_death = false
@onready var p3_death = false
@onready var e1_death = false # 敵
@onready var e2_death = false
@onready var e3_death = false

enum Status {
	ATK, 
	DEF, 
	MAG, 
	RES, 
}

enum Target { ## 効果の発動対象
	なし, ## 効果を発動しません。
	近接, ## 場に出ている目の前の敵に発動できます。
	遠隔, ## 場に出ていない遠くの敵にも発動できます。
	敵全体, ## 敵全体に発動できます。
	自分, ## 自分に発動できます。
	味方単体, ## 味方を1体だけ選んで発動できます。
	味方全体, ## 味方全体に発動できます。
	敵味方全体, ##　敵全体と味方全体に発動できます。
}

enum Stage { ## バトルステージ一覧
	PLAIN
}
@onready var battle_stage: Stage ## バトルステージ

## ディレクトリのパス[param path]を指定して読み込み、[br]
##辞書[param dict]にIDをキーとしてリソースを格納する関数。[br]
## [param array_mode]が[code]true[/code]の時、サブディレクトリは[br]
##それぞれの配列にまとめられてから、格納されます。
func directory_load(path: String, dict, array_mode: bool = false):
	var dir := DirAccess.open(path)
	if dir:
		print("ディレクトリ「%s」のロードを開始..." % path)
		dir.list_dir_begin()
		var file_name: String = dir.get_next() ## ファイル名
		
		while file_name != "":
			if file_name == "." or file_name == "..":
				file_name = dir.get_next()
				continue
			
			var full_path = path.path_join(file_name) ## rootからのファイルパス
			
			if array_mode == false:
				if dir.current_is_dir():
					directory_load(full_path, dict)
				else:
					var resource = load(full_path)
					if resource:
						dict[resource.id] = resource
			else:
				if dir.current_is_dir():
					var monster_list: Array[Monster] ## モンスターの全形態
					var monster_dict = {} ## データを入れる仮の辞書
					monster_directory_load(full_path, monster_dict)
					monster_list.resize(len(monster_dict))
					for key in monster_dict:
						monster_list[key] = monster_dict[key]
					dict[monster_list[0].id] = monster_list
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
		print("ディレクトリ「%s」のロードが完了。" % path)
	else:
		print("ERROR:ディレクトリ「%s」が存在しません" % path)


func monster_directory_load(path: String, dict):
	var dir := DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next() ## ファイル名
		
		while file_name != "":
			if file_name == "." or file_name == "..":
				file_name = dir.get_next()
				continue
			
			var full_path = path.path_join(file_name) ## rootからのファイルパス
			
			var resource: Monster = load(full_path)
			if resource:
				dict[resource.form] = resource
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	else:
		print("ERROR:ディレクトリ「%s」が存在しません" % path)

## BBcodeのタグ[]を含む[param text]を平文に戻して返す関数
func strip_bbcode(text: String) -> String:
	var regex = RegEx.new()
	regex.compile("\\[.*?\\]")
	return regex.sub(text, "", true)

## 2つの配列を比較し、共通する要素が見つかれば[code]true[/code]を、
##見つからなければ[code]false[/code]を返す関数
func arrays_overlap(array1: Array, array2: Array) -> bool:
	for i in array1:
		if array2.has(i):
			return true
	return false

## 比較されるバージョン[param version1]と比較したいバージョン[param version2]を、[br]
## 引数として入力し、[param version1]の方が古い場合は[code]true[/code]、[br]
## [param version1]の方が新しい、または同一バージョンの場合は[code]false[/code]を返す関数
## [br][br][param version2]のデフォルト値は、現在バージョンを取得する関数を呼んでいる
func is_version_older(version1: String, version2: String = 
ProjectSettings.get_setting("application/config/version")) -> bool:
	var num1_array = version1.split(".") ## version1(比較元)を分割した配列
	var num2_array = version2.split(".") ## version2(比較先)を分割した配列
	
	for i in range(3): # メジャー、マイナー、パッチの順に比較
		var num1 := int(num1_array[i])
		var num2 := int(num2_array[i])
		
		if num1 < num2:
			return true
		elif num1 > num2:
			return false
		
	return false

## モンスターのステータス表示を生成する関数
func status_text(monster: Monster) -> String:
	var text = (
		"[color=coral]HP :%3d" % monster.maxHP + 
		"[/color] [color=green]SPD:%3d" % monster.SPD + 
		"[/color]\n[color=aqua]MP :%3d" % monster.supplyMP + "  /  %3d" % 
		monster.maxMP + "\n(supply  / max)[/color]\n[color=red]ATK:%3d" % 
		monster.ATK + "[/color] [color=light_blue]DEF:%3d" % 
		monster.DEF + "[/color]\n[color=dodger_blue]MAG:%3d" % 
		monster.MAG + "[/color] [color=violet]RES:%3d" % 
		monster.RES + "[/color]")
	return text


func all_status(monster: Monster, font_size: int) -> Array[RichTextLabel]:
	var name_label := RichTextLabel.new()
	var element_label := RichTextLabel.new()
	var status_label := RichTextLabel.new()
	
	for label: RichTextLabel in [name_label, element_label, status_label]: # 初期設定
		label.bbcode_enabled = true
		label.fit_content = true
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	name_label.text = "[b][i]%s[/i][/b]" % monster.name
	element_label.set_script(load("res://element_text.gd"))
	element_label.selected(monster, font_size)
	status_label.text = "\n" + status_text(monster)
	
	return [name_label, element_label, status_label]


func action_description_creator(act: Action, blank: bool) -> Array[String]:
	var range_text: String ## 技の対象
	var range_tip: String ## 技の対象の補足
	var range_blank: String = "" ## 技の対象表示の空白
	var dmg_type_text: String ## 技のステータス参照先
	var dmg_type_tip: String ## 技のステータス参照先の補足
	var dmg_type_blank: String ## 技のステータス参照先表示の空白
	
	match act.target:
		Target.なし:
			range_text = "なし"
			range_tip = "発動対象が存在しません"
		Target.近接:
			range_text = "近接"
			range_tip = "場に出ている敵に技を発動します。"
		Target.遠隔:
			range_text = "遠隔"
			range_tip = "場に出ているかどうかに関わらず敵に技を発動します。"
		Target.敵全体:
			range_text = "敵全体"
			range_tip = "敵全体に技を発動します。"
		Target.自分:
			range_text = "自分"
			range_tip = "自分に技を発動します。"
		Target.味方単体:
			range_text = "味方単体"
			range_tip = "味方単体に技を発動します。"
		Target.味方全体:
			range_text = "味方全体"
			range_tip = "味方全体に技を発動します。"
		Target.敵味方全体:
			range_text = "敵味方全体"
			range_tip = "敵味方全体に技を発動します。"
		_:
			range_text = "[color=red][b]ERROR[/b][/color]"
			range_tip = "虚空に向かって技を放つのか？"
	
	match act.damage_type:
		Action.DamageType.なし:	
			dmg_type_text = "なし"
			dmg_type_tip = "いずれのステータスも参照されません"
			dmg_type_blank = "　　"
		Action.DamageType.物理:
			dmg_type_text = "[color=red]物理[/color]"
			dmg_type_tip = "自身のATKと相手のDEFを参照します"
			dmg_type_blank = "　　"
		Action.DamageType.魔法:
			dmg_type_text = "[color=dodger_blue]魔法[/color]"
			dmg_type_tip = "自身のMAGと相手のRESを参照します"
			dmg_type_blank = "　　"
		_:
			dmg_type_text = "[color=red][b]ERROR[/b][/color]"
			dmg_type_tip = "一体どうやって技を放つんだ？"
	
	if blank == true and len(range_text) < 4: # 空白補完
		for i in 4 - len(range_text):
			range_blank += "　"
	
	range_text = "[hint=%s]対象:[color=yellow]%s[/color][/hint]" % [range_tip, range_text]
	dmg_type_text = "[hint=%s]分類:%s[/hint]" % [dmg_type_tip, dmg_type_text]
	
	if blank == true:
		dmg_type_text += dmg_type_blank
		range_text += range_blank
	
	return [dmg_type_text, range_text]

## 技の特殊能力のうち1つのindexを引数として、その特殊能力の説明文などをまとめて返す関数
func ability_description_creator(act: Action, index: int, blank: bool) -> Array:
	## 説明文をそれぞれ登録する配列
	## 0:特殊効果名 1:対象 2:確率 3:特殊効果の強さ 4:特殊効果のイメージ色
	var ability_text: String ## 特殊効果名
	var ability_tip: String ## 特殊効果名補足
	var ability_range_text: String ## 特殊効果の対象
	var ability_range_tip: String ## 特殊効果の対象の補足
	var ability_chance_text: String = \
	"[hint=特殊効果の発生確率]確率:[color=green]%3d%%[/color][/hint]" % act.ability_chance
	var ability_power: String ## 特殊効果の強さ
	var ability_color: Color ## 特殊効果のイメージ色
	match act.ability[index].category:
		1: # 状態異常
			ability_power = "状態異常継続ターン数:[color=red]%d[/color]" % \
			act.ability_power[index]
			match act.ability[index].ailment:
				1:
					ability_text = "[color=red]火傷[/color]"
					ability_tip = "相手を火傷状態にします"
					ability_color = Color.RED # red
				2:
					ability_text = "[color=dodger_blue]水圧[/color]"
					ability_tip = "相手を水圧状態にします"
					ability_color = Color.DODGER_BLUE # blue
				3:
					ability_text = "[color=yelllow]感電[/color]"
					ability_tip = "相手を感電状態にします"
					ability_color = Color.YELLOW
				4:
					ability_text = "[color=chocolate]泥々[/color]"
					ability_tip = "相手を泥々状態にします"
					ability_color = Color.CHOCOLATE
				5:
					ability_text = "[color=green]竜巻[/color]"
					ability_tip = "相手を竜巻状態にします"
					ability_color = Color.GREEN
				6:
					ability_text = "[color=turquoise]霜焼[/color]"
					ability_tip = "相手を霜焼状態にします"
					ability_color = Color.TURQUOISE
				7:
					ability_text = "[color=light_yellow]紫外線[/color]"
					ability_tip = "相手を紫外線状態にします"
					ability_color = Color.LIGHT_YELLOW
				8:
					ability_text = "[color=violet]呪い[/color]"
					ability_tip = "相手を呪い状態にします"
					ability_color = Color.PURPLE
		2: # バフ
			ability_power = "バフ継続ターン数:[color=red]%d[/color]" % \
			act.ability_power[index]
			ability_color = Color.DARK_RED
			match act.ability[index].buff:
				1:
					ability_text = "[color=red]ATK UP[/color]"
					ability_tip = "ATKを1.5倍に強化させます"
				2:
					ability_text = "[color=light_blue]DEF UP[/color]"
					ability_tip = "DEFを1.5倍に強化させます"
				3:
					ability_text = "[color=dodger_blue]MAG UP[/color]"
					ability_tip = "MAGを1.5倍に強化させます"
				4:
					ability_text = "[color=purple]RES UP[/color]"
					ability_tip = "RESを1.5倍に強化させます"
				5:
					ability_text = "[color=green]SPD UP[/color]"
					ability_tip = "SPDを???倍に強化させます"
				_:
					ability_text = "[color=red][b]ERROR[/b][/color]"
					ability_tip = "強化するものすら存在しなかった"
		3: # デバフ
			ability_power = "デバフ継続ターン数:[color=red]%d[/color]" % \
			act.ability_power[index]
			ability_color = Color.DARK_BLUE
			match act.ability[index].debuff:
				1:
					ability_text = "[color=red]ATK DOWN[/color]"
					ability_tip = "ATKを2/3倍に弱体化させます"
				2:
					ability_text = "[color=light_blue]DEF DOWN[/color]"
					ability_tip = "DEFを2/3倍に弱体化させます"
				3:
					ability_text = "[color=dodger_blue]MAG DOWN[/color]"
					ability_tip = "MAGを2/3倍に弱体化させます"
				4:
					ability_text = "[color=purple]RES DOWN[/color]"
					ability_tip = "RESを2/3倍に弱体化させます"
				5:
					ability_text = "[color=green]SPD DOWN[/color]"
					ability_tip = "SPDを???倍に弱体化させます"
				_:
					ability_text = "[color=red][b]ERROR[/b][/color]"
					ability_tip = "弱体化するものすら存在しなかった"
		4: # 回復 forest_green
			ability_color = Color.YELLOW_GREEN
			var status: String # 参照するステータス名
			match act.damage_type:
				1:
					status = "[color=red]ATK[/color]"
				2:
					status = "[color=dodger_blue]MAG[/color]"
			match act.ability[index].healing:
				1:
					ability_text = "[color=green]HP回復[/color]"
					ability_tip = "ステータスを参照してHPを回復させます"
					ability_power = "HP回復量:%sの[color=red]%d%%[/color]相当" % \
					[status, act.ability_power[index]]
				2:
					ability_text = "[color=green]定数HP回復[/color]"
					ability_tip = "一定の量だけHPを回復させます"
					ability_power = "HP回復量:[color=red]%d[/color]" % \
					act.ability_power[index]
				3:
					ability_text = "[color=aqua]MP回復[/color]"
					ability_tip = "ステータスを参照してMPを回復させます"
					ability_power = "未実装"
				4:
					ability_text = "[color=aqua定数MP回復[/color]"
					ability_tip = "一定の量だけMPを回復させます"
					ability_power = "MP回復量:[color=red]%d[/color]" % \
					act.ability_power[index]
				_:
					ability_text = "[color=red][b]ERROR[/b][/color]"
		5: # 吸収
			ability_power = "吸収率:[color=red]%d%%[/color]" % act.ability_power[index]
			ability_color = Color(1, 0.411765, 0.705882, 1) # hot_pink
			match act.ability[index].steal:
				1:
					ability_text = "[color=green]HP吸収[/color]"
					ability_tip = "与えたダメージに対して一定の割合でHPを回復させます"
				2:
					ability_text = "[color_aqua]MP吸収[/color]"
					ability_tip = "与えたダメージに対して一定の割合でMPを回復させます"
				3:
					ability_text = "[color=green]SPD吸収[/color]"
					ability_tip = "未実装"
	
	var blank_text: String = "" ## 空白
	match act.ability_range[index]:
		0: # rangeと同期
			match act.range:
				0:
					if blank == true:
						ability_range_text = "なし"
					else:
						ability_range_text = "　なし　"
					ability_range_tip = "発動対象が存在しません"
				1:
					if blank == true:
						ability_range_text = "敵単体"
					else:
						ability_range_text = " 敵単体 "
					ability_range_tip = "敵単体に効果を発動します"
				2:
					if blank == true:
						ability_range_text = "敵全体"
					else:
						ability_range_text = " 敵全体 "
					ability_range_tip = "敵全体に効果を発動します。"
				3:
					ability_range_text = "味方単体"
					ability_range_tip = "味方単体に効果を発動します。"
				4:
					ability_range_text = "味方全体"
					ability_range_tip = "味方全体に効果を発動します。"
				5:
					if blank == true:
						ability_range_text = "自分"
					else:
						ability_range_text = "　自分　"
					ability_range_tip = "自分に効果を発動します。"
				_:
					ability_range_text = "[color=red][b]ERROR[/b][/color]"
					ability_range_tip = "虚空に向かって効果を放つのか？"
		1:
			if blank == true:
				ability_range_text = "敵単体"
			else:
				ability_range_text = " 敵単体 "
			ability_range_tip = "敵単体に効果を発動します"
		2:
			if blank == true:
				ability_range_text = "敵全体"
			else:
				ability_range_text = " 敵全体 "
			ability_range_tip = "敵全体に効果を発動します。"
		3:
			ability_range_text = "味方単体"
			ability_range_tip = "味方単体に効果を発動します。"
		4:
			ability_range_text = "味方全体"
			ability_range_tip = "味方全体に効果を発動します。"
		5:
			if blank == true:
				ability_range_text = "自分"
			else:
				ability_range_text = "　自分　"
			ability_range_tip = "自分に効果を発動します。"
		_:
			ability_range_text = "[color=red][b]ERROR[/b][/color]"
			ability_range_tip = "虚空に向かって効果を発動するのか？"
	
	for i in 4 - len(ability_range_text):
		blank_text += "　"
	
	ability_text = "[hint=%s]%s[/hint]" % [ability_tip, ability_text] # tooltipを入れる
	ability_range_text = "[hint=%s]対象:[color=yellow]%s[/color][/hint]" % \
	[ability_range_tip, ability_range_text]
	
	return [ability_text, ability_range_text + blank_text, 
	ability_chance_text, ability_power, ability_color]

## 指定したコイン枚数だけ増減させ、自動でセーブする関数
func coin_setter(n: int) -> void:
	save_data.coin += n
	save_game()

# 暗号化及び複合化を行う関数 data:平文または暗号のデータ key:暗号化キー
func xor_encrypt(data: PackedByteArray, key: String) -> PackedByteArray:
	var result = PackedByteArray()
	var key_bytes = key.to_utf8_buffer()
	var key_len = key_bytes.size()
	for i in range(data.size()):
		result.append(data[i] ^ key_bytes[i % key_len])
	return result


func save_game() -> void:
	save_file(save_data.to_dictionary())


func load_game() -> void:
	var dict := load_file()
	# セーブデータが存在しない時、新規セーブデータ作成
	if dict == {}:
		save_data = SaveData.new()
		save_game()
		
		var scene = get_tree().current_scene
		if not scene:
			print("ERROR:シーンが存在しません")
			return
		
		AcceptDialogManager.display_dialog(
				"セーブデータが存在しません！\n新たなセーブデータを作成しました。", 
				"新規セーブデータ作成"
		)
	
	# 現在のバージョン以降のデータの場合、オートセーブを切り、既存データの上書きされるのを防ぐ
	elif (not is_version_older(dict["version"]) and 
	dict["version"] != 
	ProjectSettings.get_setting("application/config/version")):
		auto_save = false # オートセーブを切る
		save_data = SaveData.new()
		
		$AcceptDialog.title = "⚠️ERROR⚠️"
		$AcceptDialog.dialog_text = "現在のバージョン ver %s " % \
		ProjectSettings.get_setting("application/config/version") + \
		"\n以降に作成されたデータのため、ロードできません。\n\n仮のセーブデータをロードしました。" + \
		"\n現在のバージョンでもプレイ可能ですが、進行状況はセーブされません。" + \
		"\nまた、既存データの破損については一切の責任を負いません！"
		$AcceptDialog.popup_centered()
	# TODO 過去のバージョンのデータだった場合、互換性があるかチェックし、
	# データのバージョンを更新する処理を実装する必要あり。
	else:
		save_data = SaveData.from_dictionary(dict)

## ファイルをセーブする関数
func save_file(data: Dictionary, key: String = "I'm watching you") -> void:
	var path: String ## セーブデータファイルパス
	if VERSION_BETA == true:
		path = save_data_path_beta
	else:
		path = save_data_path

	var buffer := PackedByteArray()
	buffer = var_to_bytes(data)

	var encrypted := xor_encrypt(buffer, key)

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_buffer(encrypted)
		file.close()
	else:
		print("ERROR:セーブ先のファイルが存在しません")

## ファイルをロードしてセーブデータの辞書形式を返す関数
func load_file(key: String = "I'm watching you") -> Dictionary:
	var path: String ## セーブデータファイルパス
	if VERSION_BETA == true:
		path = save_data_path_beta
	else:
		path = save_data_path
	
	var result ## セーブデータの返り値
	if not FileAccess.file_exists(path):
		print("ALERT:セーブデータが存在しません\nALERT:新たにセーブデータを作成します")
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		print("ERROR:セーブファイルが開けません")
		return {}
	var encrypted := file.get_buffer(file.get_length())
	file.close()

	var decrypted := xor_encrypt(encrypted, key)

	result = bytes_to_var(decrypted)
	if typeof(result) != TYPE_DICTIONARY:
		print("ERROR:セーブデータが破損しています！")
		return {}
	
	result = cheat_check(result)
	return result

## チート検知
func cheat_check(result: Dictionary) -> Dictionary:
	return result


@onready var help_message = {"type":
"・属性相性によってダメージが増減し、以下の6すくみになっています。
　[img=40]res://image/element/火属性.PNG[/img][color=red]火属性[/color]は[img=40]res://image/element/氷属性.PNG[/img]\
[color=aqua]氷属性[/color]に強く、[img=40]res://image/element/氷属性.PNG[/img][color=aqua]氷属性[/color]は\
[img=40]res://image/element/風属性.PNG[/img][color=green]風属性[/color]に強く、
　[img=40]res://image/element/風属性.PNG[/img][color=green]風属性[/color]は[img=40]res://image/element/土属性.PNG[/img]\
[color=chocolate]土属性[/color]に強く、[img=40]res://image/element/土属性.PNG[/img][color=chocolate]土属性[/color]\
は[img=40]res://image/element/雷属性.PNG[/img][color=yellow]雷属性[/color]に強く、
　[img=40]res://image/element/雷属性.PNG[/img][color=yellow]雷属性[/color]は[img=40]res://image/element/水属性.PNG[/img]\
[color=dodger_blue]水属性[/color]に強く、[img=40]res://image/element/水属性.PNG[/img]\
[color=dodger_blue]水属性[/color]は[img=40]res://image/element/火属性.PNG[/img][color=red]火属性[/color]に強い

・この6すくみに加え、[img=40]res://image/element/光属性.PNG[/img][color=light_yellow]光属性[/color]と\
[img=40]res://image/element/闇属性.PNG[/img][color=purple]闇属性[/color]は
　互いに弱点をつくことができます。

・弱点をつくと[color=red]2倍[/color]のダメージを与えられますが、相手の属性と同じ属性で
　攻撃してしまうとダメージは[color=light_blue]0.5倍[/color]になってしまいます。

・[img=40]res://image/element/無属性.PNG[/img]無属性は汎用的な属性ではありますが、[img=40]res://image/element/無属性.PNG[/img]\
無属性以外の敵に
　与えるダメージは[color=light_blue]0.8倍[/color]になってしまいます。

・タイプ相性表
　[img=40]res://image/element/火属性.PNG[/img]←[img=40]res://image/element/水属性.PNG[/img]←[img=40]res://image/element/雷属性.PNG[/img]\
　[img=40]res://image/element/光属性.PNG[/img]
  ↓　　　  ↑　 ↕　>> [img=40]res://image/element/無属性.PNG[/img]
　[img=40]res://image/element/氷属性.PNG[/img]→[img=40]res://image/element/風属性.PNG[/img]→[img=40]res://image/element/土属性.PNG[/img]\
　[img=40]res://image/element/闇属性.PNG[/img]


ㅤ","status":"　[i]モンスターには大きく8つに分けられるステータスを持っています！[/i]\n
・[b][color=red]HP[/color][/b]:モンスターの体力で、0になると行動不能になります。
　ダメージを受けることで減少し、
　スキルや技の効果でHPが回復すると増加します。
　相手の全モンスターのHPを0にすることが勝利条件です。\n
・[color=aqua][b]MP[/b](supply/max)[/color]:一部の技を繰り出すのに必要な魔力です。
　そのモンスターが行動可能になった時、supplyの値だけ増加しますが、
　maxの値を越えて増加することはありません。
　また、バトル時にmaxの値の20%分のMPが溜まった状態でスタートします。\n
・[b][color=green]SPD[/color][/b]:1秒ごとにSPDの値だけSPDゲージが増加します。
　このゲージが100%まで溜まるとモンスターは行動可能になります。
　技そのものに対する命中率・回避率などは存在しません。\n
・[b][color=red]ATK[/color][/b]:物理攻撃で敵に与えるダメージに影響するステータスです。\n
・[b][color=light_blue]DEF[/color][/b]:相手の物理攻撃から受けるダメージに影響するステータスです。\n
・[b][color=blue]MAG[/color][/b]:魔法攻撃で敵に与えるダメージに影響するステータスです。\n
・[b][color=purple]RES[/color][/b]:相手の魔法攻撃から受けるダメージに影響するステータスです。\n

　[b][i]ダメージ計算式[/i][/b]
技の基礎威力 + (攻撃側のATKかMAG / 防御側のDEFかRES) ** 1.2 (小数点以下切り捨て)



"
}
