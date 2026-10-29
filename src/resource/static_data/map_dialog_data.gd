class_name MapDialogData
extends Resource
## [MapDialog]に表示するデータがまとめて保存されているリソース

## [MapDialog]に表示される本文[br]全角34文字が3行まで
@export_multiline var text: String = ""

@export_category("フラグ関連")
## このデータが読まれた後に表示したいデータのindex[br]-1でダイアログ表示を終了[br]
## ボタン入力待ちやバトル結果待ちなど、ページ送りを待たない場合は設定は不要。
@export var redirect_id: int = -1
## 現在のフラグ数値がこのリストの中に入っていればこのデータは読まれるが、
##入っていなければスキップされる。[br]条件管理用のフラグの配列。[br]
## 空の場合は無条件に読まれます。
@export var flag_list: Array[int] = []


@export_category("ネームプレート")
@export var name_text: String = "" ## 名前などのダイアログ上部に表示されるテキスト
@export var name_color: Color = Color.BLACK ## 名前が表示される領域の背景色

@export_category("画像")
@export var speaker_texture: Texture2D = null ## 本文の左部分に表示される画像
@export var display_texture: Texture2D = null ## ダイアログ外に表示される画像[br]アスペクト比1920:1080のスクリーンショット画像などを表示できます

@export_category("ボタン")
@export var button_text: Array[String] = [] ## ボタンとして表示されるテキスト
@export var button_redirect_id: Array[int] = [] ## 対応するindexのボタン選択時の[member redirect_id]

@export_category("バトル")

@export var battle_redirect_id: Array[int] = [] ## バトルを発生させ、勝利時はindex 0のid、敗北時はindex 1のidが[member redirect_id]として処理されます。
@export var deck: Deck ## 対戦相手をこの[Deck]に固定します[br]デッキが固定されている場合、対戦前に自分のデッキと相手のデッキをプレビューします
