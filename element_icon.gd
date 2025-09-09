extends TextureRect

var monster: Monster:
	set(mon):
		if monster == mon: # 前と同じ技を選んだなら何もしない
			return
	
		if tween and tween.is_running(): # tweenがすでに動作しているなら停止
			tween.kill()
		
		monster = mon
		i = 0 # 初期化
		texture = mon.element[i].icon # 初期値
		modulate.a = 1 # 可視化
		
		if len(mon.element) > 1: # 複数属性を持つなら点滅
			blink()

var i: int = 0
var tween: Tween

func blink() -> void: ## 点滅関数
	tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).bind_node(self)
	tween.set_loops() # 以下をループ
	tween.tween_property(self, "modulate:a", 0, 1)
	tween.tween_callback(Callable(self, "change"))
	tween.tween_property(self, "modulate:a", 1, 1)


func change() -> void: ## 要素更新関数
	i += 1
	if i >= len(monster.element): # 無効なindexを取らないように初期化
		i = 0
	self.texture = monster.element[i].icon
