@tool
extends Panel

## 最初のボタンのposition
@export var start_position: Vector2 = Vector2(size.x / 2, separation.y):
	set(value):
		start_position = value
		arrange_children()
## ボタンが増えるたびに位置をずらすベクトル
@export var separation: Vector2:
	set(value):
		separation = value
		arrange_children()


func arrange_children() -> void:
	for i in len(get_children()):
		var child = get_child(i)
		child.position = start_position + separation * i
