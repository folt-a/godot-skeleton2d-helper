@tool
extends MarginContainer

@export var tab_container:TabContainer
@export var character: VBoxContainer

var SAVE_PATH:String:
	get:
		return "res://skeleton2dhelper_save.txt"

var selected_tab:int = 0
const TAB_INDEX_CLOSED:int = 0
const TAB_INDEX_CHARACTER:int = 1

@export var tr_controls:Array[Control]
@export var update_tr_controls:bool:
	set(v):
		update_tr_controls = false
		if v:
			tr_controls = []
			for n in get_all_children(self):
				if n.name.ends_with("Ig"): continue
				if n is Label or n is Button or n is TextureRect:
					tr_controls.append(n)

@export_category("Character")
@export var character_tab_container: TabContainer
@export var refresh_character_button: Button
@export var bone_list_tree: Tree
@export var selecting_bone_label: Label
@export var selecting_rename_line_edit: LineEdit
@export var selecting_bone_texture_rect: TextureRect
@export var selecting_bone_name_label: Label
@export var bone_buttons_label: Label
@export var bone_buttons: Array[BaseButton]
@export var add_bone_button: Button
@export var add_bone_from_head_button: Button
@export var move_bone_sentan_button: Button
@export var move_bone_head_button: Button
@export var bone_move_snap_option_button: OptionButton

@export var near_select_button: Button
@export var sprite_near_select_button: Button

@export var selecting_sprite_name_label: Label
@export var selecting_sprite_texture_rect: TextureRect
@export var sprite_selecting_rename_line_edit: LineEdit


@export var selecting_animation_player_texture_rect: TextureRect
@export var selecting_animation_player_label: Label
@export var insert_key_frame_button: Button
@export var insert_key_frame_with_children_button: Button

const FileDropTree = preload("res://addons/godot-skeleton2d-helper/file_drop_tree.gd")
@export var image_tree: FileDropTree

@export var image_texture_rect: TextureRect
@export var image_cursor_sprite_2d: Sprite2D

@export var image_atlas_position_x_spin_box: SpinBox
@export var image_atlas_position_y_spin_box: SpinBox
@export var image_atlas_size_width_spin_box: SpinBox
@export var image_atlas_size_height_spin_box: SpinBox

@export var image_pivot_x_spin_box: SpinBox
@export var image_pivot_y_spin_box: SpinBox

@export var image_padding_spin_box: SpinBox

@export var color_rect: ColorRect
@export var color_picker_button: ColorPickerButton
@export var image_snap_option_button: OptionButton
@export var image_cursor_option_button_ig: OptionButton
const ImageRectDropTree = preload("res://addons/godot-skeleton2d-helper/image_rect_drop_tree.gd")
@export var image_rect_item_tree: ImageRectDropTree
@export var zoom_value_label_ig: Label
@export var image_zoom_h_slider: HSlider
@export var image_name_line_edit: LineEdit

@export var image_mode_option_button: OptionButton

@export var sprite_visible_button: Button

@export var polygon_points: Node2D
@export var polygon_menu_h_box_container: HBoxContainer

@export var add_outer_polygon_point_button: Button
@export var move_outer_polygon_point_button: Button
@export var remove_outer_polygon_point_button: Button

@export var add_inner_polygon_point_button: Button
@export var move_inner_polygon_point_button: Button
@export var remove_inner_polygon_point_button: Button

@export var polygon_parent_icon_texture_rect: TextureRect
@export var polygon_parent_label_ig: Label

@onready var file_dialog: FileDialog = %FileDialog
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var canvas_center_container: CenterContainer = %CanvasCenterContainer
@onready var canvas_margin_container: MarginContainer = %CanvasMarginContainer
@onready var zoom_auto_check_box: CheckBox = %ZoomAutoCheckBox

@onready var image_text_input_h_box_container: HBoxContainer = %ImageTextInputHBoxContainer
@onready var image_text_input_line_edit: LineEdit = %ImageTextInputLineEdit

## ※Editorのコントロールにアクセスしている。
var __AnimationPlayerEditor:Control = null

var bone_list:Array[Bone2D] = []
var sprite_list:Array[CanvasItem] = []
#:Dictionary[String imagepath, Array[{display_name:String,size:Vector2,position:Vector2,outer_points:Array[Vector2],inner_points:Array[Vector2]}] polygon_data
var sprite_polygon_data_list:Dictionary = {}

var current_image_path:String = ""

var current_editing_bone:Bone2D = null
var current_editing_bone_children:Array[Bone2D] = []
var lock_current_editing_bone:bool = false

var bone_move_snap_mode:int = SNAP_MODE_PIXEL

var current_editing_sprite:CanvasItem = null
var lock_current_editing_sprite:bool = false

var current_animation_player:AnimationPlayer = null
var current_polygon_parent:Node = null

var bone_before_move_angle_length:Vector2 = Vector2.ZERO

var current_state:int = STATE_NONE
var before_pos:Vector2 = Vector2.ZERO
var before_mouse_pos:Vector2 = Vector2.ZERO

var image_current_texture: Texture2D

var image_current_polygons: Array[PackedVector2Array] = []

var image_current_index: int = -1

var image_current_scale: float = 4.0
var image_padding: int = 1

var image_snap_mode:int = SNAP_MODE_PIXEL
const SNAP_MODE_NONE:int = 0
const SNAP_MODE_PIXEL:int = 1
const SNAP_MODE_HALF_PIXEL:int = 2

var image_mode:int = 0
const IMAGE_MODE_SPRITE:int = 0
const IMAGE_MODE_POLYGON:int = 1

var polygon_mode:int = 0
const POLYGON_MODE_OUTER_ADD:int = 0
const POLYGON_MODE_OUTER_MOVE:int = 1
const POLYGON_MODE_OUTER_INTERNAL_ADD = 2
const POLYGON_MODE_OUTER_REMOVE:int = 3
const POLYGON_MODE_INNER_ADD:int = 4
const POLYGON_MODE_INNER_MOVE:int = 5
const POLYGON_MODE_INNER_REMOVE:int = 6

const STATE_NONE:int = -1
const STATE_BONE_SENTAN_MOVE:int = 1
const STATE_BONE_HEAD_MOVE:int = 2

var IsThisAddonEditing:bool = false

var selection:EditorSelection
var viewport_2d:Viewport
var main_screen:Control
var scene_root:Node

var undo_redo:EditorUndoRedoManager

func _save(filepath:String):
	var uid:int = ResourceLoader.get_resource_uid(filepath)
	var uid_path:String = ResourceUID.get_id_path(uid)
	
	var save_data:Dictionary = {}
	
	var image_tree_datalist:Array[Dictionary] = []
	var root:TreeItem = image_tree.get_root()
	if root:
		save_data["image_tree_datalist"] = image_tree.get_all_itemdata_list()
	
	save_data["sprite_polygon_data_list"] = sprite_polygon_data_list
	
	var file: = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))

func load_all_data():
	if not FileAccess.file_exists(SAVE_PATH):
		var fileinit: = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		fileinit.store_string("{
			\"image_tree_datalist\" : [],
			\"sprite_polygon_data_list\" : {},
		}")
		fileinit.close()
	
	var file: = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var jsonstr:String = file.get_as_text()
	
	var save_data:Dictionary = JSON.parse_string(jsonstr)
	
	image_tree.clear()
	var image_paths:Array[String] = []
	var index:int = 0
	if save_data.has("image_tree_datalist"):
		image_tree.set_all_itemdata_list(save_data["image_tree_datalist"])
	
	if save_data.has("sprite_polygon_data_list"):
		sprite_polygon_data_list = save_data["sprite_polygon_data_list"]
	else:
		sprite_polygon_data_list = {}

var locale:String
const locale_ja_dic:Dictionary = {
	":":":",
	"Character":"キャラクター",
	"Skeleton2D Helper":"Skeleton2D Helper",
	"Select":"選択",
	"Confirm":"確定",
	"Select Bone":"ボーン選択",
	"Near Select":"ゆる選択",
	"Rename":"名前の変更",
	"Selecting":"選択中",
	"Select Parent":"親を選択",
	"Select Child":"子を選択",
	"Select Next":"次を選択",
	"Select All":"すべて選択",
	"Bone":"ボーン",
	"Bone Tools":"ボーン操作",
	"Add Bone":"追加",
	"Add Bone from Tail":"先端から追加",
	"Add Bone from Head":"頭から追加",
	"Move Bone Tail":"先端を移動",
	"Move Bone Head": "頭を移動",
	"None":"なし",
	
	"Animation":"アニメーション",
	"Insert KeyFrame":"キー",
	"Insert KeyFrame With Children": "キー 子含む",
	
	"parent must be Skeleton2D or Bone2D.": "親はSkeleton2DかBone2Dである必要があります。",
	
	"Select Sprite":"スプライト選択",
	
	"Sprite2D":"Sprite2D",
	"Polygon2D":"Polygon2D",
	"Set Origin": "原点を設定",
	"Edit Polygon": "ポリゴンを編集",
	
	"Loaded Image List": "読み込んだ画像リスト",
	
	"Image":"画像",
	"Add Image Or DnD":"追加 (ドロップ可)",
	"Origin Position": "原点の位置",
	"Snap": "スナップ",
	"BgColor": "背景色",
	"Pixel": "ピクセル",
	"Half Pixel": "半ピクセル",
	"Zoom": "ズーム",
	"Atlas": "Altas",
	"Position": "位置",
	"Size": "サイズ",
	"Padding": "Padding",
	"Width": "幅",
	"Height": "高さ",
	"Atlases": "画像パーツ",
	
	"Add ViewerNode": "ポリゴン確認用ノードを追加",
	
	"Point": "原点",
	"Add Sprite2D To Selected Node Child": "選択中のBoneの子としてSprite2Dを追加",
	"Add Polygon2D To Selected Node Child Position": "選択中のBoneの位置へPolygon2Dを追加",
	"To": "親ノード",
	
	"Outer" : "外周点",
	"Inner" : "内部点",
}
const locale_ko_dic:Dictionary = {
	":":":",
	"Character":"キャラクター",
	"Select":"選択",
	"Near Select":"ゆる選択",
	"Rename":"名前の変更",
	"Selecting":"選択中",
	"Select Parent":"親を選択",
	"Select Child":"子を選択",
	"Select Next":"次を選択",
	"Bone":"ボーン",
	"Bone Tools":"ボーン操作",
	"Add Bone from Tail":"先端から追加",
	"Add Bone from Head":"頭から追加",
	"Move Bone Tail":"先端を移動",
	"Move Bone Head": "頭を移動",
	"None":"なし",
	
	"parent must be Skeleton2D or Bone2D.": "親はSkeleton2DかBone2Dである必要があります。"
}

