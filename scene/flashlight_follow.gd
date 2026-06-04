extends SpotLight3D # 如果是模型，就继承 Node3D

@onready var camera = $/root/main_scene/MazeGenerator/PLAYER3D/Camera3D # 根据你的实际路径修改，确保能找到相机
@export var follow_speed: float = 5.0

func _process(delta: float) -> void:
	if camera:
		# 1. 瞬间同步位置（手电筒在手心里，位置必须死死跟住）
		global_position = camera.global_position
		
		# 2. 平滑同步旋转（这就是那种“手持感”的关键）
		var target_quat = camera.global_transform.basis.get_rotation_quaternion()
		var current_quat = global_transform.basis.get_rotation_quaternion()
		
		# 使用 slerp 实现球面线性插值，让转动不僵硬
		global_transform.basis = Basis(current_quat.slerp(target_quat, delta * follow_speed))
