extends Panel

@onready var mask := $mask
@onready var label := $mask/text
var text_speed: float = 0.05
var tween: Tween

## help_textデータを持つ全てのノード[param node]にシグナルを接続する再起関数
func connect_hover_signal(node: Node) -> void:
	if node is Control and node.has_meta("help_text"):
		node.mouse_entered.connect(func(): 
			var text: String = "[i]%s[/i]" % node.get_meta("help_text")
			text_animation(text.replace("\n", "")))
	
	elif node is TabContainer: # TabBarにおけるメタデータの設定はやり方が違うので
			node.tab_clicked.connect(func(index):
				var text: String = "[i]%s[/i]" % node.get_tab_metadata(index)
				text_animation(text.replace("\n", "")))
	
	for child in node.get_children():
		connect_hover_signal(child)

## [param label]に表示される[param text]を少しずつ表示させるアニメーションを再生する関数
func text_animation(text: String) -> void:
	# アニメーション中なら中断
	if tween and tween.is_running():
		tween.kill()
	
	label.text = text
	label.size.x = label.get_content_width()
	label.position.x = 0
	# 文字が枠をはみ出す時
	if label.get_content_width() > mask.size.x:
		label.text += "　　" # 前後を空白で区切る
		var final_val: int = -label.get_content_width() # 1ループ分の移動先
		var duration: float = -final_val * text_speed * 0.1
		label.text += text # ループ後に元の文字が戻ってくるように追加
		label.size.x = label.get_content_width() # 画面外に消えるのを防止
		
		tween = get_tree().create_tween().bind_node(label).set_loops()
		tween.tween_interval(2)
		tween.tween_property(label, "position:x", final_val, duration)
		tween.tween_callback(func(): label.position.x = 0)
