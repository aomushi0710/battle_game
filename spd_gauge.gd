extends TextureProgressBar

var monster: Monster

func _process(delta: float) -> void:
	if value < Global.spd_gauge: # SPDの値ずつ毎秒増加していき、500まで到達するとコマンドリストを表示
		value += monster.SPD * Global.spd_correction * delta
	elif value >= Global.spd_gauge:
		set_process(false)
		get_parent().spd_max()
