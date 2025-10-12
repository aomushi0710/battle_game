extends Control

@onready var menu := $"../menu"
@onready var dialog := $"../dialog"
@onready var player := $"../../world/player"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("menu"):
		if dialog.visible: ## ダイアログが開かれている時はメニューを開けない 
			return
		
		if menu.visible:
			menu.visible = false
			player.can_move = true
		else:
			menu.visible = true
			player.can_move = false
