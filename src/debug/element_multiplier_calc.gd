extends RichTextLabel

func attribute_setup(off_type_main,off_type_sub,def_type_main,def_type_sub):
	var ma = float(1.0) # 初期化処理   off_type:攻撃側タイプ def_type:防御側タイプ
	if off_type_sub == -1 and def_type_sub == -1: # -1:該当なし
		ma *= attribute(off_type_main,def_type_main)
	elif off_type_sub != -1 and def_type_sub == -1: # 攻撃側が複合タイプ攻撃
		ma *= attribute(off_type_main,def_type_main)
		ma *= attribute(off_type_sub,def_type_main)
	elif off_type_sub == -1 and def_type_sub != -1: # 防御側が複合タイプ持ち
		ma *= attribute(off_type_main,def_type_main)
		ma *= attribute(off_type_main,def_type_sub)
	elif off_type_sub != -1 and def_type_sub != -1: # どちらも複合タイプ持ち
		ma *= attribute(off_type_main,def_type_main)
		ma *= attribute(off_type_sub,def_type_main)
		ma *= attribute(off_type_main,def_type_sub)
		ma *= attribute(off_type_sub,def_type_sub)
	return ma
	
func attribute(o,d):
	if ( # 0:無 1:火 2:水 3:雷 4:土 5:風 6:氷 7:光 8:闇
			(o == 2 and d == 1) or (o == 3 and d == 2) or (o == 4 and d == 3) or 
			(o == 5 and d == 4) or (o == 6 and d == 5) or (o == 1 and d == 6) or 
			(o == 7 and d == 8) or (o == 8 and d == 7)):
		return 2.0 # 弱点を突いたときダメージ2倍
	elif o == d and o != 0:
		return 0.5 # 同じ属性の技を受けた時ダメージ0.5倍
	elif o == 0 and d != 0:
		return 0.8 # 無属性でない敵に無属性の技で攻撃する際の軽減倍率0.8倍
	else:
		return 1.0 # その他等倍

func _on_計算_button_up():
	var result = attribute_setup($技タイプ1.value,$技タイプ2.value,$防御側タイプ1.value,$防御側タイプ2.value)
	if ($技タイプ1.value != -1 and $攻撃側タイプ1.value == $技タイプ1.value or 
		$技タイプ2.value != -1 and $攻撃側タイプ1.value == $技タイプ2.value or 
		$技タイプ1.value != -1 and $攻撃側タイプ2.value == $技タイプ1.value or 
		$技タイプ2.value != -1 and $攻撃側タイプ2.value == $技タイプ2.value):
		result *= 1.5
		$".".text = "属性倍率計算機　結果：[color=red]" + str(result) + "[/color]倍 [b]属性一致補正込み"
	else:
		$".".text = "属性倍率計算機　結果：[color=red]" + str(result) + "[/color]倍"


func _on_終了_button_up():
	get_tree().change_scene_to_file(Global.main_scene)
