class_name Battle
extends Node2D

var stage: Stage
var enemy_deck: Deck

@onready var stage_node := %Background as Control
@onready var battle_node := %Battle as Control

func _ready() -> void:
	stage_node.setup(stage)
	battle_node.setup()
