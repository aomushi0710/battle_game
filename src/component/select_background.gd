extends Control

@onready var mesh = $mesh
## 背景のメッシュがちょうどループする位置
var roop_pos: Vector2

func _ready() -> void:
	roop_pos = Vector2(-mesh.size.x / 2 + 22, -mesh.size.y / 2 + 24)
	animation()

## 背景メッシュの移動アニメーションループの関数
func animation():
	mesh.position = Vector2(0, 0)
	var tween: Tween = get_tree().create_tween().bind_node(mesh)
	tween.finished.connect(func(): animation())
	tween.tween_property(mesh, "position", roop_pos, 60)

## 背景メッシュの色を一度白にしてから別の色に変更するアニメーションの関数
func color_change(color: Color):
	color.a = 0.5 # 半透明に変換
	var tween: Tween = get_tree().create_tween().bind_node(mesh)
	tween.tween_property(mesh, "self_modulate:s", 0, 0.5)
	tween.tween_property(mesh, "self_modulate", color, 0.5)
