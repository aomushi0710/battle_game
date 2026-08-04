class_name AbilityCritical
extends Ability
## Abilityの継承クラス。[br]
## 対象に与えるダメージを増加させます。

enum AmountType { ## ダメージ増加量の計算式
	加算, ## 元のダメージに加算されます。
	乗算, ## 元のダメージに乗算されます。
}

@export var amount_type: AmountType ## ダメージ増加量の計算式
@export var amount: float ## ダメージ増加量[br][br]加算では[param amount]だけ足され、乗算では[param amount]で掛けられます。
