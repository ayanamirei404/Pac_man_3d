extends CharacterBody3D

@onready var camera = $Camera3D
@onready var camera2 = $Camera3D2
@onready var flashlight = $SpotLight3D
# 请确保场景中对应的 ProgressBar 路径正确
@onready var battery_bar = $BatteryBar
@onready var stamina_bar = $StaminaBar # 新增：体力条 UI

# 移动控制引用（手游界面）
var mobile_control: Node = null

# --- 手电筒电量系统变量 ---
@export var max_battery: float = 100.0
@export var drain_rate: float = 2.0
var current_battery: float = 100.0

# --- 体力系统变量 (新增) ---
@export var max_stamina: float = 100.0
@export var stamina_drain: float = 30.0 # 冲刺每秒消耗
@export var stamina_regen: float = 15.0 # 恢复每秒速度
@export var min_stamina_to_sprint: float = 20.0 # 体力耗尽后需恢复到此值才能重新冲刺
var current_stamina: float = 100.0
var was_sprinting: bool = false # 用于跟踪是否正在冲刺中

# --- 相机切换变量 ---
var current_camera: Camera3D

# --- 移动变量 ---
@export var walk_speed: float = 5.0   # 基础行走速度
@export var run_speed: float = 9.0    # 冲刺速度
const JUMP_VELOCITY = 4.5
var mouseSensibility = 1200

# 获取重力设置
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	# 捕捉鼠标
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# 初始化 UI 进度条
	if battery_bar:
		battery_bar.max_value = max_battery
		battery_bar.value = current_battery
	
	if stamina_bar:
		stamina_bar.max_value = max_stamina
		stamina_bar.value = current_stamina

	# 初始化相机
	if camera:
		camera.current = true
		current_camera = camera
	if camera2:
		camera2.current = false

	# 查找移动控制界面（手游）
	# 在场景树中查找 MobileControl 节点
	var mobile_control_node = get_tree().get_root().find_child("MobileControl", true, false)
	if mobile_control_node:
		mobile_control = mobile_control_node
		print("找到移动控制界面")
	else:
		print("未找到移动控制界面，将使用键盘输入")

func _physics_process(delta):
	# 1. 处理重力
	if not is_on_floor(): 
		velocity.y -= gravity * delta 

	# 2. 处理跳跃
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. 处理移动输入
	# 获取键盘输入
	var keyboard_input = Input.get_vector("moveLeft", "moveRight", "moveUp", "moveDown")

	# 获取虚拟摇杆输入
	var joystick_input = Vector2.ZERO
	if mobile_control and mobile_control.has_method("get_joystick_direction"):
		joystick_input = mobile_control.get_joystick_direction()

	# 组合输入：优先使用摇杆，如果有输入的话
	var input_dir = keyboard_input
	if joystick_input.length_squared() > 0.01:  # 如果有摇杆输入
		input_dir = joystick_input

	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized() 
	
	# --- 体力与速度核心逻辑 (新增) ---
	# 冲刺逻辑：按住 Shift 且 正在移动 且 体力>0 且 (体力足够或已在冲刺中)
	var wants_to_sprint = Input.is_action_pressed("shift") and direction != Vector3.ZERO
	var can_sprint = wants_to_sprint and current_stamina > 0 and (current_stamina >= min_stamina_to_sprint or was_sprinting)
	var is_sprinting = can_sprint

	if is_sprinting:
		current_stamina -= stamina_drain * delta
	else:
		current_stamina += stamina_regen * delta
	
	current_stamina = clamp(current_stamina, 0.0, max_stamina)

	# 更新冲刺状态（重要：用于判断是否已在冲刺中）
	was_sprinting = is_sprinting

	# 根据状态决定当前速度
	var current_speed = run_speed if is_sprinting else walk_speed
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

	# --- 手电筒电量逻辑 (保持原样并优化) ---
	if flashlight.visible:
		current_battery -= drain_rate * delta
	else:
		current_battery += (drain_rate * 0.5) * delta
	
	current_battery = clamp(current_battery, 0.0, max_battery)
	
	# 更新所有 UI
	update_ui()
	
	# 没电自动关灯
	if current_battery <= 0:
		flashlight.visible = false

func update_ui():
	# 更新电量条
	if battery_bar:
		battery_bar.value = current_battery
		battery_bar.modulate = Color.RED if current_battery < 25.0 else Color.WHITE
	
	# 更新体力条
	if stamina_bar:
		stamina_bar.value = current_stamina
		# 体力耗尽时变黄提示
		stamina_bar.modulate = Color.YELLOW if current_stamina < 20.0 else Color.CYAN

func _input(event):
	# 处理鼠标转向
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x / mouseSensibility
		camera.rotation.x -= event.relative.y / mouseSensibility
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	# 处理开关灯
	if event.is_action_pressed("toggle_light"):
		if current_battery > 5 or flashlight.visible:
			flashlight.visible = !flashlight.visible
		else:
			print("电量耗尽")

	# 切换相机（按 N 键）
	if event is InputEventKey and event.keycode == KEY_N and event.pressed:
		if current_camera == camera:
			camera.current = false
			camera2.current = true
			current_camera = camera2
		else:
			camera.current = true
			camera2.current = false
			current_camera = camera
		print("切换相机到：", current_camera.name)
