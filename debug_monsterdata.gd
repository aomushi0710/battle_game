extends ColorRect

var id = 0
var default = null # 未進化
var middle_evolution = null
var evolution = null

func _ready():
	$id.value = 1

func _on_spin_box_value_changed(value: int):
	var monster_dict = Global.monster_data[value]
	default = monster_dict[0]
	id = value
	if len(monster_dict) == 3: # 2回進化モンスター
		middle_evolution = monster_dict[1] # データ取得
		evolution = monster_dict[2]
		$evolution.texture_normal = evolution.image # 画像取得
		$middle_evolution.texture_normal = middle_evolution.image
		$default.texture_normal = default.image
		$evolution.show()
		$middle_evolution.show()
	elif len(monster_dict) == 2: # 1回進化モンスター
		evolution = monster_dict[2]
		$evolution.texture_normal = evolution.image # 画像取得
		$default.texture_normal = default.image
		$evolution.show()
		$middle_evolution.hide()
	elif len(monster_dict) == 1: # 進化なしモンスター
		$default.texture_normal = default.image
		$evolution.hide()
		$middle_evolution.hide()
	else:
		$data.text = "ERROR:monsterの持つ子ノードが多すぎます"
		return
	
	$data.text = "名前　:　モンスターの名前\n形態　:　第1形態とか第2形態とか\
	\n属性　:　属性と属性id\nコスト:　この形態になるのに必要なコスト"
	
	$status.text = "ステータス\n\n[color=coral]HP :---[/color]" + \
	" [color=green]SPD:---[/color]\n[color=aqua]MP :---  /  ---\n" + \
	"(supply / max)[/color]\n[color=red]ATK:---[/color] " + \
	"[color=light_blue]DEF:---[/color]\n[color=dodger_blue]MAG:---[/color] " + \
	"[color=violet]RES:---[/color]"
	
	$skill.text = "スキル\n\n・パターン1\nスキル名1 id\nスキル名2 id\n\n" + \
	"・パターン2\nスキル名1 id\nスキル名2 id"
	
	$action.text = "技一覧"


func _on_default_button_up():
	call("text",default,"第1形態")

func _on_middle_evolution_button_up():
	call("text",middle_evolution,"第2形態")

func _on_evolution_button_up():
	call("text",evolution,"[color=red]最終形態[/color]")

func text(monster: Monster, form: String) -> void:
	var element_text: String = ""
	for element: Element in monster.element:
		element_text += "属性　:　[img=30]%s[/img] " % element.icon.resource_path + \
		"[color=%s]" % element.color + "%s[/color]\n" % element.name
	
	$data.text = ("名前　:　%s\n形態　:　%s\n%sコスト:　%d" % 
	[monster.name, form, element_text, monster.cost])
	
	$status.text = ("ステータス\n\n[color=red]HP :%3d" %
		monster.maxHP + "[/color] [color=green]SPD:%3d" % monster.SPD + 
		"[/color]\n[color=aqua]MP :%3d" % monster.supplyMP + "  /  %3d" % 
		monster.maxMP + "\n (supply / max)[/color]\n[color=red]ATK:%3d" % 
		monster.ATK + "[/color] [color=light_blue]DEF:%3d" % 
		monster.DEF + "[/color]\n[color=dodger_blue]MAG:%3d" % 
		monster.MAG + "[/color] [color=violet]RES:%3d" % 
		monster.RES + "[/color]")
	
	var skill1_text = ""
	var skill2_text = ""
	if monster.skill1_name.is_empty() == true:
		skill1_text = "なし\n"
	else:
		for i in len(monster.skill1_name):
			skill1_text += monster.skill1_name[i] + " id:" + str(monster.skill1_id[i]) + "\n"
	if monster.skill2_name.is_empty() == true:
		skill2_text = "なし\n"
	else:
		for i in len(monster.skill1_name):
			skill2_text += monster.skill2_name[i] + " id:" + str(monster.skill2_id[i]) + "\n"
	
	$skill.text = "スキル\n\n・パターン1\n" + skill1_text + "\n・パターン2\n" + skill2_text
	
	$action.text = "技一覧\n"
	for action: Action in monster.actions:
		$action.text += ("\n[img=30]%s[/img] %s" % 
		[action.element[0].icon.resource_path, action.name])
