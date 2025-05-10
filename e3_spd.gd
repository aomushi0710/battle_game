extends TextureProgressBar

@onready var buff_icon = $/root/Node2D/enemies/enemy3/e3_icon/バフアイコン
@onready var buff_turn = $/root/Node2D/enemies/enemy3/e3_icon/buff_turn
@onready var debuff_icon = $/root/Node2D/enemies/enemy3/e3_icon/デバフアイコン
@onready var debuff_turn = $/root/Node2D/enemies/enemy3/e3_icon/debuff_turn
@onready var buttle_script = get_node("/root/Node2D/buttle")

var index = 2 # deckクラス内におけるモンスターの位置
var monster_dict = Global.enemy_deck.monster_dict[index]
var monster: Monster = Global.enemy_deck.monster[index]
var effects = Global.enemy_deck.effect[index] # Dictionary{エフェクト名:ターン数}

signal mp
signal command

func _ready() -> void:
	$".".max_value = float(Global.spd_gauge)

func _process(delta): # ゲージが溜まるまで自動で増加、溜まると停止
	if $".".value < Global.spd_gauge: # SPDの値ずつ毎秒増加していき、500まで到達するとコマンドリストを表示
		$".".value += monster.SPD * Global.spd_correction * delta
		call("text_update")
	elif $".".value >= Global.spd_gauge:
		set_process(false)
		for button in $"../e3_command".get_children():
			button.disabled = false
		$/root/Node2D/log_window/log.text += monster.name + "が行動可能になった！\n"
		command.emit()
		mp.emit()

func text_update():
	$spd_text.text = " [color=green][b]SPD[/b]   %3d%%[/color]" % int($".".value / 100)

func _on_コマンド_spd(): # ターン経過処理
	for effect: Effect in effects.keys(): # ALERT forループによる要素の削除は予期しない動作を引き起こす可能性あり
		effects[effect] -= 1
		if effects[effect] == 0:
			effects.erase(effect)
	
	buttle_script.buff_icon(false,index)
	
	$".".value = 0 # ゲージリセット
	set_process(true)

func reload() -> void:
	monster = Global.enemy_deck.monster[index]