func _init() -> void:
	locale =  EditorInterface.get_editor_settings().get_setting("interface/editor/editor_language")
	locale = "ja"
func _tr(s:String) -> String:
	if s == "": return s
	if locale == "ja":
		if not locale_ja_dic.has(s):
			printerr("Translation JA: [" + s + "] is missing")
			return s
		return locale_ja_dic[s]
	elif locale == "ko":
		if not locale_ko_dic.has(s):
			printerr("Translation EN: [" + s + "] is missing")
			return s
		return locale_ko_dic[s]
	else:
		return s

func _enter_tree() -> void:
	for n in get_all_children(EditorInterface.get_base_control()):
		if n.name.begins_with("@AnimationPlayerEditor"):
			__AnimationPlayerEditor = n
			break
	main_screen = EditorInterface.get_editor_main_screen()

func _ready() -> void:
	var root:Node = EditorInterface.get_edited_scene_root()
	if root == null:return
	if root.get_script() == get_script():
		IsThisAddonEditing = true
		return
	
	tab_container.set_tab_title(TAB_INDEX_CLOSED,"")
	tab_container.set_tab_icon(TAB_INDEX_CLOSED,get_theme_icon("GuiOptionArrow", "EditorIcons"))
	
	tab_container.set_tab_title(TAB_INDEX_CHARACTER,_tr(" "))
	tab_container.set_tab_icon(TAB_INDEX_CHARACTER, get_theme_icon("Skeleton2D", "EditorIcons"))
	
	refresh_character_button.text = ""
	
	_set_short_cuts(move_bone_head_button, KEY_A, false, false, false)
	_set_short_cuts(move_bone_sentan_button, KEY_A, true, true, false)
	
	_set_short_cuts(insert_key_frame_button, KEY_I, true, false, true)
	_set_short_cuts(insert_key_frame_with_children_button, KEY_W, true, false, false)
	
	_set_short_cuts(add_bone_button, KEY_A, false, false, true)
	#_set_short_cuts(add_bone_from_head_button, KEY_S, false, false, true)
	
	
	_set_short_cuts(near_select_button, KEY_X, false, false, false)
	_set_short_cuts(sprite_near_select_button, KEY_C, false, false, false)
	
	image_mode_option_button.clear()
	image_mode_option_button.add_item(_tr("Set Origin"))
	image_mode_option_button.set_item_icon(0, get_theme_icon("EditorPathSharpHandle", "EditorIcons"))
	image_mode_option_button.add_item(_tr("Edit Polygon"))
	image_mode_option_button.set_item_icon(1, get_theme_icon("Polygon2D", "EditorIcons"))
	image_mode_option_button.select(0)
	
	image_snap_option_button.clear()
	image_snap_option_button.add_item(_tr("None"))
	image_snap_option_button.add_item(_tr("Pixel"))
	image_snap_option_button.add_item(_tr("Half Pixel"))
	image_snap_option_button.select(SNAP_MODE_PIXEL)
	
	
	bone_move_snap_option_button.clear()
	bone_move_snap_option_button.add_item(_tr("None"))
	bone_move_snap_option_button.add_item(_tr("Pixel"))
	bone_move_snap_option_button.add_item(_tr("Half Pixel"))
	bone_move_snap_option_button.select(SNAP_MODE_PIXEL)
	
	image_texture_rect.resized.connect(func():
		_set_image_rect_index.call_deferred(image_current_index)
		)
	
	if not polygon_points.changed.is_connected(_on_polygon_changed):
		polygon_points.changed.connect(_on_polygon_changed)
	
	image_cursor_sprite_2d.texture =  get_theme_icon("EditorPathSharpHandle", "EditorIcons")
	
	image_cursor_option_button_ig.clear()
	image_cursor_option_button_ig.add_icon_item(get_theme_icon("EditorPathSharpHandle", "EditorIcons")," ")
	var pixel_image:Image = Image.create(1,1,false,Image.FORMAT_RGB8)
	pixel_image.fill(Color.RED)
	image_cursor_option_button_ig.add_icon_item(ImageTexture.create_from_image(pixel_image)," ")
	image_cursor_option_button_ig.select(0)
	
	image_zoom_h_slider.set_value_no_signal(image_current_scale)
	_on_image_zoom_h_slider_value_changed(image_current_scale)
	
	set_scroll_default.call_deferred()
	
	for n in tr_controls:
		if n is Button:
			if n.editor_description != "":
				n.icon = get_theme_icon(n.editor_description, "EditorIcons")
		if n is TextureRect:
			if n.editor_description != "":
				n.texture = get_theme_icon(n.editor_description, "EditorIcons")
		elif n.text != "":
			if not n.has_meta(&"orgtext"):
				n.set_meta(&"orgtext", n.text)
			if n is Button and n.shortcut != null:
				n.text = _tr(n.get_meta(&"orgtext")) + "(" + n.shortcut.get_as_text() + ")"
			else:
				n.text = _tr(n.get_meta(&"orgtext"))

func set_scroll_default(offset:Vector2 = Vector2.ZERO):
	scroll_container.set_deferred(&"scroll_horizontal",(canvas_center_container.size.x / 2.0) + offset.x)
	scroll_container.set_deferred(&"scroll_vertical",(canvas_center_container.size.y / 2.0) + offset.y)

func _set_short_cuts(btn:Button, keycode:Key, is_alt:bool, ctrl_pressed:bool, shift_pressed:bool):
	btn.shortcut = Shortcut.new()
	btn.shortcut.events = []
	var event := InputEventKey.new()
	event.keycode = keycode
	event.alt_pressed = is_alt
	event.ctrl_pressed = ctrl_pressed
	event.shift_pressed = shift_pressed
	btn.shortcut.events.append(event)

func _on_visibility_changed() -> void:
	var root:Node = EditorInterface.get_edited_scene_root()
	if root == null:return
	if root.get_script() == get_script():
		IsThisAddonEditing = true
		return
	IsThisAddonEditing = false
	selection = EditorInterface.get_selection()
	if visible:
		if not selection.selection_changed.is_connected(_on_selection_changed):
			selection.selection_changed.connect(_on_selection_changed)
		_on_selection_changed()
	else:
		if selection.selection_changed.is_connected(_on_selection_changed):
			selection.selection_changed.disconnect(_on_selection_changed)

func _on_tab_container_tab_changed(tab: int) -> void:
	if IsThisAddonEditing:return
	selected_tab = tab
	#await get_tree().create_timer(0.1).timeout
	get_parent().size = Vector2.ZERO
	get_parent().reset_size()

#func _draw() -> void:
	#if current_editing_bone:
		#var pos_1 = current_editing_bone.global_position
		#var pos_2 = current_editing_bone.global_position + _get_bone_sentan_local_pos(current_editing_bone)
		#var rect:Rect2
		## 2点間のRectを取得
		#if pos_1.x < pos_2.x:
			#rect.position.x = pos_1.x
			#rect.size.x = pos_2.x - pos_1.x
		#else:
			#rect.position.x = pos_2.x
			#rect.size.x = pos_1.x - pos_2.x
		#if pos_1.y < pos_2.y:
			#rect.position.y = pos_1.y
			#rect.size.y = pos_2.y - pos_1.y
		#else:
			#rect.position.y = pos_2.y
			#rect.size.y = pos_1.y - pos_2.y
		#
		#viewport_2d = EditorInterface.get_editor_viewport_2d()
		#print(viewport_2d.global_canvas_transform.get_scale())
		#
		#$Node2D.global_position = Vector2.ZERO
		#rect.position = (rect.position * viewport_2d.global_canvas_transform.get_scale()) + viewport_2d.global_canvas_transform.origin + main_screen.global_position - global_position
		##$Node2D.global_position = rect.position
		#draw_rect(rect, Color(1, 0, 0, 0.5))

func _get_first_canvas_item():
	if scene_root is CanvasItem:
		return viewport_2d.global_canvas_transform.origin

func _on_selection_changed():
	match selected_tab:
		TAB_INDEX_CHARACTER:
			
			var selected = _get_select_bone()
			if selected is Bone2D:
				if lock_current_editing_bone:return
				current_editing_bone = selected
				
				if _is_invalid_bone_root(selected):
					selecting_bone_name_label.text = selected.name + _tr("parent must be Skeleton2D or Bone2D.")
					return
				elif _is_bone_root(selected):
					# ボタンの有効切り替え
					move_bone_sentan_button.disabled = true
					move_bone_head_button.disabled = false
					
				elif _is_bone_matubi(selected):
					move_bone_sentan_button.disabled = false
					move_bone_head_button.disabled = false
				else:
					move_bone_sentan_button.disabled = true
					move_bone_head_button.disabled = false
				selecting_bone_name_label.text = selected.name
				selecting_rename_line_edit.text = selected.name
			
				if current_animation_player == null:
					insert_key_frame_button.disabled = true
					insert_key_frame_with_children_button.disabled = true
				else:
					insert_key_frame_button.disabled = false
					insert_key_frame_with_children_button.disabled = false
			#
			#else:
				##move_bone_sentan_button.disabled = true
				##move_bone_head_button.disabled = true
				##
				##insert_key_frame_button.disabled = true
				##insert_key_frame_with_children_button.disabled = true
				#
				#if selected:
					#selecting_bone_name_label.text = selected.name
					#selecting_bone_name_label.tooltip_text = selected.name
				return
			selected = _get_select_sprite()
			if selected is Sprite2D or selected is Polygon2D:
				if lock_current_editing_sprite:return
				current_editing_sprite = selected
				if current_editing_sprite.visible:
					sprite_visible_button.icon = get_theme_icon("GuiVisibilityVisible", "EditorIcons")
				else:
					sprite_visible_button.icon = get_theme_icon("GuiVisibilityHidden", "EditorIcons")
					
				selecting_sprite_name_label.text = selected.name
				sprite_selecting_rename_line_edit.text = selected.name


func _on_scene_changed(root:Node):
	scene_root = root
	update_bone_list_items()
	fill_animation_player()
	#load_scene_data(root.get_scene_file_path())

func _on_scene_saved(filepath:String):
	_save(filepath)

func _process(delta: float) -> void:
	if IsThisAddonEditing:return
	match current_state:
		STATE_BONE_SENTAN_MOVE:
			_bone_move_process()
		STATE_BONE_HEAD_MOVE:
			_bone_move_head_process()

