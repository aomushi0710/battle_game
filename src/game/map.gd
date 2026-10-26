class_name Map
extends Node2D

@onready var _canvas_layer := %CanvasLayer as CanvasLayer
@onready var _player := %Player as Player

## タイトル画面でマップを表示する時、不要なUIを削除しプレイヤーの入力を受け付けなくします
func setup_for_title() -> void:
	_canvas_layer.queue_free()
	_canvas_layer = null
	
	_player.is_input_enabled = false
