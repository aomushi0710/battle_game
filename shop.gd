extends Control

const item_scene = preload("res://shop_item.tscn")
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
		"[center][b]アイテム名 Lv.0[/b][/center]\n\n現在所持しているアイテムの\n能力が表示されます！"
		$dialog/margin/descriptions/description2/text.text = \
		"[center][b]アイテム名 Lv.0[/b][/center]\n\nレベルアップ後の能力が\n表示されます！"
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
	if item.id not in Global.inv.item: # 未所持の時
		$buy.disabled = false
		$dialog/margin/descriptions/description1/text.text = "[center]未所持[/center]"
		description = item.get_description(level + 1)
		$dialog/margin/descriptions/description2/text.text = \
		"[center][b]%s Lv.%d[/b][/center]\n\n%s" % [item.name, level + 1, description]
	else:
		if level < item.max_level: # 所持しているが最大レベルでない時
			$buy.disabled = false
			description = item.get_description(level)
			$dialog/margin/descriptions/description1/text.text = \
			"[center][b]%s Lv.%d[/b][/center]\n\n%s" % [item.name, level, description]
			description = item.get_description(level + 1)
			$dialog/margin/descriptions/description2/text.text = \
			"[center][b]%s Lv.%d[/b][/center]\n\n%s" % [item.name, level + 1, description]
		else: # 最大レベルに達している時
			$buy.disabled = true
			description = item.get_description(item.max_level)
			$dialog/margin/descriptions/description1/text.text = \
			"[center][b]%s Lv.%d[/b][/center]\n\n%s" % [item.name, item.max_level, description]
			$dialog/margin/descriptions/description2/text.text = \
			"[center]レベル上限に達しています！[/center]"


func _on_戻る_button_up() -> void:
	get_tree().change_scene_to_file(Global.deck_scene)

## 持ち物一覧を開く
func _on_inventory_button_up() -> void:
	add_child(Global.inventory_scene.instantiate())


func _on_buy_button_up() -> void:
	if Global.coin < selected_item.price: # コインがたりない
		$error_message.title = "コイン不足"
		$error_message.dialog_text = "コインが足りません！"
		$error_message.popup_centered()
	else:
		$confirm_message.title = "購入確認"
		$confirm_message.dialog_text = "%s Lv.%dを購入しますか？" % \
		[selected_item.name, selected_item.level]
		$confirm_message.ok_button_text = "購入！"
		$confirm_message.cancel_button_text = "キャンセル"
		$confirm_message.popup_centered()
		

## 購入確認ボタンで購入ボタンを押した時
func _on_confirm_message_confirmed() -> void:
	Global.coin -= selected_item.price # アイテム情報もセーブするので、ここではセーブしない
	if selected_item.item.id not in Global.inv.item: # 未所持の時
		Global.inv.item[selected_item.item.id] = 1
	else:
		Global.inv.item[selected_item.item.id] += 1
	Global.save_game()
	$error_message.title = "購入成功！"
	$error_message.dialog_text = "%s Lv.%dを手に入れた！" % \
	[selected_item.name, selected_item.level]
	$error_message.popup_centered()
	update(-selected_item.price)
	
