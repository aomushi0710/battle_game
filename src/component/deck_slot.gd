@tool
class_name DeckSlot
extends ColorRect

@onready var save_button := %Save as Button
@onready var load_button := %Load as Button
@onready var delete_button := %Delete as Button
@onready var deck_slot_number_label := %DeckSlotNumber as RichTextLabel
@onready var deck_name_label := %DeckName as Label
@onready var version_label := %Version as RichTextLabel
@onready var monster_icon_1 := %MonsterIcon1 as MonsterIcon
@onready var monster_icon_2 := %MonsterIcon2 as MonsterIcon
@onready var monster_icon_3 := %MonsterIcon3 as MonsterIcon

var slot_index: int ## デッキスロット番号

@export var deck: Deck: ## 表示する[Deck][br]この値が更新されると、UIが更新されます。
	set(value):
		if value == deck:
			return
		
		deck = value
		_update_ui()

var is_save_mode: bool: ## セーブ時かどうか[br]この値が変更されると、表示するボタンを切り替えます
	set(value):
		print(value)
		if slot_index <= 0:
			return
		
		is_save_mode = value
		if value:
			save_button.show()
			load_button.hide()
		else:
			save_button.hide()
			load_button.show()

func _ready() -> void:
	if slot_index != 0:
		is_save_mode = SaveManager.is_save_mode
		deck_slot_number_label.text = "デッキスロット%02d" % slot_index

## デッキスロットUI上に各種データを表示する関数
## TODO 第二形態・第三形態の見た目でもプレビューできるようにする
func _update_ui() -> void:
	var icon: String = "　" ## デッキのエラー情報を表示するテキスト
	var show_monster: bool = false ## [Monster]の情報を表示するかどうか
	var enable_button: bool = false ## セーブまたはロードボタンを使用可能にするかどうか
	
	if not deck or not deck.has_valid_slot():
		deck_name_label.hide()
		version_label.hide()
		load_button.disabled = true
		delete_button.disabled = true
		return
	else:
		deck_name_label.show()
		version_label.show()
		load_button.disabled = false
		delete_button.disabled = false
	
	match SaveManager.validate_deck(deck):
		SaveManager.DeckValidationResult.UNKNOWN_ERROR, SaveManager.DeckValidationResult.OUTDATED_VERSION_DATA, SaveManager.DeckValidationResult.FUTURE_VERSION_DATA, SaveManager.DeckValidationResult.BETA_DATA_IN_MASTER, SaveManager.DeckValidationResult.MASTER_DATA_IN_BETA:
			icon = "❌"
		
		SaveManager.DeckValidationResult.INVALID_MONSTER_COUNT, SaveManager.DeckValidationResult.DUPLICATE_MONSTER_ID:
			icon = "❌"
			show_monster = true
		
		SaveManager.DeckValidationResult.MIGRATION_REQUIRED:
			icon = "⚠️"
			show_monster = true
			enable_button = true
		
		SaveManager.DeckValidationResult.OK:
			show_monster = true
			enable_button = true
	
	deck_name_label.text = deck.name
	version_label.text = icon + "[i]ver." + deck.version + "[/i]"
	if deck.is_beta:
		version_label.text += "(β)"
	
	if show_monster:
		monster_icon_1.data = deck.monster[0].data
		monster_icon_2.data = deck.monster[1].data
		monster_icon_3.data = deck.monster[2].data
	else:
		monster_icon_1.data = null
		monster_icon_2.data = null
		monster_icon_3.data = null
	
	if enable_button:
		load_button.disabled = false
		delete_button.disabled = false
	else:
		load_button.disabled = true
		delete_button.disabled = true
	
	
