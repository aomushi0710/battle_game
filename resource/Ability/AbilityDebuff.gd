class_name AbilityDebuff
extends Ability
## Abilityの継承クラス。[br]
## 対象のステータスを弱体化するデバフエフェクトを付与します。

enum Status { ## 弱体化されるステータス
	ATK,
	DEF, 
	MAG, 
	RES, 
	SPD
}

enum AmountType { ## 弱体化される効果量の計算式
	減算, ## 元のステータスに減算されます。
	除算, ## 元のステータスに除算されます。
}

@export var status: Status ## 弱体化されるステータス
@export var amount_type: AmountType ## 弱体化される効果量の計算式
@export var amount: float ## 弱体化される効果量[br][br]減算では[param amount]だけ引かれ、除算では[param amount]で割られます。
@export var turn: int ## デバフエフェクトが継続するターン数
