extends Node2D
class_name Battle

@export var stage_node: Control

var stage: Stage
var enemy_deck: Deck

func _ready() -> void:
	stage_node.setup(stage)
