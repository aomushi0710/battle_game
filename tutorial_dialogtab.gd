extends "res://dialogtab.gd"

## チュートリアル用text_setter拡張、バトルログには全文が入る
func text_setter(tab: int, wait: bool, text: Array) -> void:
	await super(tab, wait, text)
	for t in text:
		tab_list[2] += t + "\n- - - - - - - - - - - - - - - - - - "
