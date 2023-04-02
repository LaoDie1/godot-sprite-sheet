# editor_script_00.gd
@tool
extends EditorScript


func _run():
	pass
	
	
	var rc = RandomMinimumProbability.new(0.3)
	
	
	var m = 0
	for i in 10:
		if rc.check():
			m += 1
	
	print(m)
	

