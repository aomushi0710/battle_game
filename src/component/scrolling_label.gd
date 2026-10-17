## ツールチップなどのテキストを表示するパネル。[br]
## 長文は電光掲示板のように流して表示します。[br]
## テキストを表示させたいノードにメタデータ「help_text」を追加してください。
class_name ScrollingLabel
extends Panel

var text_speed: float = 0.05 ## テキストのスクロール速度 TODO 設定画面などで調節可能にする

@onready var mask := %Mask as Control
@onready var label := %Text as RichTextLabel

## help_textデータを持つ全てのノード[param node]にシグナルを接続する再起関数
func connect_hover_signal(node: Node) -> void:
	if node is Control and node.has_meta("help_text"):
		node.mouse_entered.connect(_text_animation.bind("[i]%s[/i]" % node.get_meta("help_text").replace("\n", "")))
	
	elif node is TabContainer: # TabBarにおけるメタデータの設定方法は異なる
			node.tab_clicked.connect(_on_tab_container_tab_clicked.bind(node))
	
	for child in node.get_children():
		connect_hover_signal(child)

## [member label]に表示される[param text]を少しずつ表示させるアニメーションを再生します
func _text_animation(text: String) -> void:
	var tween: Tween
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
		
		tween = label.create_tween().set_loops()
		tween.tween_interval(2.0)
		tween.tween_property(label, "position:x", final_val, duration).from(0.0)

## [TabContainer]のmetadataを用いて[merhod _text_animation]を呼びます
func _on_tab_container_tab_clicked(tab: int, tab_container: TabContainer) -> void:
	var text: String = "[i]%s[/i]" % tab_container.get_tab_metadata(tab)
	_text_animation(text.replace("\n", ""))
