## ツールチップなどのテキストを表示するパネル。[br]
## 長文は電光掲示板のように流して表示します。[br]
## テキストを表示させたいノードにメタデータ「help_text」を追加してください。
class_name ScrollingLabel
extends Panel

var text_speed: float = 0.05 ## テキストのスクロール速度 TODO 設定画面などで調節可能にする
var tween: Tween

@onready var mask := %Mask as Control
@onready var label := %Text as RichTextLabel


func _ready() -> void:
	# 文字が枠の上に被って表示されないようにするため、少し小さくする
	mask.size = size - Vector2(4.0, 0)

## help_textデータを持つ全てのノード[param node]にシグナルを接続する再起関数
func connect_hover_signal(node: Node) -> void:
	var control := node as Control
	if control != null and control.has_meta(&"help_text"):
		if control.mouse_entered.is_connected(_text_animation):
			control.mouse_entered.disconnect(_text_animation)
		
		control.mouse_entered.connect(_text_animation.bind("[i]%s[/i]" % str(control.get_meta(&"help_text")).replace("\n", "")))
	
	for child in node.get_children():
		connect_hover_signal(child)

## [member label]に表示される[param text]を少しずつ表示させるアニメーションを再生します
func _text_animation(text: String) -> void:
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
