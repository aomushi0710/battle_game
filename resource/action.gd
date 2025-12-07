class_name Action
extends Resource

@export var data: ActionData ## 技の基データ
@export var unlock_level: int = 1 ## 技の解放レベル
@export var unlock_form: Global.Form = Global.Form.第一形態 ## 技の解放に必要な形態

## 現在の形態[param form]を引数として、その技を利用可能になる形態に達していなければ、
##対応する形態へ進化させる技として変換してからその技を返す関数
func evolution_check(form: Global.Form) -> Action:
	if unlock_form > form:
		var evolution_action := Action.new() ## 進化用として返す技
		# 第二形態(定数:1)に進化するための「進化Ⅰ」(ID:10001),
		# 第三形態(定数:2)に進化するための「進化Ⅱ」(ID:10002)...
		# という関係にあるために全パターンにおいて以下の式は成立する
		evolution_action.data = Global.action_data[10000 + unlock_form]
		return evolution_action
	else:
		return self
