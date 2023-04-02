#============================================================
#    Priority Test
#============================================================
# - author: zhangxuetu
# - datetime: 2023-03-15 20:44:15
# - version: 4.0
#============================================================
extends Node2D


signal test(a, b, c )



func _ready():
	SignalUtil.connect_array_arg_callable(test, func(params: Array):
		print(params)
	)
	
#	PriorityConnector.connect_signal(self.test, func(a, b, c):
#		print(a, b, c)
#	)
	
	self.test.emit(1, 2, 3)
	

