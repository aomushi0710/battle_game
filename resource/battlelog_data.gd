@tool
extends Resource
class_name BattlelogData

## バトル中のダイアログで表示可能なタブの一覧
enum Tab {
	MAIN, ## 基本的な全てのメッセージを表示するタブ
	STATUS, ## モンスターのステータスを表示するタブ
	BATTLE_LOG, ## バトルの履歴を表示するタブ(未実装)
}

@export_multiline var text: Array[String]: ## 要素1つにつき1ページ、全角21文字が3行分までの本文
	set(value):
		text = value
		image.resize(value.size())
@export var should_wait: bool ## 最終ページにおいて、プレイヤー入力を待つかどうかのフラグ
@export var tab: Tab ## メッセージの表示先となるタブ
@export var image: Array ## [member BattleDialogData.text]と同時に表示する画像

## 引数については[BattlelogData]クラスを参照してください。[br]
## [param p_image]は常に[param p_text]と同じ要素数となるように調整されます。 
func _init(
	p_text: Array[String] = [""],
	p_should_wait: bool = true, 
	p_tab: Tab = Tab.MAIN,
	p_image: Array = []
) -> void:
	p_image.resize(p_text.size())
	
	text = p_text
	tab = p_tab
	should_wait = p_should_wait
	image = p_image
