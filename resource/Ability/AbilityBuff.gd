class_name AbilityBuff
extends Ability
## Abilityの継承クラス。[br]
## 対象のステータスを増強するバフエフェクトを付与します。

enum Status { ## 増強されるステータス
	ATK,
	DEF, 
	MAG, 
	RES, 
	SPD
}

enum AmountType { ## 増強される効果量の計算式
	加算, ## 元のステータスに加算されます。
	乗算, ## 元のステータスに乗算されます。
}

@export var status: Status ## 増強されるステータス
@export var amount_type: AmountType ## 増強される効果量の計算式
@export var amount: float ## 増強される効果量[br][br]加算では[param amount]だけ足され、乗算では[param amount]で掛けられます。
@export var turn: int ## バフエフェクトが継続するターン数
