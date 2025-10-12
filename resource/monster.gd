class_name Monster
extends Resource

enum Form { ## モンスターの形態
	第一形態, 
	第二形態, 
	第三形態, 
}

static var form_names = {} ## Formの値をkey、Formの定数名をvalueとする辞書

@export_category("モンスター")

@export var id: int ## モンスターのid
@export var name: String ## モンスターの名前

@export var form: Form ## モンスターの形態

@export var image: Texture ## モンスターの画像
@export var element: Array[Element] ## モンスターの属性 Element型[br]複数登録可能
@export var cost: int ## 進化に必要なmp


@export_category("ステータス")
@export var base_maxHP: int ## maxHPの基礎ステータス
@export var base_maxMP: int ## maxMPの基礎ステータス
@export var base_supplyMP: int ## supplyMPの基礎ステータス
@export var base_SPD: int ## SPDの基礎ステータス
@export var base_ATK: int ## ATKの基礎ステータス
@export var base_DEF: int ## DEFの基礎ステータス
@export var base_MAG: int ## MAGの基礎ステータス
@export var base_RES: int ## RESの基礎ステータス

var maxHP: int ## HPの最大値。現在のHPは別の変数で管理。
var maxMP: int ## MPの最大値、現在のMPは別の変数で管理。
var supplyMP: int ## MP自動回復量。基本的に自身のSPDゲージが溜まった時に回復する。
var SPD: int ## SPDゲージの増加量。
var ATK: int ## 物理攻撃力。
var DEF: int ## 物理防御力。
var MAG: int ## 魔法攻撃力。
var RES: int ## 魔法防御力。

var HP: int ## HPの現在値
var MP: int ## MPの現在値

@export_category("スキル")

@export_group("スキルパターン1")
## スキルパターン1:スキルの名前
@export var skill1_name: Array[String]
## スキルパターン1:スキルのID
@export var skill1_id: Array[int]

@export_group("スキルパターン2")
## スキルパターン2:スキルの名前
@export var skill2_name: Array[String]
## スキルパターン2:スキルのID
@export var skill2_id: Array[int]


@export_category("技")
## その形態で使用可能な技の配列
@export var actions: Array[Action]


@export_category("ドロップアイテム")

@export var coin: int ## モンスターが落とすコイン枚数


@export_category("説明")

@export_multiline var description: String ## モンスターの説明
@export_multiline var flavor_text: Array[String] ## モンスターのフレーバーテキスト一覧


static func _static_init() -> void:
	for key in Form:
		var value = Form[key]
		form_names[value] = key


func status_calculator(multiplier: float) -> void:
	maxHP = base_maxHP
	

## [param actions]に第二形態の技が入っていないにもかかわらず第三形態の技が入っているなど、
##間の進化形態をスキップしている場合に[code]true[/code]を返す関数
func is_evolution_skipped(actions: Array[Action]) -> bool:
	var evolution_forms = Global.monster_data[id]
	
	if len(evolution_forms) < 3: # 第三形態以上を持たないものはチェック不要
		return false
	else:
		for i in range(len(evolution_forms) - 1, 1, -1):
			if (Global.arrays_overlap(evolution_forms[i].actions, actions) and
			not Global.arrays_overlap(evolution_forms[i - 1].actions, actions)):
				return true
	
	return false

## [param action_array]に技を、[param chance_array]にその技の出現確率を、
##ランダムで登録する関数
func random_action_selector(action_array: Array[Action], 
chance_array: Array[int]) -> void:
	# 選択可能な技をactionsに複製
	var actions: Array[Action]
	for monster in Global.monster_data[id]: # 全ての形態でループ
		for action: Action in monster.actions:
			actions.append(action)
	
	var selected_actions: Array[Action] ## ランダムに選ばれた技
	
	while true: # ランダムな技4つを選ぶ
		actions.shuffle()
		selected_actions = actions.slice(0, 4)
		
		## [code]selected_actions[/code]の最大出現率の合計
		var total_max_chance = 0
		for action in selected_actions:
			total_max_chance += action.max_chance
		
		if total_max_chance >= 100 and not is_evolution_skipped(selected_actions):
			break
	
	# 候補となった技に対して、その技の最大出現率から振り分け可能な残り確率を算出し、
	# 残り確率が多い技ほど、選ばれやすい
	var chance: Dictionary = {} ## [code]key[/code]Action [code]value[/code]int
	for action in selected_actions:
		chance[action] = 0
	
	for i in range(100): # 100%分の確率を振り分ける
		var available_actions: Array[Action] = []
		var total_weight: int = 0 ## 全ての技の残り確率の合計
		for action in selected_actions:
			if action.max_chance - chance[action] > 0:
				available_actions.append(action)
				total_weight += action.max_chance - chance[action]
		
		var n = randi() % total_weight
		var action: Action
		for act in available_actions:
			var weight = act.max_chance - chance[act]
			if n < weight:
				action = act
				break
			n -= weight
		chance[action] += 1
	
	# 初期化して結果を格納する
	action_array.clear()
	chance_array.clear()
	for action in selected_actions:
		action_array.append(action)
		chance_array.append(chance[action])

## モンスターの全ステータスをまとめたリストを返す関数[br]
## [code][maxHP, maxMP, supplyMP, SPD, ATK, DEF, MAG, RES][/code]
func get_status_list() -> Array[int]:
	var status_list: Array[int] = [
		maxHP, 
		maxMP, 
		supplyMP, 
		SPD, 
		ATK, 
		DEF, 
		MAG, 
		RES
	]
	return status_list
