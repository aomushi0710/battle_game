extends TextureButton

@onready var turn_label := $turn
@onready var parent: BattleMonster = $"../.."

var effect: MonsterEffect

func _ready() -> void:
	turn_label.text = "[b][i]%d[/i][/b]" % effect.turn
	
	if effect.effect is AbilityEffect: # TODO 未定
		texture_normal = preload("res://image/null.PNG")
	elif effect.effect is AbilityBuff: # バフエフェクトの時
		texture_normal = preload("res://image/element/バフ技.PNG")
	elif effect.effect is AbilityDebuff: # デバフエフェクトの時
		texture_normal = preload("res://image/element/デバフ技.PNG")
	else: # いずれでもない時のエラー防止
		texture_normal = preload("res://image/null.PNG")
	
	# ターン数が更新された時のシグナルを受け取り、自動で表示ターン数を更新する。
	effect.set_turn.connect(func(): turn_label.text = "[b][i]%d[/i][/b]" % effect.turn)
	# ターン数が0になった時のシグナルを受け取り、自動で削除する。
	effect.delete.connect(func(): 
		parent.effect_list.erase(effect)
		queue_free())

## ボタンが押された時、エフェクト説明文を出す関数
func _on_button_up() -> void:
	AcceptDialogManager.display_dialog(effect.description, effect.effect.name)
