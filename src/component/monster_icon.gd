@tool
class_name MonsterIcon
extends TextureButton

@export var frame: Polygon2D
@export var element_frame: Polygon2D
@export var element_icon: TextureRect
@export var back_ground: TextureRect
@export var monster_image: TextureRect
@export var shader_material: Material

var tween: Tween
var element_index: int = 0 ## [member MonsterForm.element]のindex

@export var form: Global.Form = Global.Form.第一形態: ## 表示されるモンスターの形態
	set(value):
		if data != null:
			# 対応する形態を持っていない場合は最終形態で表示する
			if len(data.evolution_forms) <= value:
				form = len(data.evolution_forms) - 1
			else:	
				form = value
		
		_update()

@export var data: MonsterData: ## 表示されるモンスター
	set(value):
		data = value
		form = Global.Form.第一形態

## 本来のmodulate.vの値だが、この変数に値を代入することでshaderにも影響を与えられる
var icon_modulate: float:
	set(value):
		icon_modulate = value
		modulate.v = icon_modulate
		monster_image.material.set_shader_parameter("brightness", icon_modulate)

## インスタンス生成時に、自動でshaderを複製してから適用
func _ready() -> void:
	monster_image.material = shader_material.duplicate()

## [param data]プロパティが変更された時に見た目を更新する関数
func _update() -> void:
	if tween and tween.is_running():
		element_index = 0
		element_icon.self_modulate.a = 1
		tween.kill()
	if back_ground == null or frame == null or monster_image == null:
		return
	
	back_ground.texture = back_ground.texture.duplicate(true)
	var gradient: Gradient = back_ground.texture.gradient ## 背景のグラデーション
	if data == null:
		frame.color = Color(0.25, 0.25, 0.25)
		element_frame.color = Color(0.25, 0.25, 0.25)
		element_icon.texture = null
		monster_image.texture = null
		gradient.colors = PackedColorArray([Color(0.5, 0.5, 0.5)])
		gradient.offsets = PackedFloat32Array([0])
	else:
		frame.color = data.evolution_forms[form].element[0].color
		element_frame.color = data.evolution_forms[form].element[0].color
		element_icon.texture = data.evolution_forms[form].element[0].icon
		monster_image.texture = data.evolution_forms[form].image
		
		if len(data.evolution_forms[form].element) <= 1: # 複数属性ではない時
			gradient.colors = PackedColorArray([
				data.evolution_forms[form].element[0].color.lightened(0.8), 
				data.evolution_forms[form].element[0].color.lightened(0.6)
			])
			gradient.offsets = PackedFloat32Array([0.5, 1.0])
		else:
			var color_list: PackedColorArray = []
			for ele: Element in data.evolution_forms[form].element: # 属性の色をリストに全て登録
				color_list.append(ele.color.lightened(0.6))
			gradient.colors = color_list
			
			var offset_list: PackedFloat32Array = []
			for i in len(color_list): # グラデーションの位置をリストに全て登録
				offset_list.append((i + 0.5) / len(color_list)) # 色数によって変動
			gradient.offsets = offset_list
			
			blink_fade_out()

## 属性フェードアウトアニメーション
func blink_fade_out() -> void:
	if tween and tween.is_running():
		tween.kill()
	
	tween = create_tween().bind_node(frame)
	tween.tween_property(frame, "color", Color.WHITE, 1)\
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)
	tween.parallel().tween_property(element_frame, "color", Color.WHITE, 1)\
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)
	tween.parallel().tween_property(element_icon, "self_modulate:a", 0, 1)\
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)
	tween.tween_callback(blink_fade_in)

## 属性フェードインアニメーション
func blink_fade_in() -> void:
	change()
	
	if tween and tween.is_running():
		tween.kill()
	
	tween = create_tween().bind_node(frame)
	tween.tween_property(frame, "color", 
	data.evolution_forms[form].element[element_index].color, 1)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween.parallel().tween_property(element_frame, "color", 
	data.evolution_forms[form].element[element_index].color, 1)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween.parallel().tween_property(element_icon, "self_modulate:a", 1, 1)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween.tween_callback(blink_fade_out)

## 属性切り替え関数
func change() -> void:
	element_index += 1
	if element_index >= len(data.evolution_forms[form].element): # 無効なindexを取らないように初期化
		element_index = 0
	element_icon.texture = data.evolution_forms[form].element[element_index].icon
