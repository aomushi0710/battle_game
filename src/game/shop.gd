extends Control

const item_scene = preload("res://scene/component/shop_item.tscn")
var coin_tween: Tween
var selected_item

func _ready() -> void:
	for i in range(1, len(Global.item_data) + 1): # 商品表示
		var shop_item = item_scene.instantiate()
		shop_item.item = Global.item_data[i]
		shop_item.button_up.connect(item_button_up)
		$"catalog/アイテム".add_child(shop_item)
	update(0)

## 所持コイン数やショップのラインナップを更新する関数
func update(paid: int) -> void:
	for shop_item in $"catalog/アイテム".get_children():
		shop_item.update()
	
	if selected_item == null: # 選ばれているアイテムがなければ
		$buy.disabled = true
		$dialog/margin/descriptions/description1/text.text = \
		"[center][b]アイテム名 Lv.0[/b][/center][font_size=20]\n\n[/font_size]" + \
		"[font_size=40]現在所持しているアイテムの\n能力が表示されます！[/font_size]"
		$dialog/margin/descriptions/description2/text.text = \
		"[center][b]アイテム名 Lv.0[/b][/center][font_size=20]\n\n[/font_size]" + \
		"[font_size=40]レベルアップ後の能力が\n表示されます！[/font_size]"
	else: # あれば続けて表示する
		item_button_up(selected_item)
	
	$coin.change(paid)

## アイテムが選ばれた時、説明文を表示する関数
func item_button_up(shop_item) -> void:
	# 現在選ばれたアイテム情報を記録
	selected_item = shop_item
	var item: Item = shop_item.item # ショップアイテムシーンに内蔵されているアイテム
	
	var level: int = item.get_level()
	var description: String
	$dialog/texture.texture = item.image
	if item.id not in Global.save_data.item: # 未所持の時
		$buy.disabled = false
		$dialog/margin/descriptions/description1/text.text = \
		"[center]未所持[/center]"
		description = item.get_description(level + 1)
		$dialog/margin/descriptions/description2/text.text = \
		"[center][b]%s Lv.%d[/b][/center]" % [item.name, level + 1] + \
		"[font_size=20]\n\n[/font_size][font_size=40]%s[/font_size]" % \
		description
	else:
		if level < item.max_level: # 所持しているが最大レベルでない時
			$buy.disabled = false
			description = item.get_description(level)
			$dialog/margin/descriptions/description1/text.text = \
			"[center][b]%s Lv.%d[/b][/center]" % [item.name, level] + \
			"[font_size=20]\n\n[/font_size][font_size=40]%s[/font_size]" % \
			description
			description = item.get_description(level + 1)
			$dialog/margin/descriptions/description2/text.text = \
			"[center][b]%s Lv.%d[/b][/center]" % [item.name, level + 1] + \
			"[font_size=20]\n\n[/font_size][font_size=40]%s[/font_size]" % \
			description
		else: # 最大レベルに達している時
			$buy.disabled = true
			description = item.get_description(item.max_level)
			$dialog/margin/descriptions/description1/text.text = \
			"[center][b]%s Lv.%d[/b][/center]" % [item.name, item.max_level] + \
			"[font_size=20]\n\n[/font_size][font_size=40]%s[/font_size]" % \
			description
			$dialog/margin/descriptions/description2/text.text = \
			"[center]レベル上限に達しています！[/center]"


func _on_戻る_button_up() -> void:
	get_tree().change_scene_to_file(Global.map_scene)

## 持ち物一覧を開く
func _on_inventory_button_up() -> void:
	add_child(Global.inventory_scene.instantiate())


func _on_buy_button_up() -> void:
	if Global.save_data.coin < selected_item.price: # コインがたりない
		Global.accept_dialog.display_dialog(
			"コインが足りません！\nバトルでコインを集めましょう！", "コイン不足")
	else:
		Global.confirmation_dialog.on_confirm_callable = self._on_confirmed
		Global.confirmation_dialog.display_dialog(
				"%s Lv.%dを購入しますか？" % 
				[selected_item.name, selected_item.level], 
				"購入確認"
		)


## 購入確認ボタンで購入ボタンを押した時
func _on_confirmed() -> void:
	# アイテム情報もセーブするので、ここではセーブしない
	Global.save_data.coin -= selected_item.price
	
	if selected_item.item.id not in Global.save_data.item: # 未所持の時
		Global.save_data.item[selected_item.item.id] = 1
	else:
		Global.save_data.item[selected_item.item.id] += 1
	
	SaveManager.save_game()
	
	Global.accept_dialog.display_dialog(
			"%s Lv.%dを手に入れた！" % [selected_item.name, selected_item.level], 
			"購入完了"
	)
	
	update(-selected_item.price)
	