func _input(event: InputEvent) -> void:
	if IsThisAddonEditing:return
	match current_state:
		STATE_NONE:
			_none_input(event)
		STATE_BONE_SENTAN_MOVE:
			_bone_move_input(event)
		STATE_BONE_HEAD_MOVE:
			_bone_move_head_input(event)

func change_state(state:int):
	exit_state(current_state)
	enter_state(state)
	await get_tree().process_frame
	current_state = state

func enter_state(state:int):
	match state:
		STATE_BONE_SENTAN_MOVE:
			_bone_move_entered()
		STATE_BONE_HEAD_MOVE:
			_bone_move_head_entered()
		

func exit_state(state:int):
	match state:
		STATE_BONE_SENTAN_MOVE:
			_bone_move_exited()
		STATE_BONE_HEAD_MOVE:
			_bone_move_head_exited()

## Character

func _none_input(event: InputEvent) -> void:
	pass

func _on_visible_toggle_character_button_toggled(toggled_on: bool) -> void:
	character.visible = toggled_on
	if toggled_on:
		pass
	else:
		pass

func _on_refresh_character_button_pressed() -> void:
	refresh()

func refresh():
	_ready()
	_on_visibility_changed()
	_on_scene_changed(EditorInterface.get_edited_scene_root())
	selection = EditorInterface.get_selection()

##
## BONELIST
##
func update_bone_list_items() -> void:
	bone_list_tree.clear()
	var root_item:TreeItem = bone_list_tree.create_item()
	bone_list = []
	sprite_list = []
	if not is_instance_valid(scene_root):return
	if not scene_root.is_inside_tree():return
	for n in get_all_children(scene_root):
		if n is Skeleton2D:
			var skeleton_item:TreeItem = root_item.create_child()
			skeleton_item.set_icon(0, get_theme_icon("Skeleton2D", "EditorIcons"))
			skeleton_item.set_text(0, n.name)
			skeleton_item.set_metadata(0, NodePath(""))
			var parent_item:TreeItem = skeleton_item
			for b in n.get_children():
				if b is Bone2D:
					create_bone_list_tree_item_recursive(b, parent_item)
		elif n is Sprite2D or n is Polygon2D:
			sprite_list.append(n)
	for n in bone_list:
		if not _is_bone_matubi(n):
			n.set_length(1.0)
			n.set_bone_angle(0.0)
	

func _on_bone_list_tree_item_selected() -> void:
	selection.clear()
	var item = bone_list_tree.get_selected()
	if item.get_metadata(0) == NodePath(""):
		return
	var bone_node:Node =  scene_root.get_node(item.get_metadata(0))
	selection.add_node(bone_node)
	_on_selection_changed()

func _on_bone_list_tree_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	selection.clear()
	var bone_node:Node =  scene_root.get_node(item.get_metadata(0))
	selection.add_node(bone_node)
	_on_selection_changed()

func get_all_children(in_node:Node) -> Array[Node]:
	if in_node == null:return []
	var children = in_node.get_children()
	var ary:Array[Node] = []
	while not children.is_empty():
		var node = children.pop_back()
		children.append_array(node.get_children())
		ary.append(node)
	ary.reverse()
	return ary

func create_bone_list_tree_item_recursive(bone_node:Bone2D,parent_item:TreeItem):
	var new_item:TreeItem = parent_item.create_child()
	new_item.set_icon(0, get_theme_icon("Bone2D", "EditorIcons"))
	new_item.set_text(0, bone_node.name)
	new_item.set_metadata(0, scene_root.get_path_to(bone_node))
	#new_item.set_button(0,0,get_theme_icon("ToolSelect", "EditorIcons"))
	new_item.add_button(0, get_theme_icon("ToolSelect", "EditorIcons"),0,false,str(scene_root.get_path_to(bone_node)))
	bone_list.append(bone_node)
	
	for b in bone_node.get_children():
		if b is Bone2D:
			create_bone_list_tree_item_recursive(b, new_item)


##
## SELECT
##
func _on_selecting_rename_line_edit_text_submitted(new_text: String) -> void:
	current_editing_bone.name = new_text
	selecting_bone_name_label.text = current_editing_bone.name
	selecting_rename_line_edit.text = current_editing_bone.name
	
	# Animationのリネームも必要

func _on_selecting_lock_toggle_button_toggled(toggled_on: bool) -> void:
	lock_current_editing_bone = toggled_on

func _on_select_parent_button_pressed() -> void:
	if current_editing_bone is Bone2D and current_editing_bone.is_inside_tree():
		if current_editing_bone.get_parent() != null:
			selection.clear()
			selection.add_node(current_editing_bone.get_parent())
			_on_selection_changed()

func _on_select_child_button_pressed() -> void:
	if current_editing_bone is Bone2D and current_editing_bone.is_inside_tree():
		if current_editing_bone.get_child_count() > 0:
			selection.clear()
			selection.add_node(current_editing_bone.get_child(0))
			_on_selection_changed()

func _on_select_next_button_pressed() -> void:
	if current_editing_bone is Bone2D and current_editing_bone.is_inside_tree():
		if current_editing_bone.get_parent() != null:
			var pa:= current_editing_bone.get_parent()
			var boneonly_children:Array[Bone2D] = []
			var index:int = 0
			var current_index:int = 0
			for n in pa.get_children():
				if n is Bone2D:
					boneonly_children.append(n)
				if n == current_editing_bone:
					current_index = index
				index = index + 1
			var count:int = boneonly_children.size()
			if count == 1:return
			
			var next:int = (current_index + 1) % count
			selection.clear()
			selection.add_node(boneonly_children[next])
			_on_selection_changed()

func _on_select_all_button_pressed() -> void:
	selection.clear()
	
	for n in get_all_children(_get_current_skeleton()):
		if n is Bone2D:
			selection.add_node(n)
	
	_on_selection_changed()

##
## ADD
##
func _on_add_bone_button_pressed() -> void:
	var new_bone := Bone2D.new()
	var is_not_shortcut := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	viewport_2d = EditorInterface.get_editor_viewport_2d()
	
	var pos:Vector2
	var length:float = 1
	var angle:float = 0
	
	if is_not_shortcut or not viewport_2d:
		length = 1.0
		angle = current_editing_bone.get_bone_angle()
		pos = _get_bone_sentan_local_pos(current_editing_bone)
	elif _is_bone_matubi(current_editing_bone):
		var mouse_pos := _get_mouse_position()
		length = _get_bone_sentan_length(pos, current_editing_bone.to_local(mouse_pos))
		angle = _get_bone_sentan_angle(pos, current_editing_bone.to_local(mouse_pos))
		pos = current_editing_bone.to_local(mouse_pos)
		#_get_bone_sentan_local_pos(current_editing_bone)
	elif current_editing_bone.get_child_count() > 0:
		var mouse_pos := _get_mouse_position()
		pos = current_editing_bone.to_local(mouse_pos)
		length = _get_bone_sentan_length(current_editing_bone.global_position, mouse_pos)
		angle = _get_bone_sentan_angle(current_editing_bone.global_position, mouse_pos)
	else:
		printerr("bone is not parent!")
	pos = _get_bone_move_snapped_point(pos)
	undo_redo.create_action("Add Bone")
	undo_redo.add_do_method(self, "_add_bone", current_editing_bone, new_bone, pos, length, angle, true)
	undo_redo.add_undo_method(self, "_remove_bone", new_bone)
	undo_redo.commit_action()


func _add_bone(bone:Bone2D, new_bone:Bone2D, pos:Vector2, length:int, angle:float,is_auto:bool):
	new_bone.name = "Bone"
	new_bone.set_autocalculate_length_and_angle(false)
	bone.set_autocalculate_length_and_angle(false)
	bone.add_child(new_bone, true)
	
	new_bone.position = pos
	new_bone.set_length(length)
	new_bone.set_bone_angle(angle)
	new_bone.owner = scene_root
	selection.clear()
	selection.add_node(new_bone)
	_on_selection_changed()
	update_bone_list_items()

func _remove_bone(bone:Bone2D):
	if selection.get_selected_nodes().has(bone):
		selection.clear()
		selection.remove_node(bone)
		if selection.get_selected_nodes().is_empty() and bone.get_parent() != null:
			_set_bone_sentan(bone.get_parent(), bone.global_position)
			bone.get_parent().set_autocalculate_length_and_angle(false)
			selection.add_node(bone.get_parent())
			_on_selection_changed()
	bone.get_parent().remove_child(bone)
	update_bone_list_items()

#func _on_add_bone_from_head_button_pressed() -> void:
	#var new_bone := Bone2D.new()
	#var is_not_shortcut := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	#viewport_2d = EditorInterface.get_editor_viewport_2d()
	#
	#var pos:Vector2 = Vector2.ZERO
	#var length:float = 1
	#var angle:float = 0
	#
	#if _is_bone_matubi(current_editing_bone):
		#if is_not_shortcut or not viewport_2d:
			#length = 1.0
			#angle = 0.0
		#else:
			#var mouse_pos := _get_mouse_position()
			#length = _get_bone_sentan_length(pos, current_editing_bone.to_local(mouse_pos))
			#angle = _get_bone_sentan_angle(pos, current_editing_bone.to_local(mouse_pos))
	#else:
		#
		#pass
	#
	#
	#undo_redo.create_action("Add Bone")
	#undo_redo.add_do_method(self, "_add_bone", current_editing_bone, new_bone, is_not_shortcut, pos, length, angle, false)
	#undo_redo.add_undo_method(self, "_remove_bone", new_bone)
	#undo_redo.commit_action()

##
## MOVE
##
func _on_move_bone_sentan_button_pressed() -> void:
	change_state(STATE_BONE_SENTAN_MOVE)

func _bone_move_entered() -> void:
	EditorInterface.set_main_screen_editor("2D")
	selection.clear()
	selection.add_node(current_editing_bone)
	_on_selection_changed()
	var localpos:Vector2 = _get_bone_sentan_local_pos(current_editing_bone)
	bone_before_move_angle_length = Vector2(current_editing_bone.get_bone_angle(), current_editing_bone.get_length())
	before_pos = current_editing_bone.global_position + localpos
	before_mouse_pos = _get_mouse_position()

func _bone_move_exited() -> void:
	await get_tree().process_frame
	selection.clear()
	selection.add_node(current_editing_bone)
	_on_selection_changed()

func _bone_move_process() -> void:
	var mouse_pos := before_pos + _get_mouse_position() - before_mouse_pos
	mouse_pos = _get_bone_move_snapped_point(mouse_pos)
	_set_bone_sentan(current_editing_bone, mouse_pos)

