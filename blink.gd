extends HBoxContainer

var tween: Tween

func blink() -> void: # 点滅関数
	tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_loops() # 以下をループ
	tween.tween_property(self, "modulate:a", 0, 1)
	tween.tween_property(self, "modulate:a", 1, 1)
