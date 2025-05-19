extends Node2D

# バージョン管理 定数
const VERSION_TEXT: String = "ver 3.1.2(β)" # バージョン
const VERSION: float = 3.1 # 比較可能バージョン セーブデータ整合性チェック用
const VERSION_BETA: bool = true # true:ベータ版 false:正式リリース版

var monster_data = {}
var action_data = {}

func _ready() -> void:
	var dir = DirAccess.open("res://action/") # actionディレクトリを開く
	if dir:
		dir.list_dir_begin() # ループ初期化
		var file := dir.get_next() # 最初のリソース取得
		
		while file != "": # リソースがなくなるまで繰り返す
			var resource = load("res://action/" + file)
			action_data[resource.id] = resource # リソースのID通りのkeyで辞書に登録
			print("ロード完了:" + resource.name + " ID:" + str(resource.id))
			file = dir.get_next() # 次のリソース取得
		dir.list_dir_end() # ループ終了
	else:
		print("ERROR:ディレクトリ「action」が存在しません")
	
	dir = DirAccess.open("res://monster/")
	if dir:
		dir.list_dir_begin()
		var file := dir.get_next() # 最初のリソース取得
		
		while file != "": # リソースがなくなるまで繰り返す
			var resource = load("res://monster/" + file)
			if resource.id not in monster_data: # 辞書内の辞書が存在しない場合
				monster_data[resource.id] = {} # モンスターIDごとに辞書生成
			monster_data[resource.id][resource.form] = resource # モンスターIDと形態がkey
			print("ロード完了:" + resource.name)
			file = dir.get_next()
		dir.list_dir_end()
	else:
		print("ERROR:ディレクトリ「monster」が存在しません")

var main_scene = load("res://メインシーン.tscn")
var deck_scene = load("res://デッキセレクト.tscn")
var chara_scene = load("res://キャラ選択.tscn")
var select_scene = load("res://特性・技セレクト.tscn")
var buttle_scene = load("res://バトル.tscn")
var debug_scene = load("res://debug.tscn")
var deck_save_scene = load("res://デッキセーブデータ.tscn")

@onready var picked_monster = [0,0,0] #モンスター
@onready var deck1 = Deck.new()
@onready var enemy_deck = Deck.new()
@onready var target = 3 # 現在攻撃対象に選択中のモンスターの位置(0~2:指定indexのモンスターを攻撃 3:未選択)
@onready var support_target = 3 # 味方から技を受ける場合の位置(0~2:指定indexのモンスターを攻撃 3:未選択)

@onready var now_picking = 3 #現在選択中のモンスターの位置　3：未選択 0～2：選択中
@onready var selected_monster = 0 #現在選択中のモンスターID(特性・技セレクトで使用)
@onready var strategy = 0

@onready var deck_name: String
@onready var save_mode := true # true:デッキセーブ時 false:デッキロード時

const spd_gauge = 10000
const spd_correction = 30 # spdゲージ増加量補正 SPD * spd_correction
const buff_list = ["ATK_up","DEF_up","MAG_up","RES_up"]
const debuff_list = ["ATK_down","DEF_down","MAG_down","RES_down"]

@onready var p1_death = false # 死亡フラグ false:生存 true:死亡
@onready var p2_death = false
@onready var p3_death = false
@onready var e1_death = false # 敵
@onready var e2_death = false
@onready var e3_death = false

 # モンスターのステータス表示を生成する関数 icon_size:bbcodeのimgタグに用いるアイコンのサイズ
func status_text(monster: Monster, icon_size: int) -> String:
	var element_text = ""
	for element: Element in monster.element:
		element_text += "[img=%d]" % icon_size + element.icon.resource_path + "[/img]" + \
		" [color=" + element.color + "]" + element.name + "[/color]\n"
	
	var text = (
		"[center][b][i]" + monster.name + "[/i][/b][/center]\n\n" + 
		element_text + "\n[color=coral]HP :%3d" %
		monster.maxHP + "[/color] [color=green]SPD:%3d" % monster.SPD + 
		"[/color]\n[color=aqua]MP :%3d" % monster.supplyMP + "  /  %3d" % 
		monster.maxMP + "\n (supply / max)[/color]\n[color=red]ATK:%3d" % 
		monster.ATK + "[/color] [color=light_blue]DEF:%3d" % 
		monster.DEF + "[/color]\n[color=dodger_blue]MAG:%3d" % 
		monster.MAG + "[/color] [color=violet]RES:%3d" % 
		monster.RES + "[/color]\n\n")
	return text

