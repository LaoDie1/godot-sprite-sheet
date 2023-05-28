#============================================================
#    Tree
#============================================================
# - author: zhangxuetu
# - datetime: 2023-03-31 08:34:04
# - version: 4.0
#============================================================
@tool
extends Tree


signal dragged(item: TreeItem, data_ref: Dictionary)


func _get_drag_data(at_position):
	var item = get_selected()
	if item:
		var data = {
			"data": null
		}
		self.dragged.emit(item, data)
		return data
	return null

