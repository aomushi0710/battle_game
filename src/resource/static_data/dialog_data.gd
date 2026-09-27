class_name DialogData
extends Resource
## 汎用ダイアログに表示するデータがまとめて保存されているリソース

## ダイアログ上部にタイトルとして表示されるテキスト
@export var title: String
## ダイアログに表示されるテキスト
@export_multiline var text: String
## ボタンに表示されるテキスト 要素数だけボタンが自動生成されます
@export var button_text: Array[String] = ["OK"]

## [member DialogData.text]が表示される領域の背景に表示される半透明な画像
@export var background_texture: Texture2D
## ダイアログの背景色
@export var dialog_color: Color = Color.BLACK
## ダイアログの枠線色
@export var dialog_border_color: Color = Color.WHITE
## ボタン選択時の色 初期値は黄色
@export var button_color: Array[Color]
