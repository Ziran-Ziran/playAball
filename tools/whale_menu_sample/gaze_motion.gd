extends SkeletonModifier3D
## 在真实骨骼上叠加有限角度注视，独立于身体动作播放。

@export_range(0.0, 30.0) var yaw_limit_degrees: float = 22.0
@export_range(0.0, 20.0) var pitch_limit_degrees: float = 12.0
@export_range(1.0, 20.0) var follow_speed: float = 5.0
var target: Vector2 = Vector2.ZERO
var gaze: Vector2 = Vector2.ZERO
var reaction: float = 0.0
var reduced_motion: bool = false
var last_head_basis: Basis = Basis.IDENTITY
var last_yaw: float = 0.0
var phase: float = 0.0

func _process_modification_with_delta(delta: float) -> void:
	var skeleton: Skeleton3D = get_skeleton()
	if skeleton == null:
		return
	phase += minf(delta, 0.05)
	gaze = gaze.lerp(target, 1.0 - exp(-follow_speed * minf(delta, 0.05)))
	var yaw: float = deg_to_rad(yaw_limit_degrees) * gaze.x
	var pitch: float = deg_to_rad(pitch_limit_degrees) * gaze.y
	if reduced_motion:
		yaw *= 0.35
		pitch *= 0.35
	var nod: float = sin(reaction * TAU) * sin(reaction * PI) * 0.12
	_rotate_global(skeleton, "neck", Basis(Vector3.UP, yaw * 0.25) * Basis(Vector3.RIGHT, pitch * 0.2))
	_rotate_global(skeleton, "head", Basis(Vector3.UP, yaw * 0.75) * Basis(Vector3.RIGHT, pitch * 0.8 + nod))
	if not reduced_motion:
		for index in 3:
			var name: String = "tail.%02d" % (index + 1)
			_rotate_global(skeleton, name, Basis(Vector3.UP, sin(phase * 0.9 - index * 0.65) * 0.025))
	var head: int = skeleton.find_bone("head")
	if head >= 0:
		last_head_basis = skeleton.get_bone_global_pose(head).basis.orthonormalized()
		last_yaw = atan2(last_head_basis.z.x, last_head_basis.z.z)

func _rotate_global(skeleton: Skeleton3D, bone_name: String, rotation: Basis) -> void:
	var bone: int = skeleton.find_bone(bone_name)
	if bone < 0:
		return
	var pose: Transform3D = skeleton.get_bone_global_pose(bone)
	var parent: int = skeleton.get_bone_parent(bone)
	var parent_basis: Basis = Basis.IDENTITY
	if parent >= 0:
		parent_basis = skeleton.get_bone_global_pose(parent).basis.orthonormalized()
	var local_basis: Basis = parent_basis.inverse() * rotation * pose.basis.orthonormalized()
	skeleton.set_bone_pose_rotation(bone, local_basis.orthonormalized().get_rotation_quaternion())
