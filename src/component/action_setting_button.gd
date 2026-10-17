@tool
class_name ActionSettingButton
extends HBoxContainer

signal delete_button_up(act: Action) ## [member delete_button]が押された時に発行されます

const BASE_SHADOW_SIZE := 10
const BASE_COLOR_V := 0.5

@export var is_locked: bool: ## 解放条件を満たしていないなど、ロックされた状態で表示したい時
	set(value):
		# chance setter内のガード節の関係で、状態を更新するタイミングが異なっている
		if value:
			chance = 0
			is_locked = value
		else:
			is_locked = value
			chance = 0
		
		_update_action_button_lock()

@export var action: Action: ## 技
	set(value):
		action = value
		_update_action_button()

@export_range(0, 100) var chance: int = 0: ## この技の現在の出現確率
	set(value):
		if is_locked == true:
			chance = 0
			return
		
		chance = value
		_update_chance()

var _local_stylebox: StyleBoxFlat ## テーマ上書き用StyleBox

@onready var chance_label := %Chance as RichTextLabel
@onready var action_button := %ActionButton as ActionButton
@onready var delete_button := %Delete as Button


func _ready() -> void:
	if is_instance_valid(chance_label):
		_local_stylebox = chance_label.get_theme_stylebox(&"normal").duplicate() as StyleBoxFlat
		chance_label.add_theme_stylebox_override(&"normal", _local_stylebox)
	
	_update_action_button_lock()
	_update_action_button()
	_update_chance()


func _update_action_button_lock() -> void:
	if is_locked:
		action_button.modulate.v = 0.5
		
		var unlock_level: int = 0
		if action:
			unlock_level = action.unlock_level
		chance_label.add_theme_font_size_override("normal_font_size", 35)
		chance_label.set_meta("help_text", "[color=yellow]この技はロックされています！[/color]モンスターがLv.%d以上に到達すると解放されます。" % unlock_level)
		chance_label.text = " 🔒 "
	else:
		action_button.modulate.v = 1.0
		chance_label.add_theme_font_size_override("normal_font_size", 40)
		chance_label.set_meta("help_text", "この技に現在設定されている出現確率。")


func _update_action_button() -> void:
	if action and action.data:
		action_button.action = action.data
	else:
		action_button.action = null


func _update_chance() -> void:
	chance_label.text = "%3d%%" % chance
	
	if chance == 0:
		_local_stylebox.shadow_size = 0
		_local_stylebox.bg_color.v = 0
		delete_button.disabled = true
	else:
		_local_stylebox.shadow_size = BASE_SHADOW_SIZE + chance / 4
		# chanceが100の時に計算結果が1.0になるように調整している
		_local_stylebox.bg_color.v = BASE_COLOR_V + chance / 200.0
		delete_button.disabled = false

## [member delete_button]の[signal BaseButton.button_up]を中継し、UIを更新しつつ[signal delete_button_up]を発行します
func _on_delete_button_button_up() -> void:
	chance = 0
	delete_button_up.emit(action)
