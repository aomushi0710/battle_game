extends HBoxContainer

var tween: Tween

func blink() -> void: # 点滅関数
	modulate.a = 1
	show()
	tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).bind_node(self)
	tween.set_loops() # 以下をループ
	tween.tween_property(self, "modulate:a", 0, 1)
	tween.tween_property(self, "modulate:a", 1, 1)


func blink_stop() -> void: # 点滅関数のストップ
	if tween and tween.is_running():
		tween.kill()
	hide()