func _bone_move_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_RIGHT:
				# キャンセル
				_move_bone_sentan(current_editing_bone, before_pos)
			else:
				# 確定
				var mouse_pos := before_pos + _get_mouse_position() - before_mouse_pos
				mouse_pos = _get_bone_move_snapped_point(mouse_pos)
				undo_redo.create_action("Move Bone Tail")
				undo_redo.add_do_method(self, "_move_bone_sentan", current_editing_bone, mouse_pos)
				undo_redo.add_undo_method(self, "_move_bone_sentan_angle_length", current_editing_bone, bone_before_move_angle_length.x, bone_before_move_angle_length.y)
				undo_redo.commit_action()
				
				var anim_player:AnimationPlayer = scene_root.get_node_or_null("%AnimationPlayer")
				#if anim_player != null:
					#print(anim_player.current_animation)
					#print(anim_player.current_animation_length)
					#print(anim_player.current_animation_position)
				
			change_state(STATE_NONE)

func _move_bone_sentan(bone:Bone2D,to_global_pos:Vector2) -> void:
	_set_bone_sentan(bone, to_global_pos)

func _move_bone_sentan_angle_length(bone:Bone2D, angle:float, length:float) -> void:
	bone.set_bone_angle(angle)
	bone.set_length(length)

##
## MOVE BONE HEAD
##

func _on_move_bone_button_pressed() -> void:
	change_state(STATE_BONE_HEAD_MOVE)

func _bone_move_head_entered() -> void:
	EditorInterface.set_main_screen_editor("2D")
	selection.clear()
	selection.add_node(current_editing_bone)
	_on_selection_changed()
	current_editing_bone_children = _get_bone_children(current_editing_bone)
	bone_before_move_angle_length = Vector2(current_editing_bone.get_bone_angle(), current_editing_bone.get_length())
	if _is_bone_matubi(current_editing_bone):
		before_pos = current_editing_bone.global_position + _get_bone_sentan_local_pos(current_editing_bone)
		current_editing_bone.set_meta(&"before_pos", current_editing_bone.global_position)
	else:
		before_pos = current_editing_bone.global_position
	before_mouse_pos = _get_mouse_position()
	for bone in current_editing_bone_children:
		bone.set_meta(&"before_pos", bone.global_position)

func _bone_move_head_exited() -> void:
	await get_tree().process_frame
	selection.clear()
	selection.add_node(current_editing_bone)
	_on_selection_changed()

func _bone_move_head_process() -> void:
	if _is_bone_matubi(current_editing_bone):
		current_editing_bone.global_position = current_editing_bone.get_meta(&"before_pos") + _get_mouse_position() - before_mouse_pos
		current_editing_bone.global_position = _get_bone_move_snapped_point(current_editing_bone.global_position)
		_set_bone_sentan(current_editing_bone, before_pos)
	else:
		current_editing_bone.global_position = before_pos + _get_mouse_position() - before_mouse_pos
		current_editing_bone.global_position = _get_bone_move_snapped_point(current_editing_bone.global_position)
		for bone in current_editing_bone_children:
			bone.global_position = bone.get_meta(&"before_pos")
		pass
	pass

func _bone_move_head_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_RIGHT:
				# キャンセル
				if _is_bone_matubi(current_editing_bone):
					_move_bone_head_matubi(current_editing_bone,current_editing_bone.get_meta(&"before_pos"),before_pos)
				else:
					var children:= current_editing_bone_children.duplicate()
					var child_positions:= Array(children.map(func(i): return i.get_meta(&"before_pos")),TYPE_VECTOR2,&"",null)
					_move_bone_head(current_editing_bone,before_pos,children,child_positions)
			else:
				# 確定
				if _is_bone_matubi(current_editing_bone):
					var mouse_pos :Vector2 = current_editing_bone.get_meta(&"before_pos") + _get_mouse_position() - before_mouse_pos
					mouse_pos = _get_bone_move_snapped_point(mouse_pos)
					undo_redo.create_action("Move Bone Head(Last Child)")
					undo_redo.add_do_method(self, "_move_bone_head_matubi", current_editing_bone, mouse_pos, before_pos)
					undo_redo.add_undo_method(self, "_move_bone_head_matubi", current_editing_bone, current_editing_bone.get_meta(&"before_pos"), before_pos)
				else:
					var mouse_pos := before_pos + _get_mouse_position() - before_mouse_pos
					mouse_pos = _get_bone_move_snapped_point(mouse_pos)
					var children:= current_editing_bone_children.duplicate()
					var child_positions:= Array(children.map(func(i): return i.get_meta(&"before_pos")),TYPE_VECTOR2,&"",null)
					undo_redo.create_action("Move Bone Head")
					undo_redo.add_do_method(self, "_move_bone_head", current_editing_bone, mouse_pos, children, child_positions)
					undo_redo.add_undo_method(self, "_move_bone_head", current_editing_bone, before_pos, children, child_positions)
				undo_redo.commit_action()
			
			change_state(STATE_NONE)

func _move_bone_head(bone:Bone2D,to_global_pos:Vector2,children:Array[Bone2D], child_positions:Array[Vector2]) -> void:
	bone.global_position = to_global_pos
	var index:int = 0
	for bone_c in children:
		bone_c.global_position = child_positions[index]
		index = index + 1

func _move_bone_head_matubi(bone:Bone2D,to_global_pos:Vector2,sentan_global_pos:Vector2) -> void:
	bone.global_position = to_global_pos
	_move_bone_sentan(bone, sentan_global_pos)

##
## INSERT KEYFRAME
##

func fill_animation_player() -> void:
	for n in get_all_children(scene_root):
		if n is AnimationPlayer:
			update_animation_player(n)
			return
	update_animation_player(null)

func update_animation_player(anim_p:AnimationPlayer) -> void:
	if anim_p != null:
		current_animation_player = anim_p
		selecting_animation_player_label.text = anim_p.name
		selecting_animation_player_texture_rect.texture = get_theme_icon("AnimationPlayer", "EditorIcons")
		insert_key_frame_button.disabled = false
		insert_key_frame_with_children_button.disabled = false
	else:
		current_animation_player = null
		selecting_animation_player_label.text = ""
		selecting_animation_player_texture_rect.texture = get_theme_icon("Info", "EditorIcons")
		insert_key_frame_button.disabled = true
		insert_key_frame_with_children_button.disabled = true
	if current_editing_bone == null:
		insert_key_frame_button.disabled = true
		insert_key_frame_with_children_button.disabled = true

func _on_select_animation_player_button_pressed() -> void:
	EditorInterface.popup_node_selector(_on_animation_player_selected, ["AnimationPlayer"])

func _on_animation_player_selected(node_path):
	if node_path.is_empty():
		pass
	elif scene_root.get_node(node_path):
		update_animation_player(scene_root.get_node(node_path))
	else:
		update_animation_player(null)

func _on_insert_key_frame_button_pressed() -> void:
	if current_editing_bone == null:
		printerr("Bone is null")
		return
	
	var current_animation:StringName = &""
	var animation_time:float = 0.0
	
	# EditorのControlから適当に取得
	# ※エディタ更新で動かなくなる可能性あり。
	var header:HBoxContainer = __AnimationPlayerEditor.get_child(0)
	for n in get_all_children(header):
		if n is SpinBox:
			animation_time= n.value
		if n is OptionButton:
			current_animation = n.get_item_text(n.selected)
			break
	
	var animation:Animation = current_animation_player.get_animation(current_animation)
	if animation == null:
		printerr("Animation is null")
		printerr("current_animation: " + current_animation)
		return
	var animation_root:Node = current_animation_player.get_node(current_animation_player.root_node)
	var root_to_path:String = animation_root.get_path_to(current_editing_bone).get_concatenated_names()
	
	if _is_bone_matubi(current_editing_bone):
		_insert_pos_rot_key(animation, root_to_path, animation_time,current_editing_bone)
		_insert_angle_length_key(animation, root_to_path, animation_time,current_editing_bone)
	else:
		_insert_pos_rot_key(animation, root_to_path, animation_time,current_editing_bone)
		_remove_angle_length_key(animation, root_to_path)

func _on_insert_key_frame_with_children_button_pressed() -> void:
	if current_editing_bone == null:
		printerr("Bone is null")
		return
	
	var current_animation:StringName = &""
	var animation_time:float = 0.0
	
	# EditorのControlから適当に取得
	# ※エディタ更新で動かなくなる可能性あり。
	var header:HBoxContainer = __AnimationPlayerEditor.get_child(0)
	for n in get_all_children(header):
		if n is SpinBox:
			animation_time= n.value
		if n is OptionButton:
			current_animation = n.get_item_text(n.selected)
			break
	
	var animation:Animation = current_animation_player.get_animation(current_animation)
	if animation == null:
		printerr("Animation is null")
		printerr("current_animation: " + current_animation)
		return
	var animation_root:Node = current_animation_player.get_node(current_animation_player.root_node)
	var root_to_path:String = animation_root.get_path_to(current_editing_bone).get_concatenated_names()
	
	if _is_bone_matubi(current_editing_bone):
		_insert_pos_rot_key(animation, root_to_path, animation_time,current_editing_bone)
		_insert_angle_length_key(animation, root_to_path, animation_time,current_editing_bone)
	else:
		_insert_pos_rot_key(animation, root_to_path, animation_time,current_editing_bone)
		_remove_angle_length_key(animation, root_to_path)
		current_editing_bone_children = _get_bone_children(current_editing_bone)
		for bone_c in current_editing_bone_children:
			root_to_path = animation_root.get_path_to(bone_c).get_concatenated_names()
			if _is_bone_matubi(bone_c):
				_insert_pos_rot_key(animation, root_to_path, animation_time,bone_c)
				_insert_angle_length_key(animation, root_to_path, animation_time,bone_c)
			else:
				_insert_pos_rot_key(animation, root_to_path, animation_time,bone_c)
				_remove_angle_length_key(animation, root_to_path)

