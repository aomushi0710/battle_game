extends RichTextLabel

var action
var i: int = 0
var tween: Tween
var font_size: int

func selected(act, f_size: int) -> void:
	if action == act: # 前と同じ技を選んだなら何もしない
		return
	
	if tween and tween.is_running(): # tweenがすでに動作しているなら停止
		tween.kill()
	action = act
	font_size = f_size
	i = 0 # 初期化
	text = "[center][img=%d]%s[/img][bgcolor=%s]%s[/bgcolor][/center]" % \
	[font_size, action.element[i].icon.resource_path, 
	action.element[i].color_text, action.element[i].name] # 初期値
	modulate.a = 1 # 可視化
	
	if len(action.element) > 1: # 複数属性を持つなら点滅
		blink()


func blink() -> void: # 点滅関数
	tween = create_tween().bind_node(self)
	tween.set_loops() # 以下をループ
	tween.tween_property(self, "modulate:a", 0, 1)\
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)
	tween.tween_callback(Callable(self, "change"))
	tween.tween_property(self, "modulate:a", 1, 1)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)


func change() -> void: # 要素更新関数
	i += 1
	if i >= len(action.element): # 無効なindexを取らないように初期化
		i = 0
	text = "[center][img=%d]%s[/img][bgcolor=%s]%s[/bgcolor][/center]" % \
	[font_size, action.element[i].icon.resource_path, 
	action.element[i].color_text, action.element[i].name] # 初期値
