extends Battle

@onready var dialog_node := %DialogTab as TabContainer

func _ready() -> void:
	battle_node.tutorial_mode = true
	dialog_node.set_tab_disabled(1, true)
	dialog_node.set_tab_disabled(2, true)
	super()
