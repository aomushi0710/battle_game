class_name Debug
extends Control
## オープンキャンパスに出展する際、予めアイテムを購入しておくためのコインを入手するためのデバッグ画面

@onready var spin_box := %CoinValue as SpinBox

func _on_coin_set_button_up() -> void:
	SaveManager.add_coins(spin_box.value)


func _on_back_button_up() -> void:
	get_tree().change_scene_to_file(Global.MAIN_SCENE)
