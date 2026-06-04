extends CanvasLayer

# 信号：发送摇杆输入方向
signal joystick_moved(direction: Vector2)
signal joystick_released

# 摇杆节点引用
@onready var joystick = $Joystick
@onready var background = $Joystick/Background
@onready var thumb = $Joystick/Background/Thumb

# 摇杆参数
@export var max_distance: float = 50.0  # 拇指最大移动距离
var is_dragging: bool = false
var joystick_center: Vector2
var current_direction: Vector2 = Vector2.ZERO

func _ready():
	# 初始化摇杆中心位置
	joystick_center = background.global_position + background.size * 0.5
	# 设置触摸区域大小
	joystick.custom_minimum_size = Vector2(100, 100)

	# 如果没有纹理，使用颜色可视化
	if background.texture == null:
		background.modulate = Color(1, 1, 1, 0.3)
	if thumb.texture == null:
		thumb.modulate = Color(1, 1, 1, 0.6)

func _input(event):
	# 处理触摸输入
	if event is InputEventScreenTouch:
		var touch_pos = event.position
		var is_in_joystick_area = joystick.get_global_rect().has_point(touch_pos)

		if event.pressed and is_in_joystick_area:
			# 触摸开始且在摇杆区域内
			is_dragging = true
			update_joystick(touch_pos)
		elif not event.pressed and is_dragging:
			# 触摸结束且正在拖拽
			is_dragging = false
			reset_joystick()

	elif event is InputEventScreenDrag and is_dragging:
		# 拖拽摇杆
		update_joystick(event.position)

func update_joystick(touch_position: Vector2):
	# 计算相对方向
	var relative = touch_position - joystick_center
	var distance = relative.length()

	# 限制拇指移动范围
	if distance > max_distance:
		relative = relative.normalized() * max_distance
		distance = max_distance

	# 更新拇指位置
	thumb.position = relative - thumb.size * 0.5

	# 计算归一化方向（-1 到 1）
	var direction = Vector2.ZERO
	if distance > 10.0:  # 死区阈值
		direction = relative.normalized()
		direction *= (distance / max_distance)  # 根据距离调整强度

	# 更新当前方向并发射信号
	if direction != current_direction:
		current_direction = direction
		joystick_moved.emit(direction)

func reset_joystick():
	# 重置摇杆位置
	thumb.position = -thumb.size * 0.5
	current_direction = Vector2.ZERO
	joystick_released.emit()
	joystick_moved.emit(Vector2.ZERO)

# 获取当前摇杆方向（供其他脚本调用）
func get_joystick_direction() -> Vector2:
	return current_direction

# 检查是否正在使用摇杆
func is_joystick_active() -> bool:
	return is_dragging