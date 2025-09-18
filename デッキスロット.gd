extends ColorRect

var slot: int # デッキスロット番号

var monster_data = Global.monster_data
var action_data = Global.action_data
var deck: Deck = Global.deck1

func _ready() -> void: # セーブ時かロード時かによってボタンを切り替える
	if Global.save_mode == true:
		$load.hide()
		$save.show()
	else:
		$save.hide()
		$load.show()


func setting(data: Dictionary) -> void: # デッキスロットUI上に各種データを表示する関数
	if data != {}:
		$Label.text = data["name"]
		$HBoxContainer/first.texture_normal = \
		monster_data[data["first"]["monster"]][0].image
		$HBoxContainer/second.texture_normal = \
		monster_data[data["second"]["monster"]][0].image
		$HBoxContainer/third.texture_normal = \
		monster_data[data["third"]["monster"]][0].image
		
		var icon = "　"
		# β版で正式リリース版、あるいはその逆のデータが保存されている場合
		# 現在のバージョン以降のデータの場合
		# βver4.4.0以下のデータの場合 ALERT β版のみ、正式版で削除
		if data["version"] is float:
			icon = "❌"
		# 型がfloatだとそもそも比較できないので分離
		elif (data["beta"] != Global.VERSION_BETA or
			(not Global.is_version_older(data["version"]) and 
			data["version"] != 
			ProjectSettings.get_setting("application/config/version"))):
			icon = "❌"
		
		# 現在のバージョン以前のデータの場合
		elif Global.is_version_older(data["version"]):
			icon = "⚠️"
		
		var beta = ""
		if data["beta"] == true: # ベータ版の時、(β)を表示
			beta = "(β)"
		
		$version.text = "%s[i]ver.%s%s[/i]" % [icon, data["version"], beta]
		$load.disabled = false
		$reset.disabled = false
	else:
		$Label.text = ""
		$HBoxContainer/first.texture_normal = load("res://1st.PNG")
		$HBoxContainer/second.texture_normal = load("res://2nd.PNG")
		$HBoxContainer/third.texture_normal = load("res://3rd.PNG")
		$version.text = ""
		$load.disabled = true
		$reset.disabled = true
