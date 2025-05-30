extends TabContainer

var tween: Tween
var text_speed: float = 0.05 # テキストアニメーションの1文字あたりの再生速度


func _ready() -> void:
	self.current_tab = 0
	_on_tab_changed(self.current_tab) # 初期値タブのテキストをアニメーション


func _on_tab_changed(tab: int) -> void:
	if tween and tween.is_running(): # tweenがすでに動作しているなら停止
		tween.kill()
	var label: RichTextLabel = self.get_child(tab) # タブのラベル取得
	label.visible_characters = 0 # 隠す
	tween = get_tree().create_tween() # tween生成、アニメーション再生
	tween.tween_property(label, "visible_characters", \
	len(label.text), text_speed * len(label.text))
