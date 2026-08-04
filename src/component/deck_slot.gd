class_name DeckSlot
extends ColorRect

@export var save_button: Button
@export var load_button: Button
@export var reset_button: Button
@export var deck_slot_label: RichTextLabel
@export var deck_name_label: Label
@export var version_label: RichTextLabel
@export var monster_icon_1: MonsterIcon
@export var monster_icon_2: MonsterIcon
@export var monster_icon_3: MonsterIcon

var slot: int ## デッキスロット番号

func _ready() -> void: # セーブ時かロード時かによってボタンを切り替える
	if slot == 0:
		return
	
	if Global.save_mode == true:
		load_button.hide()
		save_button.show()
	else:
		save_button.hide()
		load_button.show()

## デッキスロットUI上に各種データを表示する関数
## TODO 第二形態・第三形態の見た目でもプレビューできるようにする
func setting(data: Dictionary) -> void:
	if data != {}:
		deck_name_label.text = data["name"]
		monster_icon_1.data = Global.monster_data[data["first"]["id"]]
		monster_icon_2.data = Global.monster_data[data["second"]["id"]]
		monster_icon_3.data = Global.monster_data[data["third"]["id"]]
		
		var icon = "　"
		# β版で正式リリース版、あるいはその逆のデータが保存されている場合
		# 現在のバージョン以降のデータの場合
		# βver4.4.0以下のデータの場合 ALERT β版のみ、正式版で削除
		if data["version"] is float:
			icon = "❌"
		# 型がfloatだとそもそも比較できないので分離
		elif (
			data["beta"] != Global.VERSION_BETA or
			(not Global.is_version_older(data["version"]) and 
			data["version"] != Global.version)
		):
			icon = "❌"
		
		# 現在のバージョン以前のデータの場合
		elif Global.is_version_older(data["version"]):
			icon = "⚠️"
		
		var beta = ""
		if data["beta"] == true: # ベータ版の時、(β)を表示
			beta = "(β)"
		
		version_label.text = "%s[i]ver.%s%s[/i]" % [icon, data["version"], beta]
		load_button.disabled = false
		reset_button.disabled = false
	else:
		deck_name_label.text = ""
		monster_icon_1.data = null
		monster_icon_2.data = null
		monster_icon_3.data = null
		version_label.text = ""
		load_button.disabled = true
		reset_button.disabled = true
