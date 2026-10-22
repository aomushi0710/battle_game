extends "battle_buttons.gd"

## [method show_main_button]が終了した時に発行されます
signal main_button_showed
## [method show_status_button]が終了した時に発行されます
signal status_button_showed
## ステータスのテキストをページ送りされた時に発行されます
signal status_paging
## 技説明テキストをページ送りされた時に発行されます
signal description_paging
## 戻るボタンが押された時に発行されます
signal back

@onready var main_action_button := %ActionButton as Button
@onready var player_status_button := %PlayerStatus as Button

## チュートリアル時は最終ページで入力を待ち、[signal description_paging]を発行します
func _set_action_description_text() -> void:
	var descriptions: Array[String] = _action_description_creator(selected_action, true)
	var description_text: Array[String] = ["[i][u]%s[/u][/i]\n%s　　MP Cost:[color=aqua]%d[/color]\n" % [selected_action.name, descriptions[0], selected_action.mp] + "%s　　Power　:[color=red]%d[/color]" % [descriptions[1], selected_action.power]]
	
	if selected_action.ability.is_empty():
		await dialog_tab.text_setter(BattlelogData.new(description_text, true))
	else:
		var ability_description: Array = [null] ## 特殊効果説明画像のリスト
		for ability: Ability in selected_action.ability:
			description_text.append(ability.description)
			var abi_des := Global.ABILITY_DESCRIPTION.instantiate() as AbilityDescription
			abi_des.ability = ability
			ability_description.append(abi_des)
		
		await dialog_tab.text_setter(BattlelogData.new(
			description_text, true, BattlelogData.Tab.MAIN, ability_description
		))
	
	description_paging.emit()


func show_main_button() -> void:
	await super()
	for button in main_buttons.get_children() as Array[Button]:
		button.disabled = true
	
	main_button_showed.emit()


func show_action_button() -> void:
	for button in action_container.get_children() as Array[ActionButton]:
		button.disabled = true
	await super()


func show_status_button() -> void:
	await super()
	for button in status_buttons.get_children() as Array[Button]:
		button.disabled = true
	
	status_button_showed.emit()


func _on_back_button_up() -> void:
	super()
	back.emit()


func battle_finished() -> void:
	super()
	Global.player_deck = Global.current_deck.duplicate() # 元のデッキに戻す


func status_dialog(i: int) -> void:
	super(i)
	status_paging.emit()
