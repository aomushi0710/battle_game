extends TextureButton

var monster_dict # モンスターの全形態を格納する辞書
var monster: Monster # モンスターの現在の状態 INFO バトル中に更新される場合あり
var action_list: Array # 設定された技を格納する配列
var middle_evolution_list: Array # 設定された中間進化技を格納する配列
var evolution_list: Array # 設定された進化技を格納する配列
var chance_list: Array # 技の出現確率を格納する配列
var effect_dict # エフェクトの状態を格納する辞書　INFO 初期値はなし(空)

# バトル開始時セットアップ
func setup(dict: Dictionary, mon: Monster, act_list: Array, 
mid_evol_list: Array, evol_list: Array, chan_list: Array) -> void:
	# 引数から全て代入
	monster_dict = dict
	monster = mon
	action_list = act_list
	middle_evolution_list = mid_evol_list
	evolution_list = evol_list
	chance_list = chan_list
	# 初期値を設定
	monster.HP = monster.maxHP
	monster.MP = monster.maxMP / 5
	
	$HP.max_value = monster.maxHP
	$HP.value = monster.HP
	$HP/text.text = "HP %3d/%3d" % [monster.HP, monster.maxHP]
	
	$MP.max_value = monster.maxMP
	$MP.value = monster.MP
	
	$SPD.max_value = Global.spd_gauge
	$SPD.value = 0
	
	$name/element.selected(monster)
	$name/name.text = "[b][i]%s[/i][/b]" % monster.name
	self.texture_normal = monster.image
