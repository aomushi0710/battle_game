class_name MonsterData
extends Resource
## モンスターの基本情報が入ったカスタムリソース[br]
## ALERT この型のリソースファイルはゲーム内で変更してはいけません。

@export_category("モンスター")
@export var id: int ## モンスターのid
## モンスターの全形態が入った配列[br]
## 配列のindexは、形態を指す[enum Global.Form]の定数である。
@export var evolution_forms: Array[MonsterForm]

@export_category("技")
## その形態で使用可能な技の配列
@export var action: Array[Action]

@export_category("ドロップアイテム")
@export var coin: int ## モンスターが落とすコイン枚数
