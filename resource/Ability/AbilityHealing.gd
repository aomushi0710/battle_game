class_name AbilityHealing
extends Ability
## Abilityの継承クラス。[br]
## 対象のHP, MP, SPDゲージを回復させます

enum Status { ## 回復されるステータス
	HP,
	MP,  
	SPD
}

enum AmountType { ## 参照するステータス及び計算式
	定数, ## いずれのステータスも参照せず、定数を使用します。
	現在ゲージ割合, ## [b]自分[/b]の現在ゲージ量に対しての割合を参照します。
	最大ゲージ割合, ## [b]自分[/b]の最大ゲージ量に対しての割合を参照します。
	現在ゲージ割合_対象, ## [b]対象[/b]の現在ゲージ量に対しての割合を参照します。
	最大ゲージ割合_対象, ## [b]対象[/b]の最大ゲージ量に対しての割合を参照します。
	吸収, ## 与えたダメージに対しての割合を参照します。
	ATK, ## ATKを参照します。
	DEF, ## DEFを参照します。
	MAG, ## MAGを参照します。
	RES, ## RESを参照します。
}

@export var status: Status ## 回復されるステータス
@export var amount_type: AmountType ## 参照するステータス及び計算式
## 回復量[br][br]
## [code]定数[/code]では[param amount]だけ回復され、[br]
## [code]現在ゲージ割合[/code], [code]吸収[/code]などでは[param amount]が1なら100%, 0.5なら50%の割合で回復します。[br]
## [code]ATK[/code], [code]DEF[/code]などのステータス参照の場合は[param amount]倍したステータスの値だけ回復します。
@export var amount: float
