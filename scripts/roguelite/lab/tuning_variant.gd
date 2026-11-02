extends RefCounted
## 参数JSON只承载值，不允许反序列化对象或执行表达式。
static func pack(value: Variant) -> Dictionary:
	return {"type": typeof(value), "data": Marshalls.raw_to_base64(var_to_bytes(value))}

static func unpack(record: Variant) -> Variant:
	if not record is Dictionary or not record.get("data") is String or not record.get("type") is float and not record.get("type") is int:
		return null
	var bytes: PackedByteArray = Marshalls.base64_to_raw(record.data)
	if bytes.is_empty() or bytes.size() > 1048576:
		return null
	var value: Variant = bytes_to_var(bytes)
	return value if typeof(value) == int(record.type) and allowed(value) else null

static func allowed(value: Variant) -> bool:
	if typeof(value) in [TYPE_OBJECT, TYPE_RID, TYPE_CALLABLE, TYPE_SIGNAL, TYPE_NIL]: return false
	if value is float: return not is_nan(value) and not is_inf(value)
	if typeof(value) in [TYPE_VECTOR2,TYPE_VECTOR3,TYPE_VECTOR4,TYPE_COLOR,TYPE_QUATERNION,TYPE_RECT2,TYPE_TRANSFORM2D,TYPE_PLANE,TYPE_AABB,TYPE_BASIS,TYPE_TRANSFORM3D,TYPE_PROJECTION]: return allowed(parts(value))
	if typeof(value)>=TYPE_PACKED_BYTE_ARRAY:
		for item in value:
			if not allowed(item): return false
	if value is Array or value is Dictionary:
		if value is Array and value.is_typed() and value.get_typed_builtin()==TYPE_OBJECT: return false
		for item in value:
			if value is Dictionary:
				if not allowed(value[item]): return false
			elif not allowed(item): return false
	return true

static func parts(value: Variant) -> Variant:
	match typeof(value):
		TYPE_VECTOR2, TYPE_VECTOR2I: return [value.x, value.y]
		TYPE_VECTOR3, TYPE_VECTOR3I: return [value.x, value.y, value.z]
		TYPE_VECTOR4, TYPE_VECTOR4I, TYPE_QUATERNION: return [value.x,value.y,value.z,value.w]
		TYPE_COLOR: return [value.r,value.g,value.b,value.a]
		TYPE_RECT2, TYPE_RECT2I: return [parts(value.position),parts(value.size)]
		TYPE_TRANSFORM2D: return [parts(value.x),parts(value.y),parts(value.origin)]
		TYPE_PLANE: return [parts(value.normal),value.d]
		TYPE_AABB: return [parts(value.position),parts(value.size)]
		TYPE_BASIS: return [parts(value.x),parts(value.y),parts(value.z)]
		TYPE_TRANSFORM3D: return [parts(value.basis),parts(value.origin)]
		TYPE_PROJECTION: return [parts(value.x),parts(value.y),parts(value.z),parts(value.w)]
		TYPE_STRING_NAME, TYPE_NODE_PATH: return str(value)
		TYPE_ARRAY:
			var output: Array = []
			for item in value: output.append(parts(item))
			return output
		TYPE_DICTIONARY:
			var output: Dictionary = {}
			for key in value: output[str(key)] = parts(value[key])
			return output
	if typeof(value) >= TYPE_PACKED_BYTE_ARRAY:
		var output: Array = []
		for item in value: output.append(parts(item))
		return output
	return value

