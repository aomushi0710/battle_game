extends CanvasLayer

@onready var _menu := %Menu as MapMenu
@onready var _dialog := %Dialog as MapDialog


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("menu"):
		# ダイアログが開かれている時はメニューを開けない
		if _dialog.visible:
			return
		
		if _menu.visible:
			_menu.close_menu()
		else:
			_menu.open_menu()
