class_name AbilityFumble
extends Ability
## Abilityの継承クラス。[br]
## 対象に与えるダメージを減少させます。

enum AmountType { ## ダメージ増加量の計算式
	減算, ## 元のダメージに減算されます。
	除算, ## 元のダメージに除算されます。
}

@export var amount_type: AmountType ## ダメージ増加量の計算式
@export var amount: float ## ダメージ増加量[br][br]減算では[param amount]だけ引かれ、除算では[param amount]で割られます。
