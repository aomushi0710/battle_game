class_name Ability
extends Resource

enum Target {
	test2, 
	連動, 
	敵単体, 
	敵全体, 
	味方単体, 
	味方全体, 
	自分, 
	test
}

enum Timing {
	前, 
	
}

@export var name: String ## 特殊効果の名前
@export_multiline var bbcode_name: String ## 特殊効果の名前(BBcode有り)
@export var target: Target ## 特殊効果の対象
@export_range(1, 100) var chance: int = 100 ## 特殊効果の発動確率
## 特殊効果の発動タイミング
@export_enum("最初") var timing: int

## 特殊効果の発動条件
@export_enum("なし") var trigger: int
