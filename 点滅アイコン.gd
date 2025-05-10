extends TextureButton

var i = 0

func _ready():
	$".".set_process(false)

func _process(delta):
	if i == 0:
		$".".self_modulate.a -= delta * 2
		if $".".self_modulate.a <= 0.0:
			i = 1
	elif i == 1:
		$".".self_modulate.a += delta * 2
		if $".".self_modulate.a >= 1.0:
			i = 0