func _insert_pos_rot_key(animation:Animation,root_to_path:String,animation_time:float,bone:Bone2D):
	var position_track_idx:int = animation.find_track(NodePath(root_to_path + ":position"),Animation.TYPE_VALUE)
	var rotation_track_idx:int = animation.find_track(NodePath(root_to_path + ":rotation"),Animation.TYPE_VALUE)
	# Trackがなければ新規作成する
	if position_track_idx == -1:
		position_track_idx = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(position_track_idx,NodePath(root_to_path + ":position"))
	if rotation_track_idx == -1:
		rotation_track_idx = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(rotation_track_idx,NodePath(root_to_path + ":rotation"))
	
	# 指定した時間にキーがあるか確認する
	var position_key_idx:int = animation.track_find_key(position_track_idx,animation_time,Animation.FIND_MODE_APPROX)
	var rotation_key_idx:int = animation.track_find_key(rotation_track_idx,animation_time,Animation.FIND_MODE_APPROX)
	if position_key_idx == -1:
		animation.track_insert_key(position_track_idx,animation_time,bone.position)
	else:
		animation.track_set_key_value(position_track_idx,position_key_idx,bone.position)
	
	if rotation_key_idx == -1:
		animation.track_insert_key(rotation_track_idx,animation_time,bone.rotation)
	else:
		animation.track_set_key_value(rotation_track_idx,rotation_key_idx,bone.rotation)

func _insert_angle_length_key(animation:Animation,root_to_path:String,animation_time:float,bone:Bone2D):
	var length_track_idx:int = animation.find_track(NodePath(root_to_path + ":length"),Animation.TYPE_VALUE)
	var bone_angle_track_idx:int = animation.find_track(NodePath(root_to_path + ":bone_angle"),Animation.TYPE_VALUE)
	# Trackがなければ新規作成する
	if length_track_idx == -1:
		length_track_idx = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(length_track_idx,NodePath(root_to_path + ":length"))
	if bone_angle_track_idx == -1:
		bone_angle_track_idx = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(bone_angle_track_idx,NodePath(root_to_path + ":bone_angle"))
	
	# 指定した時間にキーがあるか確認する
	var length_key_idx:int = animation.track_find_key(length_track_idx,animation_time,Animation.FIND_MODE_APPROX)
	var bone_angle_key_idx:int = animation.track_find_key(bone_angle_track_idx,animation_time,Animation.FIND_MODE_APPROX)
	if length_key_idx == -1:
		animation.track_insert_key(length_track_idx,animation_time,bone.length)
	else:
		animation.track_set_key_value(length_track_idx,length_key_idx,bone.length)
	
	if bone_angle_key_idx == -1:
		animation.track_insert_key(bone_angle_track_idx,animation_time,bone.bone_angle)
	else:
		animation.track_set_key_value(bone_angle_track_idx,bone_angle_key_idx,bone.bone_angle)

func _remove_angle_length_key(animation:Animation, root_to_path:String):
	# length,bone_angleのトラックがあれば削除する
	var length_track_idx:int = animation.find_track(NodePath(root_to_path + ":length"),Animation.TYPE_VALUE)
	var bone_angle_track_idx:int = animation.find_track(NodePath(root_to_path + ":bone_angle"),Animation.TYPE_VALUE)
	if length_track_idx != -1:
		animation.remove_track(length_track_idx)
	if bone_angle_track_idx != -1:
		animation.remove_track(bone_angle_track_idx)

##
## BONE COMMON
##

## ArrayのIndexをチェックする
func is_valid_index(array:Array, index:int) -> bool:
	return index >= 0 and index < array.size()

## res://aaaa/bbb/ccc.gd -> ccc
func get_file_name(_name: String) -> String:
	return _name.split("/")[-1].split(".")[0]

func _is_invalid_bone_root(bone:Bone2D) -> bool:
	var pa:Node = bone.get_parent()
	return not (pa is Skeleton2D) and not (pa is Bone2D)

func _is_bone_root(bone:Bone2D) -> bool:
	return bone.get_parent() is Skeleton2D

func _is_bone_matubi(bone:Bone2D) -> bool:
	if bone.get_child_count() == 0:
		return true
	else:
		for n in bone.get_children():
			if n is Bone2D:
				return false
		return true

func _get_bone_sentan_local_pos(bone:Bone2D) -> Vector2:
	if not bone:
		printerr(bone)
		printerr("is not bone2d.")
		return Vector2.ZERO
	var angle := bone.get_bone_angle()
	var length := bone.get_length()
	
	var result := Vector2(length, 0)

	result = result.rotated(angle)

	return result

func _set_bone_sentan(bone:Bone2D, global_pos:Vector2) -> void:
	if not bone:
		printerr(bone)
		printerr("is not bone2d.")
	global_pos = _get_bone_move_snapped_point(global_pos)
	var pos = bone.to_local(global_pos)
	pos = pos.rotated(bone.global_rotation)
	bone.set_bone_angle(_get_bone_sentan_angle(Vector2.ZERO, pos))
	bone.set_length(_get_bone_sentan_length(Vector2.ZERO, pos))
	#bone.set_bone_angle(bone.get_bone_angle() + bone.global_rotation)

func _get_bone_sentan_angle(from_pos:Vector2, to_pos:Vector2) -> float:
	var local_pos := to_pos - from_pos
	return local_pos.angle()

func _get_bone_sentan_length(from_pos:Vector2, to_pos:Vector2) -> float:
	var local_pos := to_pos - from_pos
	return local_pos.length()

func _get_select_bone() -> Bone2D:
	if not selection:
		return null
	var nodes:= selection.get_selected_nodes()
	
	if not nodes or nodes.is_empty():
		return null
	
	var node:Node = nodes[0]
	if not(node is Bone2D):
		return null
	
	return node

func _get_select_sprite() -> CanvasItem:
	if not selection:
		return null
	var nodes:= selection.get_selected_nodes()
	
	if not nodes or nodes.is_empty():
		return null
	
	var node:Node = nodes[0]
	if not(node is Sprite2D) and not(node is Polygon2D):
		return null
	
	return node

func _get_bone_children(bone:Bone2D) -> Array[Bone2D]:
	var ary:Array[Bone2D] = []
	
	for n in get_all_children(bone):
		if n is Bone2D:
			ary.append(n)
	ary.reverse()
	return ary

func _bone_btns_enable(toggle:bool):
	for btn in bone_buttons:
		btn.disabled = not toggle

func _get_current_skeleton() -> Skeleton2D:
	var node:Node = current_editing_bone
	if not node:
		return null
	while node:
		if node is Skeleton2D:
			return node
		node = node.get_parent()
	return null

func _get_mouse_position() -> Vector2:
	if viewport_2d:
		return viewport_2d.get_mouse_position()
	else:
		viewport_2d = EditorInterface.get_editor_viewport_2d()
		if viewport_2d:
			return viewport_2d.get_mouse_position()
		else:
			return Vector2.ZERO
	return Vector2.ZERO


func _on_bone_tab_button_toggled(toggled_on: bool) -> void:
	character_tab_container.current_tab = 0

func _on_image_tab_button_toggled(toggled_on: bool) -> void:
	character_tab_container.current_tab = 1

func _on_animation_tab_button_toggled(toggled_on: bool) -> void:
	character_tab_container.current_tab = 2

func _on_add_image_button_pressed() -> void:
	file_dialog.show()

func _on_file_dialog_file_selected(path: String) -> void:
	_load_image(path)

func _on_add_image_button_dropped(path: String) -> void:
	_load_image(path)

func _on_image_tree_dropped(path: String) -> void:
	_load_image(path)

func _load_image(path: String):
	for tree_item in image_tree.get_all_file_item():
		var _path:String = tree_item.get_metadata(0)
		if path == _path:
			printerr(path + "is already exists.")
			return
	
	var tex:Texture2D = load(path)
	
	if tex == null:
		printerr(path + "is cannot load.")
		return
	
	if tex:
		image_current_texture = tex
	
	var epsilon:float = 1.0
	
	var bitmap = BitMap.new()
	var image:= tex.get_image()
	bitmap.create_from_image_alpha(image)
	bitmap.grow_mask(image_padding, Rect2(Vector2(), bitmap.get_size()))
	var image_size:= image.get_size()
	image_current_polygons = bitmap.opaque_to_polygons(Rect2(Vector2(), bitmap.get_size()), epsilon)
	var datalist:Array[Dictionary] = []
	var index:int = 0
	for poly in image_current_polygons:
		var min_x = INF
		var min_y = INF
		var max_x = -INF
		var max_y = -INF
		for pos in poly:
			min_x = min(min_x, pos.x)
			min_y = min(min_y, pos.y)
			max_x = max(max_x, pos.x)
			max_y = max(max_y, pos.y)
		var rect:Rect2 = Rect2(Vector2(min_x, min_y), Vector2(max_x-min_x, max_y-min_y))
	
		var atlas_tex:= AtlasTexture.new()
		atlas_tex.atlas = image_current_texture
		atlas_tex.region = rect
		var resize_image:Image = atlas_tex.get_image()
		if resize_image.get_height() > 64:
			resize_max_height(resize_image, 64.0)
		var resized_tex:ImageTexture  = ImageTexture.create_from_image(resize_image)
		image_rect_item_tree.add_image_rect(index,path, str(rect), rect, resized_tex)
		
		var data = {
				"display_name": "",
				"origin_x": rect.size.x / 2.0,
				"origin_y": rect.size.y / 2.0,
				"size_x": rect.size.x,
				"size_y": rect.size.y,
				"position_x":rect.position.x,
				"position_y":rect.position.y,
				"outer_points":[],
				"inner_points":[]
			}
		datalist.append(data)
		index += 1
	
	sprite_polygon_data_list[path] = datalist
	
	image_tree.add_file(path)
	current_image_path = path
	#_on_image_tree_item_selected()

func resize_max_height(image:Image, height:float):
	var scale_:float = height / image.get_height()
	image.resize(image.get_width() * scale_, height)

func _on_image_tree_item_selected() -> void:
	cancel_image_text_input()
	var tree_item:TreeItem = image_tree.get_selected()
	if tree_item.get_metadata(0) != "file":
		return
	var path:String = tree_item.get_meta(&"path")
	
	var tex:Texture2D = load(path)
	
	if tex == null:
		printerr(path + "is cannot load.")
		return
	
	image_current_texture = tex
	
	if path == current_image_path:
		return
	
	current_image_path = path
	image_rect_item_tree.reset()
	var index:int = 0
	#print(sprite_polygon_data_list[path])
	for data in sprite_polygon_data_list[path]:
		var atlas_tex:= AtlasTexture.new()
		atlas_tex.atlas = image_current_texture
		var rect = Rect2(data["position_x"],data["position_y"],data["size_x"],data["size_y"])
		atlas_tex.region = rect
		var resize_image:Image = atlas_tex.get_image()
		if resize_image.get_height() > 64:
			resize_max_height(resize_image, 64.0)
		var resized_tex:ImageTexture  = ImageTexture.create_from_image(resize_image)
		if data["display_name"]:
			image_rect_item_tree.add_image_rect(index, path, data["display_name"], rect, resized_tex, false)
			#image_rect_item_tree.add_image_rect(index, path, data["display_name"], rect, null)
		else:
			image_rect_item_tree.add_image_rect(index, path, str(rect), rect, resized_tex, false)
			#image_rect_item_tree.add_image_rect(index, path, str(rect), rect, null)
		index += 1
	image_current_index = 0
	_set_image_rect_index(0)

