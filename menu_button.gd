@tool
extends Button

var style: StyleBoxFlat = get_theme_stylebox("hover")
var tween: Tween
@export var color: Color = Color.YELLOW: ## ボタンの文字と影の色
	set(value):
		color = value
		
		add_theme_color_override("font_hover_color", value)
		
		## 色だけを変えた新しいStyleBoxFlat
		var new_style: StyleBoxFlat = style.duplicate()
		new_style.border_color = value
		value.a = 0.5
		new_style.shadow_color = value
		
		add_theme_stylebox_override("hover", new_style)
		style = get_theme_stylebox("hover") # リロード

## フォーカス表示
func _on_mouse_entered() -> void:
	tween = create_tween().bind_node(self)
	tween.set_loops()
	tween.tween_property(style, "shadow_size", 30, 0.5)\
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(style, "shadow_size", 10, 0.5)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

## フォーカス非表示
func _on_mouse_exited() -> void:
	if tween and tween.is_running():
		tween.kill()
		style.shadow_size = 10
