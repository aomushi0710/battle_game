extends RichTextLabel

var action: Action
var i: int = 0
var tween: Tween

func selected(act: Action) -> void:
	if action == act: # 前と同じ技を選んだなら何もしない
		return
	
	if tween and tween.is_running(): # tweenがすでに動作しているなら停止
		tween.kill()
	action = act
	self.text = "[center][img=25]" + action.element[i].icon.resource_path + \
	"[/img]" + action.element[i].name + "[/center]" # 初期値
	self.modulate.a = 1 # 可視化
	
	if len(action.element) > 1: # 複数属性を持つなら点滅
		blink()


func blink() -> void: # 点滅関数
	i = 0 # 初期化
	tween = create_tween()
	tween.set_loops() # 以下をループ
	tween.tween_property(self, "modulate:a", 0, 1)
	tween.tween_callback(Callable(self, "change"))
	tween.tween_property(self, "modulate:a", 1, 1)


func change() -> void: # 要素更新関数
	i += 1
	if i >= len(action.element): # 無効なindexを取らないように初期化
		i = 0
	self.text = "[center][img=25]" + action.element[i].icon.resource_path + \
	"[/img]" + action.element[i].name + "[/center]"
