class_name AbilityBuff
extends Ability
## Abilityの継承クラス。[br]
## 対象のステータスを増強するバフエフェクトを付与します。

@export var status: Global.Status ## 増強されるステータス
@export var amount: float ## 増強倍率[br]ステータスが[param amount]倍されます。
@export var turn: int ## バフエフェクトが継続するターン数
