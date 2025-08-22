class_name AbilityEffect
extends Ability
## Abilityの継承クラス。[br]
## 対象に状態異常を引き起こします。

enum Effect { ## 状態異常
	なし,
	毒, ## 毎ターン無属性ダメージ
	火傷, ## 毎ターン火属性ダメージ 
	水没, ## 毎ターン水属性ダメージ
	感電, ## 毎ターン雷属性ダメージ
	泥々, ## 毎ターン土属性ダメージ
	竜巻, ## 毎ターン風属性ダメージ
	霜焼, ## 毎ターン氷属性ダメージ
	紫外線, ## 毎ターン光属性ダメージ
	呪い, ## 毎ターン闇属性ダメージ
	睡眠, ## 行動不能
	麻痺, ## 行動不能
	凍結, ## 行動不能
	恐怖, ## 行動不能
}

enum AmountType { ## ダメージを与える際に参照するステータス
	なし, ## いずれのステータスも参照せず、定数ダメージを与えます。
	物理, ## 攻撃側のATKと、守備側のDEFを参照します。
	魔法, ## 攻撃側のMAGと、守備側のRESを参照します。
	割合, ## 相手の最大HPを参照します。
}

@export var effect: Effect ## 状態異常[enum Effect]
@export var amount_type: AmountType ## ダメージを与える際に参照するステータス[enum AmountType]
@export var amount: int ## 与えるダメージ量
@export var turn: int ## 状態異常が継続するターン数


func amount_calc(offense: BattleMonster, defense: BattleMonster) -> int:
	return 0
