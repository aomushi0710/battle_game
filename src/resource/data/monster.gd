class_name Monster
extends Resource
## デッキ内に編成され、各種情報を持つモンスター。

@export var level: int = 1: ## モンスターのレベル。マイナスにはならない。
	set(value):
		if value < 1:
			level = 1
		else:
			level = value

## 登録されたモンスターのデータ。代入されると、[Monster action], [Monster chance],
## 各種ステータス([Monster maxHP], [Monster maxMP]...)も自動で代入される。
@export var data: MonsterData:
	set(value):
		data = value
		update()

## モンスターの現在の形態。代入されると、
##各種ステータス([Monster maxHP], [Monster maxMP]...)も自動で代入される。
@export var form: Global.Form = Global.Form.第一形態:
	set(value):
		form = value
		status_update()

@export var action: Array[Action] ## 登録された技[b]のみ[/b]が格納された配列
@export var chance: Array[int] ## [member Monster.action]で同じindexにあたる技の確率が格納された配列
#@export var skill: int = 0 ## スキルパターン

var maxHP: int ## HPの最大値。[b]現在のHPは別の変数で管理。[/b]
var maxMP: int ## MPの最大値、[b]現在のMPは別の変数で管理。[/b]
var supplyMP: int ## MP自動回復量。基本的に自身のSPDゲージが溜まった時に回復する。
var SPD: int ## SPDゲージの増加量。
var ATK: int ## 物理攻撃力。
var DEF: int ## 物理防御力。
var MAG: int ## 魔法攻撃力。
var RES: int ## 魔法防御力。

var HP: int ## HPの現在値
var MP: int ## MPの現在値

## モンスターの持つ技に付け加えて装備の持つ技なども一緒に、[member Monster.action]に格納する関数
func update() -> void:
	action = data.action
	# INFO 今後、装備の技などを更に追加する処理も記述する
	chance.resize(len(action))
	chance.fill(0)
	
	status_update()

## 現在のレベルと形態を基にステータスを算出し、自身の変数に代入する関数
func status_update() -> void:
	var status := data.evolution_forms[form].status_calculator(level)
	maxHP = status[0]
	maxMP = status[1]
	supplyMP = status[2]
	SPD = status[3]
	ATK = status[4]
	DEF = status[5]
	MAG = status[6]
	RES = status[7]

## 技の出現確率をランダムに登録する関数
func random_action_selector() -> void:
	chance.fill(0)
	
	## 出現確率の上限に達していない技の、[member Monster.action]におけるindex一覧
	var available_index: Array[int] = []
	for i in len(action):
		if level >= action[i].unlock_level:
			available_index.append(i)
	
	for i in range(100):
		var index = available_index.pick_random() ## 選ばれたindex
		chance[index] += 1
		# 技の出現確率上限に到達した時、候補から除外する
		if chance[index] >= action[index].data.max_chance:
			available_index.erase(index)

## 現在の形態固有のデータを持つ[MonsterForm]を取得します
func get_monsterform() -> MonsterForm:
	return data.evolution_forms[form]