static func from_parts(data: Variant, example: Variant) -> Variant:
	var type: int = typeof(example)
	if not _shape_valid(data,example): return null
	if type in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME, TYPE_NODE_PATH]:
		if type == TYPE_BOOL and not data is bool: return null
		if type in [TYPE_INT,TYPE_FLOAT] and typeof(data) not in [TYPE_FLOAT,TYPE_INT]: return null
		return type_convert(data,type)
	if not data is Array and not data is Dictionary: return null
	var v: Array = data if data is Array else []
	match type:
		TYPE_VECTOR2: return Vector2(v[0],v[1]) if v.size()==2 else null
		TYPE_VECTOR2I: return Vector2i(v[0],v[1]) if v.size()==2 else null
		TYPE_VECTOR3: return Vector3(v[0],v[1],v[2]) if v.size()==3 else null
		TYPE_VECTOR3I: return Vector3i(v[0],v[1],v[2]) if v.size()==3 else null
		TYPE_VECTOR4: return Vector4(v[0],v[1],v[2],v[3]) if v.size()==4 else null
		TYPE_VECTOR4I: return Vector4i(v[0],v[1],v[2],v[3]) if v.size()==4 else null
		TYPE_QUATERNION: return Quaternion(v[0],v[1],v[2],v[3]) if v.size()==4 else null
		TYPE_COLOR: return Color(v[0],v[1],v[2],v[3]) if v.size()==4 else null
		TYPE_RECT2: return Rect2(from_parts(v[0],Vector2.ZERO),from_parts(v[1],Vector2.ZERO)) if v.size()==2 else null
		TYPE_RECT2I: return Rect2i(from_parts(v[0],Vector2i.ZERO),from_parts(v[1],Vector2i.ZERO)) if v.size()==2 else null
		TYPE_TRANSFORM2D: return Transform2D(from_parts(v[0],Vector2.ZERO),from_parts(v[1],Vector2.ZERO),from_parts(v[2],Vector2.ZERO)) if v.size()==3 else null
		TYPE_PLANE: return Plane(from_parts(v[0],Vector3.ZERO),v[1]) if v.size()==2 else null
		TYPE_AABB: return AABB(from_parts(v[0],Vector3.ZERO),from_parts(v[1],Vector3.ZERO)) if v.size()==2 else null
		TYPE_BASIS: return Basis(from_parts(v[0],Vector3.ZERO),from_parts(v[1],Vector3.ZERO),from_parts(v[2],Vector3.ZERO)) if v.size()==3 else null
		TYPE_TRANSFORM3D: return Transform3D(from_parts(v[0],Basis.IDENTITY),from_parts(v[1],Vector3.ZERO)) if v.size()==2 else null
		TYPE_PROJECTION: return Projection(from_parts(v[0],Vector4.ZERO),from_parts(v[1],Vector4.ZERO),from_parts(v[2],Vector4.ZERO),from_parts(v[3],Vector4.ZERO)) if v.size()==4 else null
		TYPE_ARRAY:
			var output: Array = example.duplicate()
			output.clear()
			for item in v:
				var sample: Variant = _element_sample(example)
				var converted: Variant = from_parts(item,sample) if sample!=null else item
				if converted == null: return null
				output.append(converted)
			return output
		TYPE_DICTIONARY: return data
	if type >= TYPE_PACKED_BYTE_ARRAY:
		if type in [TYPE_PACKED_VECTOR2_ARRAY,TYPE_PACKED_VECTOR3_ARRAY,TYPE_PACKED_VECTOR4_ARRAY,TYPE_PACKED_COLOR_ARRAY]:
			var converted: Array = []
			var sample: Variant = Vector2.ZERO if type==TYPE_PACKED_VECTOR2_ARRAY else Vector3.ZERO if type==TYPE_PACKED_VECTOR3_ARRAY else Vector4.ZERO if type==TYPE_PACKED_VECTOR4_ARRAY else Color.WHITE
			for item in v: converted.append(from_parts(item,sample))
			return type_convert(converted,type)
		return type_convert(data,type)
	return null

static func _shape_valid(data: Variant,example: Variant) -> bool:
	var type: int = typeof(example)
	if type in [TYPE_STRING,TYPE_STRING_NAME,TYPE_NODE_PATH]: return data is String
	if type==TYPE_BOOL: return data is bool
	if type in [TYPE_FLOAT,TYPE_INT]: return typeof(data) in [TYPE_FLOAT,TYPE_INT] and allowed(data)
	if type==TYPE_DICTIONARY: return data is Dictionary and allowed(data)
	if not data is Array: return false
	var sample: Variant = parts(example)
	if type==TYPE_ARRAY or type>=TYPE_PACKED_BYTE_ARRAY:
		var element: Variant = _element_sample(example)
		if element==null: return allowed(data)
		for item in data:
			if not _shape_valid(item,element): return false
		return true
	if not sample is Array or data.size()!=sample.size(): return false
	for i in sample.size():
		if sample[i] is Array:
			if not data[i] is Array or JSON.stringify(data[i]).contains('"') or not _numeric_tree(data[i],sample[i]): return false
		elif typeof(data[i]) not in [TYPE_FLOAT,TYPE_INT] or not allowed(data[i]): return false
	return true

static func _element_sample(example: Variant) -> Variant:
	if not example.is_empty(): return example[0]
	var type: int = typeof(example)
	if example is Array:
		if not example.is_typed(): return null
		type=example.get_typed_builtin()
	match type:
		TYPE_BOOL: return false
		TYPE_INT,TYPE_PACKED_BYTE_ARRAY,TYPE_PACKED_INT32_ARRAY,TYPE_PACKED_INT64_ARRAY: return 0
		TYPE_FLOAT,TYPE_PACKED_FLOAT32_ARRAY,TYPE_PACKED_FLOAT64_ARRAY: return 0.0
		TYPE_STRING,TYPE_PACKED_STRING_ARRAY: return ""
		TYPE_STRING_NAME: return &""
		TYPE_NODE_PATH: return NodePath("")
		TYPE_VECTOR2,TYPE_PACKED_VECTOR2_ARRAY: return Vector2.ZERO
		TYPE_VECTOR3,TYPE_PACKED_VECTOR3_ARRAY: return Vector3.ZERO
		TYPE_VECTOR4,TYPE_PACKED_VECTOR4_ARRAY: return Vector4.ZERO
		TYPE_COLOR,TYPE_PACKED_COLOR_ARRAY: return Color.WHITE
	return null

static func _numeric_tree(data: Array,sample: Array) -> bool:
	if data.size()!=sample.size(): return false
	for i in sample.size():
		if sample[i] is Array:
			if not data[i] is Array or not _numeric_tree(data[i],sample[i]): return false
		elif typeof(data[i]) not in [TYPE_INT,TYPE_FLOAT] or not allowed(data[i]): return false
	return true
