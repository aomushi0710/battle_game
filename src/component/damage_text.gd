extends RichTextLabel

func _ready() -> void:
	position =  Vector2(40 + randi() % 100,randi() % 156) # 端や下側に出現しないように調整
	var tween: Tween = get_tree().create_tween().bind_node(self)\
	.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.15) # 拡大アニメーション
	tween.tween_property(self, "scale", Vector2(1, 1), 0.05) # 縮小アニメーション
	tween.tween_interval(1.0) # 1秒停止# 移動アニメーション
	tween.tween_property(self, "position:y", position.y - 10, 0.1)
	# 移動+透明化アニメーション
	tween.tween_property(self, "position:y", position.y - 40, 0.4)
	tween.parallel().tween_property(self, "self_modulate:a", 0, 0.4)
	tween.tween_callback(queue_free) # 削除
