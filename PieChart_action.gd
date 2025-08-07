extends Control

@onready var action1: TextureProgressBar = $action1
@onready var action2: TextureProgressBar = $action2
@onready var action3: TextureProgressBar = $action3
@onready var action4: TextureProgressBar = $action4
@onready var nodes: Array[TextureProgressBar] = [action1, action2, action3, action4]

var actions: Array[Action]
var chances: Array[int]

## 現在の技とその出現確率から、円グラフを生成する関数
func update() -> void:
	var color_list: Array[Color] ## これまでの色の履歴を保持
	var sum_chance: int = 0 ## それまでの合計の確率
	
	for i in len(actions):
		if actions[i] == null:
			nodes[i].tint_progress = Color.TRANSPARENT
			continue
		## 被らないようにcolor_checker関数を通してから、使用する色を取得
		## (複数属性あるものも、とりあえず1つ目の属性のみにする)
		var color: Color = color_checker(color_list, actions[i].element[0].color)
		sum_chance += chances[i]
		
		nodes[i].tint_progress = color # 色設定
		nodes[i].value = sum_chance # 数値設定
		
		color_list.append(color) # 使用済みの色を登録
		if sum_chance >= 100: # もし既に100%を越えていたら
			break

## 既に使用された色のリストcolor_listと、追加したい色colorを引数とする。
## color_listの中に、colorと重複する色が含まれていた場合に、色をずらして返す関数
func color_checker(color_list: Array[Color], color: Color) -> Color:
	for c: Color in color_list:
		if color.is_equal_approx(c): # もし色が一緒なら少し色をずらす
			color.v -= 0.15
			if color.v < 0: # オーバーフロー防止
				color.v += 1
	return color
