##01. tool
#
##02. class_name
#class_name MainScene
#
##03. extends
#extends Node
##-----------------------------------------------------------
##04. # docstring
### メインシーン[br]
### 2Dシーンのルートと3Dルートを持つ[br]
### プレイヤーやカメラの一時格納先として使用する。[br]
### このメインを介して操作する。
#
##-----------------------------------------------------------
##05. signals
##-----------------------------------------------------------
#
##-----------------------------------------------------------
##06. enums
##-----------------------------------------------------------
#
##-----------------------------------------------------------
##07. constants
##-----------------------------------------------------------
#
##-----------------------------------------------------------
##08. exported variables
##-----------------------------------------------------------
#
##-----------------------------------------------------------
##09. public variables
##-----------------------------------------------------------
#
##-----------------------------------------------------------
##10. private variables
##-----------------------------------------------------------
#
##-----------------------------------------------------------
##11. onready variables
##-----------------------------------------------------------
#@onready var scene_3d: Node = %Scene3D
#
#@onready var camera_3d: Camera3D = %Camera3D
#@onready var phantom_camera_host: PhantomCameraHost = %PhantomCameraHost
#@onready var static_p_camera: PhantomCamera3D = %StaticPCamera
#
#@onready var scene_3d_objects = %Scene3DObjects
##@onready var player: Player
#@onready var player_nav_cursor_mesh: MeshInstance3D = %PlayerNavCursorMesh
#
#@onready var parallax_2d: Parallax2D = %Parallax2D
#
#static var MainNode:MainScene
#
#var tree: SceneTree
#var viewport: Viewport
#
##func d_a():
	##return CharacterInfo.data.map(func(i): return RefSerializer.serialize_object(i))[0]
#
##-----------------------------------------------------------
##12. optional built-in virtual _init method
##-----------------------------------------------------------
#
##-----------------------------------------------------------
##13. built-in virtual _ready method
##-----------------------------------------------------------
#
#func _init() -> void:
	#MainScene.MainNode = self
#
#func _enter_tree() -> void:
	#tree = get_tree()
	#viewport = tree.root.get_viewport()
	#Global.update_setting_init()
#
#func _ready():
	#NodeStatic.deactivate(scene_3d_objects)
	#get_viewport().content_scale_size = Vector2(1280,720)
	#set_static_p_cam_priority(true)
	#
	###	テスト用
	#var root:Window = get_node("/root")
#
	#get_tree().auto_accept_quit = false
	#root.close_requested.connect(func(): 
		#get_tree().quit()
		#get_tree().free()
		#)
	#
	#Gv.load_global_save_data()
	#
	#Gv.set_v("プレイヤー/マップ", "res://scene/game/map/scene/map_temp.tscn")
	#Gv.set_v("プレイヤー/マップ座標", Vector3(10,5,10))
	#Gv.set_v("プレイヤー/デッキ上限", 12)
	#
	## TEST
	#var item_have_infos:Dictionary = {
		#"item1" : {
			#"count": 10,
			#"feature_lists": [
				#[]
			#]
		#},
		#"material" : {
			#"count": 1
		#},
		#"aaa" : {
			#"count": 2
		#},
		#"item4" : {
			#"count": 0
		#},
	#}
	#Gv.set_v('プレイヤー/所持アイテム', item_have_infos)
	#
	#var item_have_cards:Dictionary = {
		#"item1" : {
			#"count": 10,
			#"feature_lists": [
				#[
				#]
			#]
		#},
		#"material" : {
			#"count": 1
		#},
		#"aaa" : {
			#"count": 2
		#},
		#"item4" : {
			#"count": 0
		#},
	#}
	#Gv.set_v('プレイヤー/所持カード', item_have_infos)
	#
	#
	#var deck:Array = [
		#
	#]
	#Gv.set_v('プレイヤー/所持デッキ', deck)
	#
	#var boot_count:int = Gv.get_g(&"boot_count", 0)
	#Gv.set_g(&"boot_count", boot_count + 1)
	#
	#SceneSystem2d.change_scene("res://scene/game/title/title_menu.tscn","",0.5)
#
##-----------------------------------------------------------
##14. remaining built-in virtual methods
##-----------------------------------------------------------
#
##func _process(delta: float) -> void:
	##if player:
		##parallax_2d.scroll_offset = Vector2(player.position.x, player.position.z) * 6
#
##-----------------------------------------------------------
##15. public methods
##-----------------------------------------------------------
#
#func back_to_title() -> void:
	#var player:Player = MapScene.CurrentMapScene.remove_player()
	#player.queue_free()
	#NodeStatic.deactivate(player)
	#MapScene.PrevMapNodeName = ""
	#FoltaUISystem.lock()
	#NodeStatic.deactivate(MapScene.CurrentMapScene)
	#SceneSystem.close_current_scene()
	#MapScene.CurrentMapScene.queue_free()
	#var tmp_2d_scene:Node = SceneSystem2d.current_scene
	#NodeStatic.deactivate(tmp_2d_scene)
	#SceneSystem.clear_all_cashe()
	#SceneSystem2d.clear_all_cashe()
	#FoltaUISystem.clear_histories()
	#SceneSystem2d.change_scene("res://scene/game/title/title_menu.tscn","",0.5)
	#FoltaUISystem.unlock.call_deferred()
#
#func activate_3d_objects() -> void:
	#NodeStatic.activate(scene_3d_objects)
#
#func deactivate_3d_objects() -> void:
	#NodeStatic.deactivate(scene_3d_objects)
#
#func get_main_3d_viewport() -> SubViewport:
	#return viewport
#
#func get_player() -> Player:
	#return player
#
#func remove_player() -> Player:
	#if !scene_3d_objects: return null
	#scene_3d_objects.remove_child(player)
	#return player
#
#const PLAYER = preload("res://scene/game/map/character/player/player.tscn")
#func create_player() -> void:
	#add_player(PLAYER.instantiate())
#
#func add_player(player_: Node) -> void:
	#self.player = player_
	#if !scene_3d_objects.get_node_or_null("Player"):
		#scene_3d_objects.add_child(player_)
#
#func hide_player() -> void:
	#player.hide_disable()
#
#func show_player() -> void:
	#player.show_enable()
#
#func get_static_p_cam() -> PhantomCamera3DEx:
	#return static_p_camera
#
#func set_static_p_cam_priority(on:bool):
	#if on:
		#var p_cam:PhantomCamera3D= phantom_camera_host.get_active_pcam()
		#set_static_p_cam_transform(p_cam)
		#static_p_camera.set_priority(PhantomCamera3DEx.PRIORITY_TELEPORT)
	#else:
		#static_p_camera.set_priority(PhantomCamera3DEx.PRIORITY_DISABLED)
#
#func set_static_p_cam_transform(p_cam:PhantomCamera3D):
	#static_p_camera.global_position = p_cam.global_position
	#static_p_camera.global_rotation = p_cam.global_rotation
#
#func get_p_cam_host() -> PhantomCameraHost:
	#return phantom_camera_host
#
##-----------------------------------------------------------
##16. private methods
##-----------------------------------------------------------
