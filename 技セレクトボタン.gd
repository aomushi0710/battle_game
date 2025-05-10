extends Button

@onready var texture = $TextureRect
var action: Action
var icon_visible := true
var i: int = 0

signal element_icon 

func _ready() -> void:
	element_icon.emit() # インスタンスされた時にシグナルを送る

func _process(delta: float) -> void:
	texture.texture = action.element[i].icon
	
	if icon_visible == true:
		texture.self_modulate.a -= delta
		if texture.self_modulate.a <= 0.0:
			icon_visible = false
			
			if i == len(action.element) - 1: # index変化によるアイコン切り替え処理
				i = 0
			else:
				i += 1
	else:
		texture.self_modulate.a += delta
		if texture.self_modulate.a >= 1.0:
			icon_visible = true
	
