extends RichTextLabel

func _on_計算_button_up():
	var damage = float(
		float($技威力.value) * (float($ステータス1.value) / 
		float($ステータス2.value)) ** 1.2 * float($属性倍率.value))
	$".".text = "ダメージ計算機　結果：[color=red]" + str(int(damage)) + "[/color]ダメージ"
