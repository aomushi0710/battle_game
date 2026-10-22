class_name MonsterData
extends Resource
## モンスターの基本情報が入ったカスタムリソース

@export var id: int ## モンスターのid

@export var evolution_forms: Array[MonsterForm] ## モンスターの全形態が入った配列[br]配列のindexは、形態を指す[enum Monster.Form]の定数である。
@export var action: Array[Action] ## 使用可能な技の配列

@export var coin: int ## モンスターが落とすコイン枚数
