class_name Action
extends Resource

enum DamageType {
	なし, ## いずれのステータスも参照されません。
	物理, ## 攻撃側はATK、防御側はDEFを参照します。
	魔法, ## 攻撃側はMAG、防御側はRESを参照します。
}

@export var id: int ## 技のid
@export var name: String ## 技の名前
@export var element: Array[Element] ## 技の属性 Element型のリソース[br]複数登録可能
@export_range(1,100,1,"suffix:%") var max_chance: int ## 技の最大出現確率
@export var power: int ## 技の基本的な威力 0なら直接的なダメージは発生しない
@export var mp: int ## 技の発動に必要なmp
@export var target: Global.Target ## 技の対象範囲
@export var damage_type: DamageType ## 技の参照するステータスの分類
@export var touch: bool ## 技の接触判定[br][code]true[/code]接触する技[br][code]false[/code]:接触しない技
@export var ability: Array[Ability] ## 技の特殊効果 Ability型のリソース[br]複数登録可能
@export_multiline var description: String ## 技の説明[br]1行につき全角12文字記述可能
