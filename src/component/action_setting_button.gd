@tool
extends HBoxContainer

signal delete_button_up

const BASE_SHADOW_SIZE := 10
const BASE_COLOR_V := 0.5

@onready var chance_label := %Chance as RichTextLabel
@onready var action_button := %ActionButton as ActionButton
@onready var delete_button := %Delete as Button

@export var lock: bool: ## 解放条件を満たしていないなど、ロックされた状態で表示したい時
	set(value):
		# chance setter内のガード節の関係で、状態を更新するタイミングが異なっている
		if value == true:
			chance = 0
			lock = value
			
			if not is_node_ready():
				return
			
			action_button.modulate.v = 0.5
			chance_label.add_theme_font_size_override("normal_font_size", 35)
			chance_label.set_meta("help_text", 
			"[color=yellow]この技はロックされています！[/color]" + 
			"モンスターがLv.%d以上に到達すると解放されます。" % 
			action.unlock_level)
			chance_label.text = " 🔒 "
		else:
			lock = value
			chance = 0
			
			if not is_node_ready():
				return
			
			action_button.modulate.v = 1.0
			chance_label.add_theme_font_size_override("normal_font_size", 40)
			chance_label.set_meta("help_text", "この技に現在設定されている出現確率。")

@export var action: Action: ## 技
	set(act):
		action = act
		# [Action]リソースが存在するかどうかと、[ActionData]リソースが存在するかどうかを
		# 調べる必要がある。
		if action == null:
			action_button.action = null
		elif action.data == null:
			action_button.action = null
		else:
			action_button.action = action.data

@export_range(0, 100) var chance: int = 0: ## この技の現在の出現確率
	set(value):
		if lock == true:
			chance = 0
			return
		
		chance = value
		
		if chance_label != null:
			chance_label.text = "%3d%%" % chance
			
			var style: StyleBoxFlat = (
				chance_label.get_theme_stylebox("normal").duplicate(true))
			
			if chance == 0:
				style.shadow_size = 0
				style.bg_color.v = 0
				delete_button.disabled = true
			else:
				style.shadow_size = BASE_SHADOW_SIZE + chance / 4
				# chanceが100の時に計算結果が1.0になるように調整している
				style.bg_color.v = BASE_COLOR_V + chance / 200.0
				delete_button.disabled = false
			
			chance_label.add_theme_stylebox_override("normal", style)


func _on_delete_button_button_up() -> void:
	chance = 0
	delete_button_up.emit()