func _set_image_rect_index(index:int):
	if index == -1:return
	if not sprite_polygon_data_list.has(current_image_path):return
	if index < 0 or index >= sprite_polygon_data_list[current_image_path].size():return
	
	image_current_index = index
	
	var rect:Rect2 = _get_current_rect()
	
	# キャンバスの形を変える
	canvas_margin_container.size = rect.size * image_current_scale
	color_rect.size = rect.size * image_current_scale
	
	canvas_margin_container.force_update_transform()
	color_rect.force_update_transform()
	canvas_center_container.force_update_transform()
	
	set_scroll_default.bind(-Vector2(24,24)).call_deferred()
	
	var atlas_tex:= AtlasTexture.new()
	atlas_tex.atlas = image_current_texture
	atlas_tex.region = rect

	image_texture_rect.texture = atlas_tex
	image_texture_rect.scale = Vector2(image_current_scale, image_current_scale)
	image_texture_rect.set_size(rect.size * image_current_scale)
	image_texture_rect.force_update_transform()
	
	image_atlas_position_x_spin_box.set_value_no_signal(rect.position.x)
	image_atlas_position_y_spin_box.set_value_no_signal(rect.position.y)
	image_atlas_size_width_spin_box.set_value_no_signal(rect.size.x)
	image_atlas_size_height_spin_box.set_value_no_signal(rect.size.y)
	
	var origin:Vector2 = Vector2(sprite_polygon_data_list[current_image_path][index]["origin_x"],sprite_polygon_data_list[current_image_path][index]["origin_y"])
	image_pivot_x_spin_box.set_value_no_signal(origin.x)
	image_pivot_y_spin_box.set_value_no_signal(origin.y)
	
	image_name_line_edit.text = sprite_polygon_data_list[current_image_path][index]["display_name"]
	
	_update_image_origin_cursor()
	if image_mode == IMAGE_MODE_POLYGON:
		polygon_points.queue_redraw.call_deferred()

func _is_valid_current_sprite_polygon_data():
	if not sprite_polygon_data_list.has(current_image_path):
		return false
	if not is_valid_index(sprite_polygon_data_list[current_image_path],image_current_index):
		return false
	return true

func _get_current_display_name():
	if not _is_valid_current_sprite_polygon_data():
		return null
	return sprite_polygon_data_list[current_image_path][image_current_index]["display_name"]

func _set_current_display_name(display_name:String) -> void:
	if not _is_valid_current_sprite_polygon_data():
		return
	sprite_polygon_data_list[current_image_path][image_current_index]["display_name"] = display_name


func _get_current_origin():
	if not _is_valid_current_sprite_polygon_data():
		return null
	return Vector2(sprite_polygon_data_list[current_image_path][image_current_index]["origin_x"],sprite_polygon_data_list[current_image_path][image_current_index]["origin_y"])

func _set_current_origin(origin:Vector2) -> void:
	if not _is_valid_current_sprite_polygon_data():
		return
	sprite_polygon_data_list[current_image_path][image_current_index]["origin_x"] = origin.x
	sprite_polygon_data_list[current_image_path][image_current_index]["origin_y"] = origin.y

func _get_current_rect():
	if not _is_valid_current_sprite_polygon_data():
		return Rect2()
	return Rect2(
		sprite_polygon_data_list[current_image_path][image_current_index]["position_x"],
		sprite_polygon_data_list[current_image_path][image_current_index]["position_y"],
		sprite_polygon_data_list[current_image_path][image_current_index]["size_x"],
		sprite_polygon_data_list[current_image_path][image_current_index]["size_y"]
		)

func _set_current_rect(rect:Rect2) -> void:
	if not _is_valid_current_sprite_polygon_data():
		return
	sprite_polygon_data_list[current_image_path][image_current_index]["position_x"] = rect.position.x
	sprite_polygon_data_list[current_image_path][image_current_index]["position_y"] = rect.position.y
	sprite_polygon_data_list[current_image_path][image_current_index]["size_x"] = rect.size.x
	sprite_polygon_data_list[current_image_path][image_current_index]["size_y"] = rect.size.y

func _get_outer_vertices() -> Array[Vector2]:
	var vertices:Array[Vector2] = []
	if not _is_valid_current_sprite_polygon_data():
		return vertices
	if not sprite_polygon_data_list[current_image_path][image_current_index].has("outer_vertices"):
		sprite_polygon_data_list[current_image_path][image_current_index]["outer_vertices"] = []
		return vertices
	for data in sprite_polygon_data_list[current_image_path][image_current_index]["outer_vertices"]:
		vertices.append(Vector2(data.x, data.y))
	
	return vertices

func _set_outer_vertices(vertices:Array[Vector2]) -> void:
	if not _is_valid_current_sprite_polygon_data():
		return
	sprite_polygon_data_list[current_image_path][image_current_index]["outer_vertices"] = vertices.map(func(i):
		return {
			"x": i.x,
			"y": i.y,
		}
	)

func _get_inner_vertices() -> Array[Vector2]:
	var vertices:Array[Vector2] = []
	if not _is_valid_current_sprite_polygon_data():
		return vertices
	if not sprite_polygon_data_list[current_image_path][image_current_index].has("inner_vertices"):
		sprite_polygon_data_list[current_image_path][image_current_index]["inner_vertices"] = []
		return vertices
	for data in sprite_polygon_data_list[current_image_path][image_current_index]["inner_vertices"]:
		vertices.append(Vector2(data.x, data.y))
	
	return vertices

func _set_inner_vertices(vertices:Array[Vector2]) -> void:
	if not _is_valid_current_sprite_polygon_data():
		return
	sprite_polygon_data_list[current_image_path][image_current_index]["inner_vertices"] = vertices.map(func(i):
		return {
			"x": i.x,
			"y": i.y,
		}
	)

func _update_image_origin_cursor():
	var origin:Vector2 = _get_current_origin()
	#image_cursor_sprite_2d.show()
	image_cursor_sprite_2d.position = origin * image_current_scale

func _on_color_rect_gui_input(event: InputEvent) -> void:
	if image_mode == IMAGE_MODE_SPRITE:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				_set_origin(event.position / image_current_scale)
		elif event is InputEventMouseMotion:
			if event.button_mask == MOUSE_BUTTON_LEFT:
				_set_origin(event.position / image_current_scale)

	elif image_mode == IMAGE_MODE_POLYGON:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				var pos:Vector2 = _get_snapped_point(event.position / image_current_scale)
				if polygon_mode == POLYGON_MODE_OUTER_ADD:
					_add_polygon_outer_point(pos)
				elif polygon_mode == POLYGON_MODE_OUTER_MOVE:
					if not polygon_points.is_outer_point_moving():
						var index:int = polygon_points.get_nearest_outer_point_index(pos)
						if index != -1:
							polygon_points.start_move_outer(index)
				elif polygon_mode == POLYGON_MODE_OUTER_INTERNAL_ADD:
					_add_polygon_outer_internal_point(pos)
				elif polygon_mode == POLYGON_MODE_OUTER_REMOVE:
					var index:int = polygon_points.get_nearest_outer_point_index(pos)
					if index != -1:
						polygon_points.remove_outer_point(index)
				elif polygon_mode == POLYGON_MODE_INNER_ADD:
					_add_polygon_inner_point(event.position / image_current_scale)
				elif polygon_mode == POLYGON_MODE_INNER_MOVE:
					if not polygon_points.is_inner_point_moving():
						var index:int = polygon_points.get_nearest_inner_point_index(pos)
						if index != -1:
							polygon_points.start_move_inner(index)
				elif polygon_mode == POLYGON_MODE_INNER_REMOVE:
					var index:int = polygon_points.get_nearest_inner_point_index(pos)
					if index != -1:
						polygon_points.remove_inner_point(index)
			elif event.button_index == MOUSE_BUTTON_LEFT and not (event.pressed):
				var pos:Vector2 = _get_snapped_point(event.position / image_current_scale)
				if polygon_mode == POLYGON_MODE_OUTER_MOVE:
					if polygon_points.is_outer_point_moving():
						polygon_points.fix_outer_point()
				elif polygon_mode == POLYGON_MODE_INNER_MOVE:
					if polygon_points.is_inner_point_moving():
						polygon_points.fix_inner_point()
			
			if event.button_index == MOUSE_BUTTON_RIGHT:
				if polygon_mode == POLYGON_MODE_OUTER_MOVE:
					polygon_points.cancel_move_outer()
				elif polygon_mode == POLYGON_MODE_INNER_MOVE:
					polygon_points.cancel_move_inner()
				
		elif event is InputEventMouseMotion:
			if event.button_mask == MOUSE_BUTTON_LEFT:
				var pos:Vector2 = _get_snapped_point(event.position / image_current_scale)
				if polygon_mode == POLYGON_MODE_OUTER_MOVE:
					if polygon_points.is_outer_point_moving():
						polygon_points.move_outer_point(pos)
				elif polygon_mode == POLYGON_MODE_INNER_MOVE:
					if polygon_points.is_inner_point_moving():
						polygon_points.move_inner_point(pos)

func _on_polygon_changed():
	_set_inner_vertices(polygon_points.inner_vertices)
	_set_outer_vertices(polygon_points.outer_vertices)

func _add_polygon_outer_point(pos:Vector2) -> void:
	var origin:Vector2 = _get_snapped_point(pos)
	polygon_points.scale = Vector2(image_current_scale, image_current_scale)
	polygon_points.add_outer_point(origin)

func _add_polygon_outer_internal_point(pos:Vector2) -> void:
	var origin:Vector2 = _get_snapped_point(pos)
	polygon_points.scale = Vector2(image_current_scale, image_current_scale)
	polygon_points.add_outer_internal_point(origin)

func _add_polygon_inner_point(pos:Vector2) -> void:
	var origin:Vector2 = _get_snapped_point(pos)
	polygon_points.scale = Vector2(image_current_scale, image_current_scale)
	polygon_points.add_inner_point(origin)

