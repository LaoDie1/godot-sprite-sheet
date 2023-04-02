#============================================================
#    2d Map
#============================================================
# - datetime: 2023-02-22 17:24:48
#============================================================
## 生成 2D 地图
@tool
extends EditorScript


func _run():
	
	#【通过设置每一步的概率值，进行设置图块】
	
	# 地图大小
	var rect = Rect2i(0,0, 120, 40)
	
	var start = rect.get_center()
	var all = {}
	while true:
		# 概率值，先多一些，然后让他变少，然后又突然增多
		var probability = [0.8, 0.95, 0.65, 0.4, 0.6, 0.15, 0.8]
		# 概率的索引位置
		var idx = {
			value = 0
		}
		# 广度搜索
		var points = MapUtil.breadth_search(start, MathUtil.get_four_directions_i(), 
			func(coord: Vector2i):
				if rect.has_point(coord):
					if randf() <= probability[idx.value % probability.size()]:
						idx.value += 1
						return true
				return false
		)
		for point in points:
			all[point] = null
		
		# 如果数量不够，则继续始执行
		# 随机开始下一个位置，如果要连续，则 start 设置为 points 最后一个位置
#		start = Vector2i(MathUtil.random_position_in_rect2(rect))
		if points.size() > 0:
			start = points.back()
		else:
			start = Vector2i(MathUtil.random_position_in_rect2(rect))
		
		# 数量超过了地图大小的 25% 则退出
		if all.size() >= (rect.size.x * rect.size.y) * 0.25:
			break
	
	# 输出字符串显示
	MathUtil.for_rect_y(rect, func(y):
		var string = [""]
		MathUtil.for_rect_x(rect, func(x):
			if all.has(Vector2i(x, y)):
				string[0] += "#"
			else:
				string[0] += " "
		)
		print(string[0])
	)



func test_generate_2d_map():
	var map_rect = Rect2i(0,0,40,40)
	var data = MapUtil.generate_2d_map(map_rect)
	var text
	for y in range(map_rect.position.y, map_rect.end.y):
		text = ""
		for x in range(map_rect.position.x, map_rect.end.x):
			text += " "
			if data.has(Vector2i(x,y)):
				text += "1"
		print(text)
	
	print( "=".repeat(100) )

