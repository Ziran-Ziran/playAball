extends SkeletonModifier3D
## 将现成动作相对参考帧的旋转微动传给原始骨架，不修改骨长、静止姿态或蒙皮。
## 放在注视、尾巴等修饰器之前；源、目标都使用同向的 +Z 人形空间。

@export_range(0.0, 1.0, 0.01) var motion_strength: float = 0.55
@export_range(0.0, 1.0, 0.01) var shoulder_arm_weight: float = 0.4

var last_head_basis: Basis = Basis.IDENTITY
var max_rotation: float = 0.0
var last_rotation_by_bone: Dictionary = {}
var mapped_bone_count: int = 0

var _source: Skeleton3D
var _baseline_global: Array[Transform3D] = []
var _target_global_rest: Array[Transform3D] = []
var _target_order: Array[int] = []
var _source_indices: Dictionary = {}
var _weights: Dictionary = {}
var _target_count: int = 0


func configure(source_skeleton: Skeleton3D, baseline_global: Array[Transform3D]) -> void:
	_source = source_skeleton
	_baseline_global.assign(baseline_global)
	_target_global_rest.clear()
	_target_order.clear()
	_source_indices.clear()
	_weights.clear()
	last_rotation_by_bone.clear()
	mapped_bone_count = 0
	max_rotation = 0.0
	var target: Skeleton3D = get_skeleton()
	if target == null or not is_instance_valid(_source):
		return
	if _baseline_global.size() != _source.get_bone_count():
		push_warning("动作参考帧与源骨架骨数不一致，未应用加性动作。")
		return
	_target_count = target.get_bone_count()
	for bone_index: int in range(_target_count):
		_target_global_rest.append(target.get_bone_global_rest(bone_index))
	# 原始GLB的骨骼索引并非父先子后，必须按层级遍历。
	for root_index: int in target.get_parentless_bones():
		_append_target_branch(target, root_index)
	var names: Dictionary = {
		"spine": ["Spine", "DEF-spine.001"],
		"chest": ["Chest", "DEF-spine.003", "DEF-spine.002"],
		"neck": ["Neck", "DEF-neck"],
		"head": ["Head", "DEF-head"],
	}
	for target_name: String in names:
		var target_index: int = target.find_bone(target_name)
		if target_index < 0:
			continue
		for source_name: String in names[target_name]:
			var source_index: int = _source.find_bone(source_name)
			if source_index < 0:
				continue
			_source_indices[target_index] = source_index
			_weights[target_index] = shoulder_arm_weight if target_name.begins_with("clavicle") or target_name.begins_with("upper_arm") else 1.0
			break
	mapped_bone_count = _source_indices.size()
	var head_index: int = target.find_bone("head")
	if head_index >= 0:
		last_head_basis = _target_global_rest[head_index].basis.orthonormalized()


func _append_target_branch(target: Skeleton3D, bone_index: int) -> void:
	_target_order.append(bone_index)
	for child_index: int in target.get_bone_children(bone_index):
		_append_target_branch(target, child_index)


func _process_modification_with_delta(_delta: float) -> void:
	var target: Skeleton3D = get_skeleton()
	if target == null or not is_instance_valid(_source) or mapped_bone_count == 0:
		return
	if target.get_bone_count() != _target_count or _source.get_bone_count() != _baseline_global.size():
		return
	var desired_global: Array[Basis] = []
	desired_global.resize(_target_count)
	last_rotation_by_bone.clear()
	for bone_index: int in _target_order:
		var parent_index: int = target.get_bone_parent(bone_index)
		var parent_basis: Basis = Basis.IDENTITY if parent_index < 0 else desired_global[parent_index]
		if not _source_indices.has(bone_index):
			# 原模型手部蒙皮在谈话片段中拉丝；四肢保持输入姿态，随父骨整体运动。
			desired_global[bone_index] = parent_basis * target.get_bone_pose(bone_index).basis.orthonormalized()
			continue
		var source_index: int = int(_source_indices[bone_index])
		var baseline_basis: Basis = _baseline_global[source_index].basis.orthonormalized()
		var source_basis: Basis = _source.get_bone_global_pose(source_index).basis.orthonormalized()
		var motion_delta: Quaternion = (source_basis * baseline_basis.inverse()).get_rotation_quaternion().normalized()
		# 四元数q和-q是同一旋转；选短弧，避免跨过符号边界时绕大圈。
		if motion_delta.w < 0.0:
			motion_delta = -motion_delta
		var amount: float = clampf(motion_strength * float(_weights[bone_index]), 0.0, 1.0)
		var blended_delta: Quaternion = Quaternion.IDENTITY.slerp(motion_delta, amount).normalized()
		# 基础绑定只验证小幅动作；限制现成谈话片段的极值，避免牵扯融合发束或袖口。
		var bone_name: String = target.get_bone_name(bone_index)
		var limit: float = deg_to_rad(18.0 if bone_name.begins_with("forearm") else 8.0)
		var blended_angle: float = Quaternion.IDENTITY.angle_to(blended_delta)
		if blended_angle > limit:
			blended_delta = Quaternion.IDENTITY.slerp(blended_delta, limit / blended_angle).normalized()
		var global_basis: Basis = Basis(blended_delta) * _target_global_rest[bone_index].basis.orthonormalized()
		var local_basis: Basis = parent_basis.inverse() * global_basis
		target.set_bone_pose_rotation(bone_index, local_basis.get_rotation_quaternion().normalized())
		desired_global[bone_index] = global_basis
		var angle: float = Quaternion.IDENTITY.angle_to(blended_delta)
		max_rotation = maxf(max_rotation, angle)
		last_rotation_by_bone[target.get_bone_name(bone_index)] = angle
		if target.get_bone_name(bone_index) == "head":
			last_head_basis = global_basis
