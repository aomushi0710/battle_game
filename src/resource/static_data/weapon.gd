class_name Attachment
extends Resource

@export var id: int ## アタッチメントの固有ID
@export var name: String ## アタッチメントの名前
@export var image: Texture ## アタッチメントの画像
@export var action: Action ## アタッチメントに搭載されている技
@export var patch_size: int: ## 割り当て可能なパッチ数の上限
	set(value):
		patch_size = max(0, value)
		if patch:
			patch.resize(patch_size)
var patch: Array


func _init() -> void:
	patch.resize(patch_size)
