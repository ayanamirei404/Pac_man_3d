extends Node3D

#@header("资源配置")
@export var wall_scene: PackedScene
@export var floor_scene: PackedScene
@export var player_scene: PackedScene
# 1. 新增：鬼魂场景插座
@export var ghost_scene: PackedScene 

#@header("迷宫参数")
@export var width: int = 21  # 建议奇数
@export var height: int = 21 # 建议奇数
@export var cell_size: float = 2.0

#@header("游戏元素配置")
# 2. 新增：随机生成的鬼魂数量
@export_range(1, 50) var ghost_count: int = 4
# 3. 新增：额外通路数量
@export_range(0, 100) var extra_paths: int = 10

# 内部数据
var grid = []
# 3. 新增：记录所有地面空位的列表
var available_ground_positions: Array[Vector2i] = []

func _ready():
	randomize()

	# 重置空地列表，防止编辑器下反复运行累积
	available_ground_positions = []

	# 1. 生成逻辑数据
	generate_maze_data()

	# 1.5 新增：添加额外通路
	add_extra_paths()

	# 2. 渲染 3D 实体 (并收集空地)
	create_3d_world()

	# 3. 放置玩家
	spawn_player()

	# 4. 新增：生成鬼魂
	spawn_ghosts()

## --- 核心算法部分 ---
func generate_maze_data():
	grid = []
	for x in range(width):
		grid.append([])
		for y in range(height):
			grid[x].append(0)

	var stack = []
	var start_cell = Vector2i(1, 1)
	grid[1][1] = 1 
	stack.push_back(start_cell)

	while stack.size() > 0:
		var current = stack[-1]
		var neighbors = get_unvisited_neighbors(current)

		if neighbors.size() > 0:
			var next = neighbors.pick_random()
			var mid_wall = current + (next - current) / 2
			grid[mid_wall.x][mid_wall.y] = 1
			grid[next.x][next.y] = 1
			stack.push_back(next)
		else:
			stack.pop_back()

func get_unvisited_neighbors(p: Vector2i):
	var n = []
	var directions = [Vector2i(0, 2), Vector2i(0, -2), Vector2i(2, 0), Vector2i(-2, 0)]
	for d in directions:
		var target = p + d
		if target.x > 0 and target.x < width - 1 and target.y > 0 and target.y < height - 1:
			if grid[target.x][target.y] == 0:
				n.append(target)
	return n

## --- 额外通路生成部分 ---
func add_extra_paths():
	if extra_paths <= 0:
		return

	var possible_walls: Array[Vector2i] = []

	# 收集所有内墙位置（排除边界）
	for x in range(1, width - 1):
		for y in range(1, height - 1):
			# 只选择当前是墙的位置
			if grid[x][y] == 0:
				possible_walls.append(Vector2i(x, y))

	if possible_walls.size() == 0:
		return

	# 打乱墙列表
	possible_walls.shuffle()

	# 确定实际要打通的数量
	var actual_extra = min(extra_paths, possible_walls.size())

	# 打通选中的墙
	for i in range(actual_extra):
		var wall_pos = possible_walls[i]
		grid[wall_pos.x][wall_pos.y] = 1
		print("额外通路打通于: ", wall_pos)

## --- 3D 实例化部分 ---
func create_3d_world():
	for x in range(width):
		for z in range(height):
			# 铺设地板
			var f = floor_scene.instantiate()
			add_child(f)
			f.position = Vector3(x * cell_size, -0.1, z * cell_size)
			
			if grid[x][z] == 0:
				# 生成墙体
				var w = wall_scene.instantiate()
				add_child(w)
				w.position = Vector3(x * cell_size, 1.0, z * cell_size)
			else:
				# 4. 新增：如果是路，保存这个坐标，用于生成鬼魂/道具
				# (1,1) 是玩家出生点，可以考虑排除
				if x == 1 and z == 1:
					continue
				available_ground_positions.append(Vector2i(x, z))

## --- 实体生成部分 ---
func spawn_player():
	if player_scene:
		var player = player_scene.instantiate()
		add_child(player)
		# 初始位置设在 (1, 1)
		player.position = Vector3(1 * cell_size, 1.5, 1 * cell_size)
	else:
		push_warning("未关联 Player 场景，无法生成玩家。")

# 5. 新增：鬼魂生成函数
func spawn_ghosts():
	if not ghost_scene:
		push_warning("未关联 Ghost 场景，无法生成鬼魂。")
		return

	if available_ground_positions.size() == 0:
		push_warning("没有可用的空地来生成鬼魂。")
		return

	# 确保请求的鬼魂数量不超过实际空地数量
	var actual_count = min(ghost_count, available_ground_positions.size())
	
	# 这里使用一个克隆列表，防止随机抽取时修改原列表影响其他逻辑
	var spawn_pool = available_ground_positions.duplicate()
	spawn_pool.shuffle() # 随机打乱

	for i in range(actual_count):
		# 从打乱后的列表中弹出最后一个，确保不重复选择同一个格子
		var grid_pos = spawn_pool.pop_back()
		
		var ghost = ghost_scene.instantiate()
		add_child(ghost)
		
		# 设置 3D 位置
		ghost.position = Vector3(
			grid_pos.x * cell_size,
			1.2, # 鬼魂稍微悬空一点
			grid_pos.y * cell_size
		)
		
		# 随机旋转一下鬼魂，看起来自然点
		ghost.rotate_y(randf_range(0, TAU)) 
		
		print("鬼魂 ", i+1, " 生成于 grid 坐标: ", grid_pos)
