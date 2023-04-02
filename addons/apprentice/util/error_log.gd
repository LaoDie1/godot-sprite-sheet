#============================================================
#    Condition Log
#============================================================
# - author: zhangxuetu
# - datetime: 2023-03-10 16:04:50
# - version: 4.x
#============================================================
## 错误日志打印
class_name ErrorLog


static func is_true(expression: bool, message: String) -> void:
	if expression:
		push_error(message)

static func is_false(expression: bool, message: String) -> void:
	if not expression:
		push_error(message)

static func is_null(expression, message: String) -> void:
	if expression == null:
		push_error(message)

static func not_null(expression, message: String) -> void:
	if expression != null:
		push_error(message)

static func is_zero(expression: float, message: String) -> void:
	if expression == 0:
		push_error(message)

