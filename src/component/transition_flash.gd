extends Control

signal finished ## [method Node._ready]のアニメーション終了時に発行されるシグナル

var is_open: bool = true

#@onready var background := %Background
@onready var light := %Light

func _ready() -> void:
	if is_open:
		light.scale = Vector2(0, 0.05)
		await get_tree().create_timer(3).timeout
		var tween: Tween = light.create_tween().bind_node(self)
		tween.tween_property(light, "scale:x", 1, 0.05)
		tween.tween_property(light, "scale:y", 1, 0.05)
		tween.tween_property(self, "modulate:a", 0, 1)
		await tween.finished
		finished.emit()
	else:
		await get_tree().create_timer(3).timeout
		light.scale = Vector2(1, 1)
		var tween: Tween = light.create_tween().bind_node(self)
		tween.tween_property(light, "scale:y", 0.05, 0.05)
		tween.tween_property(light, "scale:x", 0, 0.05)
		await tween.finished
		finished.emit()
