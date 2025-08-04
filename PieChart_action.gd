extends Control

@onready var action1: TextureProgressBar = $action1
@onready var action2: TextureProgressBar = $action2
@onready var action3: TextureProgressBar = $action3
@onready var action4: TextureProgressBar = $action4
@onready var nodes: Array[TextureProgressBar] = [action1, action2, action3, action4]

var actions: Array[Action]
var chances: Array[int]

func _ready() -> void:
	for i in range(4):
		nodes[i].value = chances[i]
		nodes[i].tint_progress = actions[i].element[0].color
