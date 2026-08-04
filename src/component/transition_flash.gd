extends Control

@onready var back := $background
@onready var light := $light
var open: bool = true ## true:画面を開く時 false:画面を閉じる時
signal finished ## _readyのアニメーション終了時に発行されるシグナル

func _ready() -> void:
	if open == true:
		light.scale = Vector2(0, 0.05)
		await get_tree().create_timer(3).timeout # 3秒考える
		var tween: Tween = light.create_tween().bind_node(self)
		tween.tween_property(light, "scale:x", 1, 0.05)
		tween.tween_property(light, "scale:y", 1, 0.05)
		tween.tween_property(self, "modulate:a", 0, 1)
		await tween.finished
		finished.emit()
	else:
		await get_tree().create_timer(3).timeout # 3秒考える
		light.scale = Vector2(1, 1)
		var tween: Tween = light.create_tween().bind_node(self)
		tween.tween_property(light, "scale:y", 0.05, 0.05)
		tween.tween_property(light, "scale:x", 0, 0.05)
		await tween.finished
		finished.emit()
