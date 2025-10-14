class_name DialogData
extends Resource
## ダイアログに表示するデータがまとめて保存されているリソース

## このデータが読まれた後に表示したいデータのindex[br]-1でダイアログ表示を終了[br]
## ボタン入力を待つ([member DialoData.button_text]プロパティが空でない)場合は、
##[member DialoData.button_redirect_id]プロパティを用いるため、
## どの数が入っても結果は変わらず、設定は不要です。
@export var redirect_id: int = -1
## 現在のフラグ数値がこのリストの中に入っていればこのデータは読まれるが、
##入っていなければスキップされる。[br]条件管理用のフラグの配列。[br]
## 空の場合は無条件に読まれます。
@export var flag_list: Array[int] = []
## ダイアログに表示される本文[br]全角34文字が3行まで
@export_multiline var text: String = ""

@export_category("ネームプレート")
@export var name_text: String = "" ## 名前などの、ダイアログ上部に表示されるテキスト
@export var name_color: Color = Color.BLACK ## 名前が表示される領域の背景色

@export_category("画像")
@export var image: Texture2D = null ## 本文左に表示される画像

@export_category("ボタン")
@export var button_text: Array[String] = [] ## ボタンとして表示されるテキスト
## 対応するindexのボタン選択時の[member DialogData.redirect_id]
@export var button_redirect_id: Array[int] = []
