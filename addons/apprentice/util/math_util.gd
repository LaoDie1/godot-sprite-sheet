#============================================================
#    Math Util
#============================================================
# - datetime: 2022-12-21 22:53:39
#============================================================
## 数学工具
class_name MathUtil


const INT_MAX : int = 2 ^ 63 - 1  #0x7FFFFFFFFFFFFFFF
const INT_MIN : int = -2 ^ 63 
const FLOAT_MAX : float = 1.79769e308
const FLOAT_MIN : float = -1.79769e308
const VECTOR2_MAX : Vector2 = Vector2.INF
const VECTOR2I_MAX : Vector2i = Vector2i(INT_MAX, INT_MAX)


static func distance_to(from: Vector2, to: Vector2) -> float:
	return from.distance_to(to)

static func distance_squared_to(from: Vector2, to: Vector2) -> float:
	return from.distance_squared_to(to)

static func direction_to(from: Vector2, to: Vector2) -> Vector2:
	return from.direction_to(to)

static func angle_to_point(from: Vector2, to: Vector2) -> float:
	return from.angle_to_point(to)

##  反弹
##[br]
##[br][code]velocity[/code]  移动向量或移动方向
##[br][code]from[/code]  当前对象的位置
##[br][code]to[/code]  撞到的目标位置
static func bounce_to( velocity: Vector2, from: Vector2, to: Vector2 ):
	var dir = direction_to(from, to)
	return velocity.bounce(dir)

static func get_four_directions_i() -> Array[Vector2i]:
	return [Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN]

static func get_eight_directions_i() -> Array[Vector2i]:
	return [Vector2i.LEFT, Vector2i(-1, -1), Vector2i.UP, Vector2i(1, -1), Vector2i.RIGHT, Vector2i(1, 1), Vector2i.DOWN, Vector2(-1, 1)]

static func get_four_directions() -> Array[Vector2]:
	return [Vector2.LEFT, Vector2.UP, Vector2.RIGHT, Vector2.DOWN]

static func get_eight_directions() -> Array[Vector2]:
	return [Vector2.LEFT, Vector2(-1, -1), Vector2.UP, Vector2(1, -1), Vector2.RIGHT, Vector2(1, 1), Vector2.DOWN, Vector2(-1, 1)]

static func is_rect_edge(coord: Vector2, rect: Rect2, margin: float = 0) -> bool:
	return (
		coord.x == rect.position.x + margin 
		or coord.y == rect.position.y - 1 - margin
		or coord.x == rect.end.x - margin
		or coord.y == rect.end.y-1 + margin
	)

static func is_in_rect( coord: Vector2, rect: Rect2 ) -> bool:
	return rect.has_point(coord)


static func diff_length(velocity: Vector2, diff_length_value: float) -> Vector2:
	return velocity.limit_length(velocity.length() - diff_length_value)


class N:
	
	static func diff_position(from: Node2D, to: Node2D) -> Vector2:
		return to.global_position - from.global_position
	
	static func distance_to(from: Node2D, to: Node2D) -> float:
		return from.global_position.distance_to(to.global_position)

	static func direction_to(from: Node2D, to: Node2D) -> Vector2:
		return from.global_position.direction_to(to.global_position)

	static func angle_to(from: Node2D, to: Node2D) -> float:
		return from.global_position.angle_to(to.global_position)

	static func angle_to_point(from: Node2D, to: Node2D) -> float:
		return from.global_position.angle_to_point(to.global_position)
	
	static func direction_x(from: Node2D, to: Node2D) -> Vector2:
		return Vector2(to.global_position.x - from.global_position.x, 0)
	
	static func direction_y(from: Node2D, to: Node2D) -> Vector2:
		return Vector2(0, to.global_position.y - from.global_position.y)
	
	static func distance_x(from: Node2D, to: Node2D) -> float:
		return abs(from.global_position.x - to.global_position.x)
	
	static func distance_y(from: Node2D, to: Node2D) -> float:
		return abs(from.global_position.y - to.global_position.y)
	
	static func distance_v(from: Node2D, to: Node2D) -> Vector2:
		return (from.global_position - to.global_position).abs()
	
	static func is_in_distance(from: Node2D, to: Node2D, max_distance: float) -> bool:
		return from.global_position.distance_squared_to(to.global_position) <= pow(max_distance, 2)
	
	static func bounce_to( velocity: Vector2, from: Node2D, to: Node2D ):
		var dir = direction_to(from, to)
		return velocity.bounce(dir)
	
	##  移动后的向量
	##[br]
	##[br][code]target[/code]  目标节点
	##[br][code]vector[/code]  移动向量值
	##[br][code]return[/code]  返回移动后的位置
	static func move(target: Node2D, velocity: Vector2) -> Vector2:
		return target.global_position + velocity


