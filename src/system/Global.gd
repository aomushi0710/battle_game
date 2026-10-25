extends Node2D

## 現在のバージョン
var version: String = ProjectSettings.get_setting("application/config/version")
## 現在のバージョンがβ版であるかどうか
const IS_BETA: bool = true

const MAIN_SCENE: String = "res://scene/new_main.tscn"
const MAP_SCENE: String = "res://scene/game_scene/map.tscn"
const SELECT_SCENE: String = "res://scene/game_scene/monster_setting.tscn"
const BATTLE_SCENE: String = "res://scene/game_scene/battle.tscn"
const DECK_SAVE_SCENE: String = "res://scene/game_scene/deck_select.tscn"
const TUTORIAL_SCENE: String = "res://scene/game_scene/tutorial.tscn"
const SHOP_SCENE: String = "res://scene/game_scene/shop.tscn"

const DEBUG_SCENE: String = "res://scene/debug/debug.tscn"

const GAME_BUTTON: PackedScene = preload("res://scene/component/game_button.tscn")
const MONSTER_ICON: PackedScene = preload("res://scene/component/monster_icon.tscn")
const ACTION_BUTTON: PackedScene = preload("res://scene/component/action_button.tscn")
const ACTION_SETTING_BUTTON: PackedScene = preload("res://scene/component/action_setting_button.tscn")
const ABILITY_DESCRIPTION: PackedScene = preload("res://scene/component/ability_description.tscn")
const DAMAGE_TEXT: PackedScene = preload("res://scene/component/damage_text.tscn")

## [MonsterData]のリソースを格納した辞書
## 各形態の情報は[member MonsterData.evolution_forms]を参照すること。
var monster_data: Dictionary[int, MonsterData] = {}
## [ActionData]のリソースを格納した辞書
var action_data: Dictionary[int, ActionData] = {}
## [Item]のリソースを格納した辞書
var item_data: Dictionary[int, Item] = {}
## [Stage]のリソースを格納した辞書
var stage_data: Dictionary[int, Stage] = {}

var is_first_launch: bool = true ## 初回起動によるタイトル画面の呼び出しかどうか

@onready var player_deck := Deck.new()
@onready var enemy_deck := Deck.new()
## プレイヤーのデッキではなく、別のデッキを用いてバトルを行う必要がある時、プレイヤーのデッキを一時的に格納しておく変数
@onready var current_deck := Deck.new()

@onready var p1_death := false ## 死亡フラグ false:生存 true:死亡
@onready var p2_death := false
@onready var p3_death := false
@onready var e1_death := false # 敵
@onready var e2_death := false
@onready var e3_death := false

@onready var battle_stage: Stage ## バトルステージ


func _ready() -> void:
	_directory_load("res://resource/monster_data/", monster_data)
	_directory_load("res://resource/action_data/", action_data)
	_directory_load("res://resource/item/", item_data)
	_directory_load("res://resource/stage/", stage_data)

## ディレクトリのパス[param path]を指定して読み込み、[param dict]にIDをキーとしてリソースを格納します。
func _directory_load(path: String, dict: Dictionary) -> void:
	var dir := DirAccess.open(path)
	if dir:
		print("ディレクトリ「%s」のロードを開始..." % path)
		dir.list_dir_begin()
		var file_name: String = dir.get_next() ## ファイル名
		
		while file_name != "":
			if file_name == "." or file_name == "..":
				file_name = dir.get_next()
				continue
			
			var full_path: String = path.path_join(file_name) ## rootからのファイルパス
			if dir.current_is_dir():
				_directory_load(full_path, dict)
			else:
				var resource: Resource = load(full_path)
				if resource:
					dict[resource.id] = resource
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
		print("ディレクトリ「%s」のロードが完了。" % path)
	else:
		print("ERROR:ディレクトリ「%s」が存在しません" % path)

## BBcodeのタグ[]を含む[param text]を平文に戻して返します
func strip_bbcode(text: String) -> String:
	var regex := RegEx.new()
	regex.compile("\\[.*?\\]")
	return regex.sub(text, "", true)

## 2つの[Array]を比較し、共通する要素が見つかれば[code]true[/code]を返します
func arrays_overlap(array1: Array, array2: Array) -> bool:
	if array1.is_empty() or array2.is_empty():
		return false
	
	for item: Variant in array1:
		if array2.has(item):
			return true
	return false

## 重みづけ抽選を行う関数。重みづけテーブルを引数として、抽選された結果のindexを返します。
## [br][b]アイテムテーブルと重みづけテーブルの要素数は必ず一致させてください。[/b]
func get_weighted_random(weight: Array[int]) -> int:
	var total_weight: int = 0
	for w in weight:
		total_weight += w
	
	var random: int = randi() % total_weight
	
	var current_weight: int = 0
	for i in weight.size():
		current_weight += weight[i]
		if random < current_weight:
			return i
	
	return -1

## Array[lb][Action][rb]型をArray[lb][ActionData][rb]型に変換します
func action_to_actiondata(actions: Array[Action]) -> Array[ActionData]:
	var result: Array[ActionData]
	for act in actions:
		result.append(act.data)
	return result

## 比較基となるバージョン[param version1]と比較先となるバージョン[param version2]を、引数として入力し、[param version1]の方が古い場合は[code]true[/code]、[br]
## [param version1]の方が新しい、または同一バージョンの場合は[code]false[/code]を返します
## [br][param version2]の引数を指定しなかった場合、現在のバージョンと比較されます
func is_version_older(version1: String, version2: String = Global.version) -> bool:
	var string_array1 := version1.split(".") ## version1(比較元)を分割した配列
	var string_array2 := version2.split(".") ## version2(比較先)を分割した配列
	
	var int_array1 := PackedInt32Array([
		string_array1[0].to_int(),
		string_array1[1].to_int(),
		string_array1[2].to_int()
	])
	var int_array2 := PackedInt32Array([
		string_array2[0].to_int(),
		string_array2[1].to_int(),
		string_array2[2].to_int()
	])
	
	for i in range(3): # メジャー、マイナー、パッチの順に比較
		var int1: int = int_array1[i]
		var int2: int = int_array2[i]
		
		if int1 < int2:
			return true
		elif int1 > int2:
			return false
		
	return false

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
	
	return [ability_text, ability_range_text + blank_text, ability_chance_text, ability_power, ability_color]
