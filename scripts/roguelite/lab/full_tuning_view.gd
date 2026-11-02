extends VBoxContainer
## 分页只创建当前20行，避免把几千条属性一次塞进界面。
const Codec = preload("res://scripts/roguelite/lab/tuning_variant.gd")
const PAGE_SIZE: int = 20
var model: RefCounted
var category: OptionButton
var search: LineEdit
var list: VBoxContainer
var count_label: Label
var pager: Label
var page: int = 0
var matches: Array[Dictionary] = []
var status_callback: Callable

func configure(catalog: RefCounted,on_status: Callable) -> void:
	model=catalog
	status_callback=on_status
	custom_minimum_size.y=210
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	var header := HBoxContainer.new()
	category=OptionButton.new()
	category.custom_minimum_size.x=136
	category.add_item("全部分类",0)
	category.set_item_metadata(0,"")
	var groups: Array[String] = []
	for row: Dictionary in model.rows:
		if not groups.has(row.category): groups.append(row.category)
	for group: String in groups:
		category.add_item(group)
		category.set_item_metadata(category.item_count-1,group)
	search=LineEdit.new()
	search.placeholder_text="搜索中文 / 属性名 / 对象"
	search.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	header.add_child(category)
	header.add_child(search)
	add_child(header)
	count_label=Label.new()
	count_label.add_theme_font_size_override("font_size",13)
	add_child(count_label)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y=120
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	list=VBoxContainer.new()
	list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation",9)
	scroll.add_child(list)
	add_child(scroll)
	var footer := HBoxContainer.new()
	for spec: Array in [["上一页",-1],["下一页",1]]:
		var button := Button.new()
		button.text=spec[0]
		button.pressed.connect(func():
			page=clampi(page+int(spec[1]),0,maxi(0,ceili(float(matches.size())/PAGE_SIZE)-1))
			_render()
		)
		footer.add_child(button)
	pager=Label.new()
	footer.add_child(pager)
	var clear := Button.new()
	clear.text="清除重启覆盖"
	clear.pressed.connect(func():
		var directory: String=ProjectSettings.globalize_path("user://") if OS.has_feature("editor") else OS.get_executable_path().get_base_dir()
		var result: Error=model.engine.clear_restart_settings(directory)
		status_callback.call("启动覆盖已清除，重启程序恢复工程原配置" if result==OK else "清除失败："+error_string(result))
	)
	footer.add_child(clear)
	add_child(footer)
	search.text_changed.connect(func(_text: String): _filter())
	category.item_selected.connect(func(_index: int): _filter())
	_filter()

func _filter() -> void:
	page=0
	matches=model.filtered(String(category.get_selected_metadata()),search.text)
	_render()

func _render() -> void:
	for child in list.get_children(): list.remove_child(child); child.queue_free()
	count_label.text="共 %d 项 · 匹配 %d 项 · 即时 / 新生成 / 重启均有标记" % [model.rows.size(),matches.size()]
	pager.text="%d / %d" % [page+1,maxi(1,ceili(float(matches.size())/PAGE_SIZE))]
	for row: Dictionary in matches.slice(page*PAGE_SIZE,(page+1)*PAGE_SIZE): _make_row(row)

func _make_row(row: Dictionary) -> void:
	var container := VBoxContainer.new()
	var heading := HBoxContainer.new()
	var title := Label.new()
	title.text="%s · %s" % [row.target,row.label]
	title.tooltip_text=row.target+" / "+row.name
	title.clip_text=true
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size",16)
	heading.add_child(title)
	var reset := Button.new()
	reset.text="复位"
	reset.disabled=not row.editable
	reset.pressed.connect(func(): model.reset_value(row.id); _render())
	heading.add_child(reset)
	container.add_child(heading)
	var detail := Label.new()
	detail.text=row.name+" · "+(row.effect if row.editable else "对象引用/标识：只读")
	detail.clip_text=true
	detail.tooltip_text=detail.text
	detail.add_theme_font_size_override("font_size",12)
	container.add_child(detail)
	var value: Variant = model.current_value(row.id)
	if row.editable: container.add_child(_editor(row,value))
	else:
		var label := Label.new()
		label.text=str(value).left(100)
		label.clip_text=true
		label.add_theme_font_size_override("font_size",13)
		container.add_child(label)
	list.add_child(container)

func _submit(row: Dictionary,value: Variant) -> bool:
	var ok: bool = model.set_value(row.id,value)
	status_callback.call(("已写入：" if ok else "未应用：类型或范围不合法 · ")+row.target+" / "+row.name+" · "+row.effect)
	return ok

func _editor(row: Dictionary,value: Variant) -> Control:
	if value is bool:
		var check := CheckButton.new()
		check.button_pressed=value
		check.text="开启" if value else "关闭"
		check.toggled.connect(func(enabled: bool): check.text="开启" if enabled else "关闭"; _submit(row,enabled))
		return check
	if value is int and int(row.meta.hint)==PROPERTY_HINT_ENUM:
		var option := OptionButton.new()
		var next: int = 0
		for item: String in String(row.meta.hint_string).split(","):
			var entry: PackedStringArray = item.split(":")
			if entry.size()>1: next=int(entry[-1])
			option.add_item(entry[0],next)
			if next==value: option.select(option.item_count-1)
			next+=1
		option.item_selected.connect(func(index: int): _submit(row,option.get_item_id(index)))
		return option
	if value is String and int(row.meta.hint)==PROPERTY_HINT_ENUM:
		var option := OptionButton.new()
		for choice: String in String(row.meta.hint_string).split(","):
			option.add_item(choice)
			if choice==value: option.select(option.item_count-1)
		option.item_selected.connect(func(index: int): _submit(row,option.get_item_text(index)))
		return option
	if value is float or value is int:
		var spin := SpinBox.new()
		spin.min_value=-1e12
		spin.max_value=1e12
		spin.step=1.0 if value is int else 0.0001
		spin.allow_greater=true
		spin.allow_lesser=true
		spin.value=float(value)
		spin.value_changed.connect(func(number: float):
			if not _submit(row,int(number) if value is int else number): spin.set_value_no_signal(float(model.current_value(row.id)))
		)
		return spin
	if value is Color:
		var color := ColorPickerButton.new()
		color.color=value
		color.custom_minimum_size.y=24
		color.color_changed.connect(func(chosen: Color): _submit(row,chosen))
		return color
	var controls := HBoxContainer.new()
	var text := LineEdit.new()
	text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	text.text=str(value) if value is String or value is StringName or value is NodePath else JSON.stringify(Codec.parts(value))
	text.tooltip_text="向量填数组，矩形填[[x,y],[宽,高]]，数组/字典填JSON；回车或点写入"
	var apply := Button.new()
	apply.text="写入"
	var submit := func():
		var data: Variant = text.text if value is String or value is StringName or value is NodePath else JSON.parse_string(text.text)
		var converted: Variant = Codec.from_parts(data,value)
		_submit(row,converted)
	apply.pressed.connect(submit)
	text.text_submitted.connect(func(_text: String): submit.call())
	controls.add_child(text)
	controls.add_child(apply)
	return controls