func _set_origin(pos:Vector2) -> void:
	var origin:Vector2 = _get_snapped_point(pos)
	image_pivot_x_spin_box.set_value_no_signal(origin.x)
	_on_image_pivot_x_spin_box_value_changed(origin.x)
	image_pivot_y_spin_box.set_value_no_signal(origin.y)
	_on_image_pivot_y_spin_box_value_changed(origin.y)

func _get_bone_move_snapped_point(pos:Vector2) -> Vector2:
	if bone_move_snap_mode == SNAP_MODE_NONE:
		return pos
	elif bone_move_snap_mode == SNAP_MODE_PIXEL:
		return pos.snapped(Vector2.ONE)
	elif bone_move_snap_mode == SNAP_MODE_HALF_PIXEL:
		return pos.snappedf(0.5)
	return Vector2.ZERO

func _get_snapped_point(pos:Vector2) -> Vector2:
	if image_snap_mode == SNAP_MODE_NONE:
		return pos
	elif image_snap_mode == SNAP_MODE_PIXEL:
		return pos.snapped(Vector2.ONE)
	elif image_snap_mode == SNAP_MODE_HALF_PIXEL:
		return pos.snappedf(0.5)
	return Vector2.ZERO

func _on_image_rect_item_tree_item_selected(index:int = -1) -> void:
	if index == -1:
		var tree_item:TreeItem = image_rect_item_tree.get_selected()
		if tree_item == null:return
		if tree_item.get_metadata(0) != "rect":return
		
		index = tree_item.get_meta(&"index")
		if index == -1:return
	
	_set_image_rect_index(index)
	
	_auto_zoom()
	if image_mode == IMAGE_MODE_POLYGON:
		polygon_points.outer_vertices = _get_outer_vertices()
		polygon_points.inner_vertices = _get_inner_vertices()
		polygon_points.process_outer_geometry()
		polygon_points.update_inner_points()
		polygon_points.process_inner_geometry()
		polygon_points.queue_redraw.call_deferred()

func _auto_zoom() -> void:
	var rect:Rect2 = _get_current_rect()
	if zoom_auto_check_box.button_pressed:
		image_current_scale = image_zoom_h_slider.min_value
		var image_size:Vector2 = (rect.size * image_current_scale) + Vector2(24,24)
		var count:int = 0
		while image_size.x < scroll_container.size.x and \
			image_size.y < scroll_container.size.y:
				if count > 100:break
				image_current_scale = image_current_scale + image_zoom_h_slider.step
				image_size = (rect.size * image_current_scale) + Vector2(24,24)
				count += 1
		image_current_scale = image_current_scale - image_zoom_h_slider.step
		image_zoom_h_slider.value = image_current_scale

func _on_image_pivot_x_spin_box_value_changed(value: float) -> void:
	var origin = _get_current_origin()
	if origin == null:return
	origin.x = value
	_set_current_origin(origin)
	
	_update_image_origin_cursor()

func _on_image_pivot_y_spin_box_value_changed(value: float) -> void:
	var origin = _get_current_origin()
	if origin == null:return
	origin.y = value
	_set_current_origin(origin)
	_update_image_origin_cursor()

func _on_image_texture_rect_resized() -> void:
	if image_current_index != -1:
		var rect:Rect2 = _get_current_rect()

		image_texture_rect.scale = Vector2(image_current_scale, image_current_scale)
		image_texture_rect.set_size(rect.size * image_current_scale)

func _on_color_picker_button_color_changed(color: Color) -> void:
	color_rect.color = color

func _on_image_snap_option_button_item_selected(index: int) -> void:
	image_snap_mode = index

func _on_image_cursor_option_button_ig_item_selected(index: int) -> void:
	if index == 0:
		image_cursor_sprite_2d.texture =  get_theme_icon("EditorPathSharpHandle", "EditorIcons")
	else:
		var pixel_image:Image = Image.create(image_current_scale,image_current_scale,false,Image.FORMAT_RGB8)
		pixel_image.fill(Color.RED)
		image_cursor_sprite_2d.texture = ImageTexture.create_from_image(pixel_image)

func _on_image_zoom_h_slider_value_changed(value: float) -> void:
	image_current_scale = value
	if image_mode == IMAGE_MODE_POLYGON:
		polygon_points.scale = Vector2(image_current_scale, image_current_scale)
		polygon_points.queue_redraw.call_deferred()
	zoom_value_label_ig.text = str(int(value * 100)) + "%"
	_set_image_rect_index(image_current_index)

func _on_image_add_one_button_pressed() -> void:
	if current_editing_bone:
		var sprite2d := Sprite2D.new()
		var atlas_tex:= AtlasTexture.new()
		atlas_tex.atlas = image_current_texture
		atlas_tex.region = _get_current_rect()
		sprite2d.texture = atlas_tex
		sprite2d.centered = false
		sprite2d.offset = - _get_current_origin()
		var display_name:String = _get_current_display_name()
		if display_name != "":
			sprite2d.name = display_name
		else:
			sprite2d.name = "Sprite2D"
		
		current_editing_bone.add_child(sprite2d, true)
		sprite2d.owner = scene_root
		
		sprite_list.append(sprite2d)


func _on_image_add_polygon_button_pressed() -> void:
	if current_editing_bone:
		var polygon_2d := Polygon2D.new()
		
		var atlas_tex:= AtlasTexture.new()
		atlas_tex.atlas = image_current_texture
		atlas_tex.region = _get_current_rect()
		
		polygon_2d.texture = image_current_texture
		polygon_2d.offset = - _get_current_origin()
		
		polygon_points.set_polygon(polygon_2d, _get_current_rect().position)
		
		var display_name:String = _get_current_display_name()
		if display_name != "":
			polygon_2d.name = display_name
		else:
			polygon_2d.name = "Polygon2D"
		
		if current_polygon_parent == null:
			scene_root.add_child(polygon_2d, true)
		else:
			current_polygon_parent.add_child(polygon_2d, true)
		
		polygon_2d.global_position = current_editing_bone.global_position
		
		polygon_2d.owner = scene_root
		
		polygon_2d.skeleton = polygon_2d.get_path_to(_get_current_skeleton())
		
		sprite_list.append(polygon_2d)


func _on_name_line_edit_text_changed(new_text: String) -> void:
	_set_current_display_name(new_text)
	image_rect_item_tree.set_item_text(image_current_index, new_text)

##
## SPRITE SELECT
##
func _on_sprite_selecting_rename_line_edit_text_submitted(new_text: String) -> void:
	current_editing_sprite.name = new_text
	selecting_sprite_name_label.text = current_editing_sprite.name
	sprite_selecting_rename_line_edit.text = current_editing_sprite.name
	
	# Animationのリネームも必要

func _on_sprite_selecting_lock_toggle_button_toggled(toggled_on: bool) -> void:
	lock_current_editing_sprite = toggled_on

func _on_sprite_select_parent_button_pressed() -> void:
	if (current_editing_sprite is Sprite2D or current_editing_sprite is Polygon2D) and current_editing_sprite.is_inside_tree():
		if current_editing_sprite.get_parent() != null:
			var parent_bone:Node = current_editing_sprite.get_parent()
			#var parent_parent_bone:Node = parent_bone.get_parent()
			#if parent_parent_bone is Bone2D:
			var res = _recursive_parent_sprite(parent_bone)
			if res != null:
				selection.clear()
				selection.add_node(res)
				_on_selection_changed()
			elif parent_bone is Sprite2D or parent_bone is Polygon2D:
				selection.clear()
				selection.add_node(parent_bone)
				_on_selection_changed()

func _on_sprite_select_child_button_pressed() -> void:
	if (current_editing_sprite is Sprite2D or current_editing_sprite is Polygon2D) and current_editing_sprite.is_inside_tree():
		var parent_bone:Node = current_editing_sprite.get_parent()
		if parent_bone is Bone2D:
			if parent_bone.get_child_count() > 0:
				var children_bones:Array = parent_bone.get_children().filter(func(i): return i is Bone2D)
				
				for c_bone in children_bones:
					var res = _recursive_child_sprite(c_bone)
					if res != null:
						selection.clear()
						selection.add_node(res)
						_on_selection_changed()
						break
		elif parent_bone is Sprite2D or parent_bone is Polygon2D:
			selection.clear()
			selection.add_node(parent_bone)
			_on_selection_changed()

func _recursive_parent_sprite(node:Node) -> CanvasItem:
	var bones:Array[Bone2D] = []
	if not is_instance_valid(node):return null
	if not node.is_inside_tree() :return null
	var parent = node.get_parent()
	if parent == null:return null
	if parent is Skeleton2D:return null
	if parent == scene_root:return null
	for c in parent.get_children():
		if c is Sprite2D or c is Polygon2D:
			return c
	return _recursive_parent_sprite(parent)

func _recursive_child_sprite(node:Node) -> CanvasItem:
	var bones:Array[Bone2D] = []
	if not is_instance_valid(node):return null
	if not node.is_inside_tree() :return null
	if node.get_child_count() == 0:return null
	for c in node.get_children():
		if c is Sprite2D or c is Polygon2D:
			return c
		elif c is Bone2D:
			bones.append(c)
	for b in bones:
		var res = _recursive_child_sprite(b)
		if res != null:
			return res
	return null

func _on_sprite_select_next_button_pressed() -> void:
	if (current_editing_sprite is Sprite2D or current_editing_sprite is Polygon2D) and current_editing_sprite.is_inside_tree():
		if current_editing_sprite.get_parent() != null:
			var pa:= current_editing_sprite.get_parent()
			var spriteonly_children:Array[CanvasItem] = []
			var index:int = 0
			var current_index:int = 0
			for n in pa.get_children():
				if n is Sprite2D or n is Polygon2D:
					spriteonly_children.append(n)
				if n == current_editing_sprite:
					current_index = index
				index = index + 1
			var count:int = spriteonly_children.size()
			if count == 1:return
			
			var next:int = (current_index + 1) % count
			selection.clear()
			selection.add_node(spriteonly_children[next])
			_on_selection_changed()


func _on_near_select_button_pressed() -> void:
	var main_screen := EditorInterface.get_editor_main_screen()
	
	# マウスがMainScreen外の場合
	if not main_screen.get_global_rect().has_point(get_global_mouse_position()):
		return
	
	# マウスがMainScreen内のこのControl内の場合
	if get_global_rect().has_point(get_global_mouse_position()):
		return
	
	var mouse_pos :Vector2 = _get_mouse_position()
	var nearest_pos:Vector2 = Vector2.INF
	var nearest_bone:Bone2D = null
	for bone in bone_list:
		if bone == null or not is_instance_valid(bone):
			continue
		var pos:Vector2 = bone.global_position
		if nearest_pos == Vector2.INF:
			nearest_pos = pos
			nearest_bone = bone
		else:
			if nearest_pos.distance_to(mouse_pos) > pos.distance_to(mouse_pos):
				nearest_pos = pos
				nearest_bone = bone
	if nearest_bone != null:
		await get_tree().process_frame
		selection.clear()
		selection.add_node(nearest_bone)
		_on_selection_changed()

