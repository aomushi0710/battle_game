extends "res://dialogtab.gd"

## チュートリアル用text_setter拡張、バトルログには全文が入る
func text_setter(data: BattlelogData) -> void:
	await super(data)
	for text in data.text:
		text_data[BattlelogData.Tab.BATTLE_LOG].text[0] += (
			text + "\n[color=gray]- - - - - - - - - - - - - - - - - - [/color]\n"
		)
