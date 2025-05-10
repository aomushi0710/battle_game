extends RichTextLabel

var action: Action
var text_visible := true
var i: int = 0

func _ready() -> void:
	self.set_process(false) # 初期設定false


func _process(delta: float) -> void:
	self.text = "[center][img=25]" + action.element[i].icon.resource_path + \
	"[/img]" + action.element[i].name + "[/center]"
	
	if text_visible == true:
		self.self_modulate.a -= delta
		if self.self_modulate.a <= 0.0:
			text_visible = false
			
			if i == len(action.element) - 1: # index変化によるアイコン切り替え処理
				i = 0
			else:
				i += 1
	else:
		self.self_modulate.a += delta
		if self.self_modulate.a >= 1.0:
			text_visible = true
