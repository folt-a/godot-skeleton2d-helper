@tool
extends Tree

#signal dropped(path:String)
signal removed(items:Array[TreeItem])

#func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	#return true
#
#func _drop_data(at_position: Vector2, data: Variant) -> void:
	#if data is Dictionary:
		#if data.type == "files":
			#if not data.is_empty() and data.files[0].begins_with("res://"):
				#dropped.emit(data.files[0])

func _enter_tree() -> void:
	if not self.button_clicked.is_connected(_on_button_clicked):
		self.button_clicked.connect(_on_button_clicked)
	if not self.empty_clicked.is_connected(_on_empty_clicked):
		self.empty_clicked.connect(_on_empty_clicked)

func _ready() -> void:
	set_all_itemdata_list([])

func reset():
	set_all_itemdata_list([])

func add_image_rect(index:int,path:String, text:String, rect:Rect2, texture:Texture2D, select:bool = false) -> void:
	add_item({
		"type": "rect",
		"rect": rect,
		"index": index,
		"name": text,
		"path": path
	},
	texture,
	select
	)

func add_dir(dir_name:String) -> void:
	add_item({
		"type": "dir",
		"name": dir_name,
		"children": []
	},
	get_theme_icon("Folder", "EditorIcons")
	)

var is_remove_show:bool = false
func toggle_delete(toggled_on:bool):
	is_remove_show = toggled_on
	if is_remove_show:
		var remove_tex: = get_theme_icon("Remove", "EditorIcons")
		for item in get_all_children():
			item.add_button(0, remove_tex, 0)
	else:
		for item in get_all_children():
			item.erase_button(0, 0)

func get_file_name(_name: String) -> String:
	return _name.split("/")[-1].split(".")[0]

func add_item(data:Dictionary,texture:Texture = null, select:bool = false) -> void:
	var selected_item:= get_selected()
	var item:TreeItem
	if selected_item:
		if selected_item.get_metadata(0) == "dir":
			item = selected_item.create_child()
		else:
			item = selected_item.get_parent().create_child(selected_item.get_index() + 1)
	else:
		var root:TreeItem = get_root()
		item = root.create_child()
	if texture:
		item.set_icon(0, texture)
	if is_remove_show:
		var remove_tex: = get_theme_icon("Remove", "EditorIcons")
		item.add_button(0, remove_tex, 0)
	set_rect_data(item, data)
	if select:
		set_selected(item,0)

func get_all_children() -> Array[TreeItem]:
	var root:= get_root()
	var children:Array[TreeItem] = []
	if !root:return children
	for item in root.get_children():
		set_recursive_item(item, children)
	return children

func get_item_all_children(item:TreeItem) -> Array[TreeItem]:
	var children:Array[TreeItem] = []
	for child in item.get_children():
		set_recursive_item(child, children)
	return children

func get_all_rect_item()  -> Array[TreeItem]:
	var root:= get_root()
	var children:Array[TreeItem] = []
	if !root:return children
	for item in root.get_children():
		set_recursive_item(item, children)
	
	return Array(children.filter(func(i): return i.get_metadata(0) == "rect"),TYPE_OBJECT,&"TreeItem",null) 

func set_recursive_item(parent:TreeItem,children:Array[TreeItem]):
	children.append(parent)
	for item in parent.get_children():
		set_recursive_item(item, children)

func set_all_itemdata_list(data_list:Array) -> void:
	clear()
	var root:TreeItem = create_item()
	
	for data in data_list:
		var item:TreeItem = root.create_child()
		if data.type == "dir":
			item.set_icon(0, get_theme_icon("Folder", "EditorIcons"))
			set_recursive(item, data)
		else:
			item.set_icon(0, get_theme_icon("Image", "EditorIcons"))
			if is_remove_show:
				var remove_tex: = get_theme_icon("Remove", "EditorIcons")
				item.add_button(0, remove_tex, 0)
			set_rect_data(item, data)

func set_recursive(item:TreeItem, data:Dictionary) -> void:
	if item.get_metadata(0) == "dir":
		var children:Array = []
		if item.get_child_count() > 0:
			var dir_item: = item.create_child()
			dir_item.set_icon(0, get_theme_icon("Folder", "EditorIcons"))
			for child_item_data in data.children:
				set_recursive(dir_item, child_item_data)
		var dir:Dictionary = {
			"type": "dir",
			"name": item.get_text(0),
			"children": children
		}
	else:
		return set_rect_data(item, data)

func set_rect_data(item:TreeItem,data:Dictionary) -> void:
	item.set_text(0, data.name)
	item.set_metadata(0, data.type)
	if data.has("path"):
		item.set_meta(&"path", data.path)
	if data.has("rect"):
		item.set_meta(&"rect", data.rect)
	if data.has("index"):
		item.set_meta(&"index", int(data.index))

func get_all_itemdata_list() -> Array:
	var root:TreeItem = get_root()
	if !root:
		return []
	
	var items = []
	for item in root.get_children():
		items.append(get_recursive(item))
	
	return items

func get_recursive(item:TreeItem) -> Variant:
	if item.get_metadata(0) == "dir":
		var children:Array = []
		if item.get_child_count() > 0:
			for child_item in item.get_children():
				children.append(get_recursive(child_item))
		var dir:Dictionary = {
			"type": "dir",
			"name": item.get_text(0),
			"children": children
		}
		return dir
	else:
		return get_rect_data(item)

func get_rect_data(item:TreeItem) -> Dictionary:
	var data:Dictionary = {
		"type": "rect",
		"name": item.get_text(0),
		"path": item.get_meta(&"path"),
		"rect": item.get_meta(&"rect"),
		"index": int(item.get_meta(&"index")),
	}
	return data

func remove_item(item: TreeItem):
	var items:Array[TreeItem] = get_item_all_children(item)
	items.append(item)#自己も追加する
	removed.emit(items)
	item.get_parent().remove_child(item)

func _on_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	if column == 0:
		if id == 0: ## REMOVE
			remove_item(item)

func _on_empty_clicked(click_position: Vector2, mouse_button_index: int):
	deselect_all()