func deck_creator(deck: Deck) -> void:
	var monster_id_list: Array[int] = [0] # 選ばれたモンスターのIDを登録と0だけ
	var monster_id: int = 0
	for i in range(3): # 全モンスターからランダムに選ぶ。iは0-2が入りモンスターの位置を表す。
		# Global.enemy_deck[i]["id"] は敵モンスター[i]枠目のモンスターidが入ります
		while monster_id in monster_id_list: # 被りがでなくなるまで繰り返す
			monster_id = randi() % (len(monster_data) - 1) + 1
		monster_id_list.append(monster_id)
		
		deck.monster_dict[i] = monster_data[monster_id]
		deck.monster[i] = deck.monster_dict[i][0].duplicate() # 第一形態を登録
		#deck.skill[i] = randi() % 2 # スキルパターンindexを0or1に設定
		
		# 選択可能な技をactionsに複製
		var actions: Array[Action]
		for form in deck.monster_dict[i]: # 全ての形態でループ
			for action: Action in deck.monster_dict[i][form].actions:
				actions.append(action)
		
		var sum_chance = 0
		while sum_chance < 100: # 合計出現率が100%になるまでモンスターの持つ全技からランダムに選ぶ。
			deck.action[i] = []
			deck.chance[i] = []
			sum_chance = 0
			var copy = actions.duplicate()
			for act_index in range(4):
				if sum_chance != 100: # 既に100%ならスキップ
					# n には全ての選択可能な技のindexが入ります
					var n = randi() % len(copy)
					# action_id にはnに入ったindexの位置の技idが入ります
					var action: Action = copy.pop_at(n)
					var chance = 0
					if act_index == 3: # 4つ目の技を設定する時は、ちょうど100%になるように調整される。
						if action.max_chance >= 100 - sum_chance: # ただし、max_chanceには従う
							chance = 100 - sum_chance
						else:
							break
					else:
						# chance にはactionに入った技の出現率が入ります。
						# もし残りの%よりもmax_chanceが大きければ、100%を超過しないようにする。
						if 100 - sum_chance >= action.max_chance:
							chance = randi() % (action.max_chance) + 1 # 1~max_chanceの値が入る
						else:
							chance = randi() % (100 - sum_chance) + 1
					deck.action[i].insert(act_index, action)
					deck.chance[i].insert(act_index, chance)
					sum_chance += chance
		
	deck.evolution_check(deck)

@onready var help_message = {"type":
"・属性相性によってダメージが増減し、以下の6すくみになっています。
　[img=40]res://火属性.PNG[/img][color=red]火属性[/color]は[img=40]res://氷属性.PNG[/img]\
[color=aqua]氷属性[/color]に強く、[img=40]res://氷属性.PNG[/img][color=aqua]氷属性[/color]は\
[img=40]res://風属性.PNG[/img][color=green]風属性[/color]に強く、
　[img=40]res://風属性.PNG[/img][color=green]風属性[/color]は[img=40]res://土属性.PNG[/img]\
[color=chocolate]土属性[/color]に強く、[img=40]res://土属性.PNG[/img][color=chocolate]土属性[/color]\
は[img=40]res://雷属性.PNG[/img][color=yellow]雷属性[/color]に強く、
　[img=40]res://雷属性.PNG[/img][color=yellow]雷属性[/color]は[img=40]res://水属性.PNG[/img]\
[color=dodger_blue]水属性[/color]に強く、[img=40]res://水属性.PNG[/img]\
[color=dodger_blue]水属性[/color]は[img=40]res://火属性.PNG[/img][color=red]火属性[/color]に強い

・この6すくみに加え、[img=40]res://光属性.PNG[/img][color=light_yellow]光属性[/color]と\
[img=40]res://闇属性.PNG[/img][color=purple]闇属性[/color]は
　互いに弱点をつくことができます。

・弱点をつくと[color=red]2倍[/color]のダメージを与えられますが、相手の属性と同じ属性で
　攻撃してしまうとダメージは[color=light_blue]0.5倍[/color]になってしまいます。

・[img=40]res://無属性.PNG[/img]無属性は汎用的な属性ではありますが、[img=40]res://無属性.PNG[/img]\
無属性以外の敵に
　与えるダメージは[color=light_blue]0.8倍[/color]になってしまいます。

・タイプ相性表
　[img=40]res://火属性.PNG[/img]←[img=40]res://水属性.PNG[/img]←[img=40]res://雷属性.PNG[/img]\
　[img=40]res://光属性.PNG[/img]
  ↓　　　  ↑　 ↕　>> [img=40]res://無属性.PNG[/img]
　[img=40]res://氷属性.PNG[/img]→[img=40]res://風属性.PNG[/img]→[img=40]res://土属性.PNG[/img]\
　[img=40]res://闇属性.PNG[/img]


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

　[b][i]ダメージ計算式[/b][/i]
技の基礎威力 + (攻撃側のATKかMAG / 防御側のDEFかRES) ** 1.2 (小数点以下切り捨て)


"
}
