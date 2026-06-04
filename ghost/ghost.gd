extends CharacterBody3D

@export var speed_wander: float = 2.0
@export var speed_chase: float = 6.0
@export var cell_size: float = 2.0
@export var detection_range: float = 8.0
@export var kill_distance: float = 1.5
@export var game_over_scene: PackedScene 

# 状态定义
enum State { WANDER, CHASE, SEARCH }
var current_state = State.WANDER
var last_known_player_pos: Vector3

var target_position: Vector3
var player: CharacterBody3D = null
var has_killed: bool = false

# 这里的节点名称必须和你场景中添加的 AudioStreamPlayer3D 一致
@onready var footstep_audio = $AudioStreamPlayer3D 

func _ready():
	player = get_tree().get_first_node_in_group("player") 
	
	# 初始位置对齐网格
	global_position = Vector3(
		round(global_position.x / cell_size) * cell_size,
		1.2, 
		round(global_position.z / cell_size) * cell_size
	) 
	target_position = global_position
	
	# 启动脚步声
	if footstep_audio:
		footstep_audio.play()

func _physics_process(_delta):
	if has_killed: 
		return

	# 1. 核心 AI 状态切换检测
	_update_ai_state()
	
	# 2. 抓捕检测
	if player and global_position.distance_to(player.global_position) < kill_distance:
		trigger_game_over() 
		return

	# 3. 移动与瞬间转向逻辑
	_perform_movement()

func _update_ai_state():
	if not player: return
	
	var dist = global_position.distance_to(player.global_position)
	if dist < detection_range:
		# 视线检测
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(
			global_position + Vector3(0, 1, 0), 
			player.global_position + Vector3(0, 1, 0)
		)
		query.exclude = [get_rid()]
		var result = space_state.intersect_ray(query) 
		
		if result.is_empty() or result.collider == player:
			current_state = State.CHASE
			last_known_player_pos = player.global_position
			target_position = player.global_position
			return
			
	# 如果正在追逐但失去了视野，进入搜索模式
	if current_state == State.CHASE:
		current_state = State.SEARCH
		target_position = last_known_player_pos
	
	# 如果到达了最后已知位置仍没看到玩家，回到游荡模式
	if current_state == State.SEARCH and global_position.distance_to(last_known_player_pos) < 0.5:
		current_state = State.WANDER

func _perform_movement():
	# 游荡模式下，到达目标点选下一个
	if current_state == State.WANDER and global_position.distance_to(target_position) < 0.2:
		pick_new_target()

	var dir = (target_position - global_position).normalized()
	if dir.length() > 0.01:
		# --- 瞬间转向 (删除了平滑插值) ---
		look_at(Vector3(target_position.x, global_position.y, target_position.z))
		
		# 移动
		var current_speed = speed_chase if current_state == State.CHASE else speed_wander
		velocity = dir * current_speed
		move_and_slide()

func pick_new_target():
	var directions = [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]
	directions.shuffle()
	var space_state = get_world_3d().direct_space_state
	
	for dir in directions:
		var next_point = global_position + dir * cell_size
		var query = PhysicsRayQueryParameters3D.create(
			global_position + Vector3(0, 0.5, 0), 
			next_point + Vector3(0, 0.5, 0)
		)
		query.exclude = [get_rid()]
		var result = space_state.intersect_ray(query) 
		
		if result.is_empty():
			target_position = next_point
			return 

func trigger_game_over():
	if has_killed: return
	has_killed = true
	
	var ui = get_tree().root.find_child("GameOverUI", true, false) 
	if ui:
		ui.visible = true 
		get_tree().paused = true 
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
