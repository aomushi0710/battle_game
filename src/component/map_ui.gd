extends CanvasLayer

@export var _player: Player

@onready var _menu := %Menu as MapMenu
@onready var _dialog := %Dialog as MapDialog


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("menu"):
		if _dialog.visible: ## ダイアログが開かれている時はメニューを開けない 
			return
		
		if _menu.visible:
			menu_close()
		else:
			menu_open()

## メニューを開きます
func menu_open() -> void:
	_menu.visible = true
	_player.can_move = false

## メニューを閉じます
func menu_close() -> void:
	_menu.visible = false
	_player.can_move = true
