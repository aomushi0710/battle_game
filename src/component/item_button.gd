## バトル中に使用される、アイテム表示用のボタン
class_name ItemButton
extends TextureButton

var item: Item ## ボタンに割り当てられたアイテム
var is_used: bool = false ## アイテムがバトル中で既に使用されたかどうか
