extends Node2D

@onready var background: Control = $Node2D/background
@onready var battle_node: Control = $Node2D/battle
@onready var button_node: Control = $Node2D/battle/button
@onready var dialog_node: TabContainer = $Node2D/battle/button/dialogtab

var action_data = Global.action_data

func _ready() -> void:
	battle_node.tutorial_mode = true
	dialog_node.set_tab_disabled(1, true)
	dialog_node.set_tab_disabled(2, true)
	dialog_node.global_flavor_text = [[""]]