## 在距离之内
static func is_in_distance(from: Vector2, to: Vector2, max_distance: float) -> bool:
	return from.distance_squared_to(to) <= pow(max_distance, 2)


##  返回对应概率的值
##[br]
##[br][code]value_list[/code]  值列表
##[br][code]probability_list[/code]  概率列表
static func random_probability(value_list : Array, probability_list: Array):
	
	# 两个列表的值的个数应相同
	if value_list.size() != probability_list.size():
		print("值列表和概率列表元素数量不一致")
		return null
	
	# 累加概率值，计算概率总和
	# 每次累加存到列表中作为概率区间
	var sum = 0.0
	var p_list = []	# 概率列表
	for i in probability_list:
		sum += i
		p_list.push_back(sum)
	
	# 产生一个 [0, 概率总和) 之间的随机值
	# 概率区间越大的值，则随机到的概率越大
	# 则就实现了每个值的随机值
	var r = randf() * sum
	var idx = 0
	for p in p_list:
		# 当前概率超过或等于随机的概率，则返回
		if p >= r:
			return value_list[idx]
		idx += 1
	
	return null


class _RandomVector2:
	# 原始位置
	var _origin: Vector2
	
	func _init(origin_pos: Vector2 = Vector2(0,0)):
		self._origin = origin_pos
	
	## 随机方向。from 开始角度，to 结束角度
	func random_direction(from: float = -PI, to: float = PI) -> Vector2:
		return Vector2.LEFT.rotated( randf_range(from, to) )
	
	## 随机位置。
	## max_distance 随机的最大距离，min_distance 最小随机距离，
	## from_angle 开始角度，to_angle 到达角度
	func random_position(max_distance: float, min_distance: float = 0.0, from_angle: float = -PI, to_angle: float = PI) -> Vector2:
		return _origin + random_direction(from_angle, to_angle) * randf_range(min_distance, max_distance)
	
	## 矩形内随机位置
	func random_in_rect(rect: Rect2) -> Vector2:
		var x = randf_range( rect.position.x, rect.end.x )
		var y = randf_range( rect.position.y, rect.end.y )
		return _origin + Vector2(x, y)


## 随机 Vector2 值
static func random_vector2(origin_pos: Vector2 = Vector2(0,0)) -> _RandomVector2:
	return _RandomVector2.new(origin_pos)


## 位运算 - 存在于
static func bit_contain(number: int, is_in: int) -> bool:
	return (number & is_in) == number

## 位运算 - 相加
static func bit_add(list: Array) -> int:
	var v = 0
	for i in list:
		v |= i
	return v


## 遍历 Rect X 轴
static func for_rect_x(rect: Rect2, callable: Callable) -> void:
	for x in range(rect.position.x, rect.end.x):
		callable.call(x)

## 遍历 Rect Y 轴
static func for_rect_y(rect: Rect2, callable: Callable) -> void:
	for y in range(rect.position.y, rect.end.y):
		callable.call(y)

static func random_position_in_rect2(rect: Rect2) -> Vector2:
	var x = randf_range( rect.position.x, rect.end.x )
	var y = randf_range( rect.position.y, rect.end.y )
	return Vector2(x, y)

