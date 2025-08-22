class_name Ability
extends Resource

enum Target { ## 特殊効果を発動する対象
	連動, ## Actionのものと同一になります。
	敵単体, 
	敵全体, 
	味方単体, 
	味方全体, 
	自分, 
}

enum Trigger { ## 特殊効果の発動条件(複数選択可)
	
}

@export var name: String ## 特殊効果の名前
@export_multiline var bbcode_name: String ## 特殊効果の名前(BBcode有り)
@export var target: Target ## 特殊効果の対象
@export_range(1, 100) var chance: int = 100 ## 特殊効果の発動確率
## 特殊効果を発動するタイミング[br][br]
## [code]true[/code][b]ダメージ判定後[/b]に発動します。[br]
## [code]false[/code][b]ダメージ判定前[/b]に発動します。
@export var is_after: bool = true
@export var trigger: Array[Trigger] ## 特殊効果の発動条件(複数選択可)
@export_multiline var description: String ## 特殊効果の説明文
