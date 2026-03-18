extends Control

@onready var menu := $"../menu"
@onready var dialog := $"../dialog"
@onready var player := $"../../world/player"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("menu"):
		if dialog.visible: ## ダイアログが開かれている時はメニューを開けない 
			return
		
		if menu.visible:
			menu_close()
		else:
			menu_open()

## メニューを開きます
func menu_open() -> void:
	menu.visible = true
	player.can_move = false

## メニューを閉じます
func menu_close() -> void:
	menu.visible = false
	player.can_move = true
