@tool
extends Resource
class_name Stage
## バトルの背景となるステージの情報が格納されたカスタムリソース。

@export var id: int
@export var name: String

@export_category("Texture")
@export var texture: Texture ## ステージの画像
@export var animation_texture: Texture ## アニメーションされるステージの画像

@export_category("Flavor Text")
@export var flavor_text: Array[BattlelogData]: ## ステージ固有のフレーバーテキスト
	set(value):
		flavor_text = value
		flavor_text_weight.resize(len(flavor_text))
		flavor_text_weight.fill(1)

@export var flavor_text_weight: Array[int] ## [member Stage.flavor_text]の重みづけテーブル
