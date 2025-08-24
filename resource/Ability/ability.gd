class_name Ability
extends Resource

enum Timing { ## 特殊効果の発動タイミング
	なし, ## 自動で発動します。
	前, ## ダメージ判定前に発動します。
	後, ## ダメージ判定後に発動します。
}

enum Trigger { ## 特殊効果の発動条件(複数選択可)
	接触
}

@export var name: String ## 特殊効果の名前
@export_multiline var bbcode_name: String ## 特殊効果の名前(BBcode有り)
@export var target: Global.Target ## 特殊効果の対象
@export_range(1, 100) var chance: int = 100 ## 特殊効果の発動確率
## 特殊効果を発動するタイミング[br][br]
## [code]true[/code][b]ダメージ判定後[/b]に発動します。[br]
## [code]false[/code][b]ダメージ判定前[/b]に発動します。
@export var timing: Timing = Timing.後 ## 特殊効果の発動タイミング
@export var trigger: Array[Trigger] ## 特殊効果の発動条件(複数選択可)
@export_multiline var description: String ## 特殊効果の説明文(バトル中の表示は全角13文字が3行まで)
@export_multiline var battle_log_message: String ## バトル中に特殊効果が発動された時、ログに表示される文章(全角21文字が3行まで)
