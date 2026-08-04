@tool
class_name ActionButton
extends Button
## 技のボタン

@export var element: TextureRect
@export var background: TextureRect

var tween: Tween ## 属性アイコン点滅アニメーション
var n: int = 0 ## 属性アイコン点滅用

@export var action: ActionData: ## 技
	set(act):
		if action == act:
			return
		elif tween and tween.is_running():
			tween.kill()
		
		action = act
		background.texture = background.texture.duplicate(true)
		var gradient: Gradient = background.texture.gradient ## 背景のグラデーション
		if action == null:
			text = " "
			element.hide()
			gradient.colors = PackedColorArray([Color.BLACK])
		else:
			text = action.name
			element.texture = action.element[0].icon
			element.show()
			if len(action.element) <= 1: # 複数属性ではない時
				gradient.colors = PackedColorArray(
					[action.element[0].color.darkened(0.5), action.element[0].color])
				gradient.offsets = PackedFloat32Array([1.0 / 3.0, 2.0 / 3.0])
			else: # 複数の属性を持つ技の時
				var color_list: PackedColorArray
				for ele: Element in action.element: # 属性の色をリストに全て登録
					color_list.append(ele.color)
				gradient.colors = color_list
				
				var offset_list: PackedFloat32Array
				for i in len(color_list): # グラデーションの位置をリストに全て登録
					offset_list.append((i + 1.0) / (len(color_list) + 1.0)) # 色数によって変動
				gradient.offsets = offset_list
				
				blink()

## 点滅関数
func blink() -> void:
	tween = create_tween().bind_node(element)
	tween.set_loops() # 以下をループ
	tween.tween_property(element, "self_modulate:a", 0, 1)\
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)
	tween.tween_callback(Callable(self, "change"))
	tween.tween_property(element, "self_modulate:a", 1, 1)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)

## blink()用更新関数
func change() -> void:
	n += 1
	if n >= len(action.element): # 無効なindexを取らないように初期化
		n = 0
	element.texture = action.element[n].icon
