@tool
extends TextureButton

@onready var frame := $Frame
@onready var element_frame := $ElementFrame
@onready var element_icon := $ElementIcon
@onready var back_ground := $BackGround
@onready var monster_image := $MonsterImage

var tween: Tween
var element_index: int = 0 ## [member Monster.element]のindex
@export var monster: Monster: ## 表示されるモンスター
	set(mon):
		monster = mon
		if is_inside_tree():
			_update()

## [param monster]プロパティが変更された時に見た目を更新する関数
func _update() -> void:
	if tween and tween.is_running():
		element_index = 0
		element_icon.self_modulate.a = 1
		tween.kill()
	if back_ground == null or frame == null or monster_image == null:
		return
	
	back_ground.texture = back_ground.texture.duplicate(true)
	var gradient: Gradient = back_ground.texture.gradient ## 背景のグラデーション
	if monster == null:
		frame.color = Color(0.25, 0.25, 0.25)
		element_frame.color = Color(0.25, 0.25, 0.25)
		element_icon.texture = null
		monster_image.texture = null
		gradient.colors = PackedColorArray([Color(0.5, 0.5, 0.5)])
		gradient.offsets = PackedFloat32Array([0])
	else:
		frame.color = monster.element[0].color
		element_frame.color = monster.element[0].color
		element_icon.texture = monster.element[0].icon
		monster_image.texture = monster.image
		
		if len(monster.element) <= 1: # 複数属性ではない時
			gradient.colors = PackedColorArray([
				monster.element[0].color.lightened(0.8), 
				monster.element[0].color.lightened(0.6)
			])
			gradient.offsets = PackedFloat32Array([0.5, 1.0])
		else:
			var color_list: PackedColorArray = []
			for ele: Element in monster.element: # 属性の色をリストに全て登録
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
	tween.tween_property(frame, "color", monster.element[element_index].color, 1)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween.parallel().tween_property(element_frame, "color", monster.element[element_index].color, 1)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween.parallel().tween_property(element_icon, "self_modulate:a", 1, 1)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween.tween_callback(blink_fade_out)

## 属性切り替え関数
func change() -> void:
	element_index += 1
	if element_index >= len(monster.element): # 無効なindexを取らないように初期化
		element_index = 0
	element_icon.texture = monster.element[element_index].icon
