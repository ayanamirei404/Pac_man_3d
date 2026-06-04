extends Control

func _ready() -> void:
	# 初始状态隐藏菜单
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 确保 UI 弹出时鼠标是可见的
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_restart_button_pressed():
	get_tree().paused = false # 取消暂停
	get_tree().reload_current_scene() # 重新加载当前关卡
