extends Control

func _ready() -> void:
	# 初始状态隐藏菜单
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	# 监听取消键（默认为 ESC）
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	# 切换可见性
	visible = !visible
	# 核心：切换游戏的暂停状态
	get_tree().paused = visible
	
	# 处理鼠标状态
	if visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# 连接到“继续游戏”按钮的信号
func _on_continue_button_pressed() -> void:
	toggle_pause()

# 连接到“退出”按钮的信号
func _on_quit_button_pressed() -> void:
	get_tree().paused = false # 退出前记得解除暂停，否则主菜单可能卡死
	get_tree().quit()
 
# 连接到“重启”按钮的信号
func _on_restart_pressed() -> void:
	get_tree().paused = false # 退出前记得解除暂停，否则主菜单可能卡死
	get_tree().reload_current_scene() # 重新加载当前关卡	
