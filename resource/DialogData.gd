class_name DialogData
extends Resource
## ダイアログに表示するデータがまとめて保存されているリソース

@export var id: int
## ダイアログに表示される本文[br]全角38文字が4行まで
@export_multiline var text: String = ""
@export var name_text: String = "" ## 名前などの、ダイアログ上部に表示されるテキスト
@export var name_color: Color = Color.BLACK
@export var image: Texture2D = null ## 左に表示される画像
@export var button_text: Array[String] = [] ## ボタンとして表示されるテキスト
