@tool
extends EditorPlugin

const BOTTOM_DOCK_TSCN:PackedScene = preload("res://addons/godot-skeleton2d-helper/bottom_dock.tscn")
var bottom_dock_scene:Control = null

var locale:String

const locale_ja_dic:Dictionary = {
	"AGM Helper" : "アクツク"
}

func _init() -> void:
	bottom_dock_scene = BOTTOM_DOCK_TSCN.instantiate()
	bottom_dock_scene.undo_redo = get_undo_redo()
	locale = EditorInterface.get_editor_settings().get_setting("interface/editor/editor_language")
	bottom_dock_scene.load_all_data()

func _tr(s:String) -> String:
	if locale == "ja":
		return locale_ja_dic[s]
	else:
		return s

func _enter_tree() -> void:
	#add_control_to_bottom_panel(bottom_dock_scene, _tr("AGM Helper"))
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_BOTTOM, bottom_dock_scene)
	
	if not scene_changed.is_connected(bottom_dock_scene._on_scene_changed):
		scene_changed.connect(bottom_dock_scene._on_scene_changed)
	
	if not scene_saved.is_connected(bottom_dock_scene._on_scene_saved):
		scene_saved.connect(bottom_dock_scene._on_scene_saved)
	
	bottom_dock_scene.load_all_data()
	bottom_dock_scene.refresh()

func _exit_tree() -> void:
	#remove_control_from_bottom_panel(bottom_dock_scene)
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_BOTTOM, bottom_dock_scene)
	
	if scene_changed.is_connected(bottom_dock_scene._on_scene_changed):
		scene_changed.disconnect(bottom_dock_scene._on_scene_changed)
	
	if scene_saved.is_connected(bottom_dock_scene._on_scene_saved):
		scene_saved.disconnect(bottom_dock_scene._on_scene_saved)
