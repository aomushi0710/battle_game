class_name AbilityDebuff
extends Ability
## Abilityの継承クラス。[br]
## 対象のステータスを弱体化するデバフエフェクトを付与します。

@export var status: Global.Status ## 弱体化されるステータス
@export var amount: float ## 弱体化倍率[br]ステータスが1/[param amount]倍されます。
@export var turn: int ## デバフエフェクトが継続するターン数