func _on_sprite_near_select_button_pressed() -> void:
	var main_screen := EditorInterface.get_editor_main_screen()
	
	# マウスがMainScreen外の場合
	if not main_screen.get_global_rect().has_point(get_global_mouse_position()):
		return
	
	# マウスがMainScreen内のこのControl内の場合
	if get_global_rect().has_point(get_global_mouse_position()):
		return
	
	var mouse_pos :Vector2 = _get_mouse_position()
	var nearest_pos:Vector2 = Vector2.INF
	var nearest_sprite:CanvasItem = null
	for sprite in sprite_list:
		if sprite == null or not is_instance_valid(sprite):
			continue
		var pos:Vector2 = sprite.global_position
		if nearest_pos == Vector2.INF:
			nearest_pos = pos
			nearest_sprite = sprite
		else:
			if nearest_pos.distance_to(mouse_pos) > pos.distance_to(mouse_pos):
				nearest_pos = pos
				nearest_sprite = sprite
	if nearest_sprite != null:
		await get_tree().process_frame
		selection.clear()
		selection.add_node(nearest_sprite)
		_on_selection_changed()


func _on_sprite_visible_button_pressed() -> void:
	if current_editing_sprite!=null:
		current_editing_sprite.visible = !current_editing_sprite.visible
		if current_editing_sprite.visible:
			sprite_visible_button.icon = get_theme_icon("GuiVisibilityVisible", "EditorIcons")
		else:
			sprite_visible_button.icon = get_theme_icon("GuiVisibilityHidden", "EditorIcons")

func _on_image_mode_option_button_item_selected(index: int) -> void:
	image_mode = index
	if image_mode == IMAGE_MODE_POLYGON:
		polygon_menu_h_box_container.show()
		add_outer_polygon_point_button.button_pressed = true
		polygon_points.outer_vertices = _get_outer_vertices()
		polygon_points.inner_vertices = _get_inner_vertices()
		polygon_points.show()
		
		image_cursor_sprite_2d.hide()
	else:
		polygon_menu_h_box_container.hide()
		polygon_points.hide()
		
		image_cursor_sprite_2d.show()

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_on_image_rect_item_tree_item_selected.bind(image_current_index).call_deferred()

func _on_add_outer_polygon_point_button_toggled(toggled_on: bool) -> void:
	polygon_mode = POLYGON_MODE_OUTER_ADD

func _on_add_outer_polygon_internal_point_button_toggled(toggled_on: bool) -> void:
	polygon_mode = POLYGON_MODE_OUTER_INTERNAL_ADD

func _on_move_outer_polygon_point_button_toggled(toggled_on: bool) -> void:
	polygon_mode = POLYGON_MODE_OUTER_MOVE

func _on_remove_outer_polygon_point_button_toggled(toggled_on: bool) -> void:
	polygon_mode = POLYGON_MODE_OUTER_REMOVE

func _on_add_inner_polygon_point_button_toggled(toggled_on: bool) -> void:
	polygon_mode = POLYGON_MODE_INNER_ADD

func _on_move_inner_polygon_point_button_toggled(toggled_on: bool) -> void:
	polygon_mode = POLYGON_MODE_INNER_MOVE

func _on_remove_inner_polygon_point_button_toggled(toggled_on: bool) -> void:
	polygon_mode = POLYGON_MODE_INNER_REMOVE


func _on_image_atlas_position_x_spin_box_value_changed(value: float) -> void:
	var rect:Rect2 = _get_current_rect()
	rect.position.x = value
	_set_current_rect(rect)
	_set_image_rect_index(image_current_index)

func _on_image_atlas_position_y_spin_box_value_changed(value: float) -> void:
	var rect:Rect2 = _get_current_rect()
	rect.position.y = value
	_set_current_rect(rect)
	_set_image_rect_index(image_current_index)

func _on_image_atlas_size_width_spin_box_value_changed(value: float) -> void:
	var rect:Rect2 = _get_current_rect()
	rect.size.x = value
	_set_current_rect(rect)
	_set_image_rect_index(image_current_index)

func _on_image_atlas_sizeheight_spin_box_value_changed(value: float) -> void:
	var rect:Rect2 = _get_current_rect()
	rect.size.y = value
	_set_current_rect(rect)
	_set_image_rect_index(image_current_index)

func _on_image_padding_spin_box_value_changed(value: float) -> void:
	image_padding = value

func _on_polygon_parent_select_button_pressed() -> void:
	EditorInterface.popup_node_selector(_on_polygon_parent_selected)
	
func _on_polygon_parent_selected(node_path):
	if node_path.is_empty():
		pass
	elif scene_root.get_node(node_path):
		update_polygon_parent_selected(scene_root.get_node(node_path))
	else:
		update_polygon_parent_selected(null)

func update_polygon_parent_selected(node:Node):
	if node != null:
		current_polygon_parent = node
		polygon_parent_label_ig.text = node.name
		if node is Node2D:
			polygon_parent_icon_texture_rect.texture = get_theme_icon(node.get_class(), "EditorIcons")
		elif node is Control:
			polygon_parent_icon_texture_rect.texture = get_theme_icon(node.get_class(), "EditorIcons")
		else:
			polygon_parent_icon_texture_rect.texture = get_theme_icon(node.get_class(), "EditorIcons")
	else:
		current_polygon_parent = null
		polygon_parent_label_ig.text = ""
		polygon_parent_icon_texture_rect.texture = get_theme_icon("Info", "EditorIcons")


func _on_scroll_container_resized() -> void:
	if scroll_container:
		if canvas_center_container:
			canvas_center_container.custom_minimum_size = scroll_container.size * 3.0


func _on_scroll_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.ctrl_pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				image_zoom_h_slider.value = image_zoom_h_slider.value + image_zoom_h_slider.step
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				image_zoom_h_slider.value = image_zoom_h_slider.value - image_zoom_h_slider.step

func _on_remove_image_check_button_toggled(toggled_on: bool) -> void:
	image_tree.toggle_delete(toggled_on)

func _on_image_tree_removed(items:Array[TreeItem]) -> void:
	for item in items:
		if item.get_metadata(0) == "file":
			var path:String = item.get_meta(&"path")
			sprite_polygon_data_list.erase(path)
	current_image_path = ""
	image_current_index = -1
	image_current_texture = null
	image_rect_item_tree.reset()
	image_tree.deselect_all()
	image_texture_rect.texture = null
	canvas_margin_container.size = Vector2.ZERO
	color_rect.size = Vector2.ZERO


var image_tree_btn_mode:int = 0
const IMAGE_TREE_BTN_MODE_NONE:int = 0
const IMAGE_TREE_BTN_MODE_ADD_DIR:int = 1
const IMAGE_TREE_BTN_MODE_RENAME_DIR:int = 2

func _on_add_image_dir_button_pressed() -> void:
	image_text_input_h_box_container.show()
	image_tree_btn_mode = IMAGE_TREE_BTN_MODE_ADD_DIR

func cancel_image_text_input():
	image_tree_btn_mode = IMAGE_TREE_BTN_MODE_NONE
	image_text_input_line_edit.text = ""
	image_text_input_h_box_container.hide()

func _on_image_text_input_confirm_button_pressed() -> void:
	if image_text_input_line_edit.text == "":
		return
	
	if image_tree_btn_mode == IMAGE_TREE_BTN_MODE_ADD_DIR:
		image_tree.add_dir(image_text_input_line_edit.text)
	elif image_tree_btn_mode == IMAGE_TREE_BTN_MODE_RENAME_DIR:
		image_tree.add_dir(image_text_input_line_edit.text)
	
	image_text_input_line_edit.text = ""
	image_text_input_h_box_container.hide()

func _on_image_text_input_line_edit_text_submitted(new_text: String) -> void:
	_on_image_text_input_confirm_button_pressed()

func _on_image_tree_empty_clicked(click_position: Vector2, mouse_button_index: int) -> void:
	cancel_image_text_input()


func _on_add_image_rect_button_pressed() -> void:
	var selected: = image_rect_item_tree.get_selected()
	var rect = Rect2(0,0,1,1)
	if selected == null:
		rect = Rect2(0,0,1,1)
	else:
		rect = selected.get_meta(&"rect")
	var index:int = sprite_polygon_data_list[current_image_path].size()
	var atlas_tex:= AtlasTexture.new()
	atlas_tex.atlas = image_current_texture
	atlas_tex.region = rect
	var resize_image:Image = atlas_tex.get_image()
	if resize_image.get_height() > 64:
		resize_max_height(resize_image, 64.0)
	var resized_tex:ImageTexture  = ImageTexture.create_from_image(resize_image)
	var data = {
				"display_name": "",
				"origin_x": rect.size.x / 2.0,
				"origin_y": rect.size.y / 2.0,
				"size_x": rect.size.x,
				"size_y": rect.size.y,
				"position_x":rect.position.x,
				"position_y":rect.position.y,
				"outer_points":[],
				"inner_points":[]
			}
	sprite_polygon_data_list[current_image_path].append(data)
	image_rect_item_tree.add_image_rect(index, current_image_path, str(rect), rect, resized_tex, false)

func _on_remove_image_rect_check_button_toggled(toggled_on: bool) -> void:
	image_rect_item_tree.toggle_delete(toggled_on)

func _on_image_rect_item_tree_removed(items: Array[TreeItem]) -> void:
	image_texture_rect.texture = null
	canvas_margin_container.size = Vector2.ZERO
	color_rect.size = Vector2.ZERO

func _on_polygon_viewer_node_add_button_pressed() -> void:
	if current_editing_bone:
		var viewer_node = polygon_points.duplicate()
		viewer_node.scale = Vector2.ONE
		viewer_node.z_index = 999
		EditorInterface.get_edited_scene_root().add_child(viewer_node)
		EditorInterface.get_edited_scene_root().move_child(viewer_node,0)
		viewer_node.position = current_editing_bone.global_position - _get_current_origin()
		viewer_node.owner = EditorInterface.get_edited_scene_root()


func _on_bone_move_snap_option_button_ig_item_selected(index: int) -> void:
	pass # Replace with function body.
