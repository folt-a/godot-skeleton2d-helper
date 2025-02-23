@tool
extends Node2D

@export var update:bool:
	set(v):
		update = false
		if v:
			process_outer_geometry()
			update_inner_points()
			process_inner_geometry()
			queue_redraw.call_deferred()

@export var outer_vertices: Array[Vector2] = []
@export var inner_vertices: Array[Vector2] = []

var outer_triangles: Array = []
var inner_triangles: Array = []

var current_outer_moving_index:int = -1
var current_outer_moving_before_point:Vector2
var current_inner_moving_index:int = -1
var current_inner_moving_before_point:Vector2

signal changed()

func _draw():
	if outer_vertices.is_empty():
		return
	
	var outline = outer_vertices + [outer_vertices[0]]
	draw_polyline(PackedVector2Array(outline), Color.WHITE, 0.25)
		
	## 外周のみのポリゴン
	#for t in outer_triangles:
		#draw_colored_polygon(PackedVector2Array(t), Color(0.7, 0.9, 1.0, 0.3))
		#draw_polyline(PackedVector2Array(t), Color(0.7, 0.9, 1.0, 0.5), 0.25)
	#
	# 内部の点を含むポリゴン
	for t in inner_triangles:
		draw_colored_polygon(PackedVector2Array(t), Color(1.0, 0.9, 0.7, 0.5))
		#draw_polyline(PackedVector2Array(t), Color(0.7, 0.9, 1.0, 0.5), 0.25)
		
		# ラインを1本ずつ引く
		for i in range(3):
			draw_multiline([
				t[i],
				t[(i + 1) % 3]
			], Color(0.7, 0.9, 1.0, 0.5), 0.25)
			#draw_line(t[i], t[(i + 1) % 3], Color(0.7, 0.9, 1.0, 0.5), 0.25)
	
	for point in outer_vertices:
		draw_circle(point, 0.5, Color.WHITE)
		
	for point in inner_vertices:
		draw_circle(point, 0.5, Color.BLUE)

func get_final_polygon(offset:Vector2 = Vector2.ZERO) -> PackedVector2Array:
	if inner_triangles.is_empty():return []
	var final_polygon:PackedVector2Array = []
	var polygons:Array[PackedVector2Array] = []
	for t in inner_triangles:
		polygons.append(PackedVector2Array(t))
	
	var count:int = 0
	while polygons.size() > 1:
		var merged:Array[PackedVector2Array] = Geometry2D.merge_polygons(polygons.pop_back(),polygons.pop_back())
		if merged.size() == 1:
			polygons.push_back(merged[0])
		if count > 10000:
			printerr("10000 over.")
			break
	
	return polygons[0]
#for t in inner_triangles:
		#print(t)
		#for i in 3:
			#final_polygon.append(t[i] + offset)

func set_polygon(polygon_2d:Polygon2D, offset:Vector2 = Vector2.ZERO) -> void:
	if inner_triangles.is_empty():
		return
	
	var all_vertices = outer_vertices + inner_vertices
	polygon_2d.polygons = triangles_to_polygons(inner_triangles)
	polygon_2d.internal_vertex_count = inner_vertices.size()
	polygon_2d.polygon = PackedVector2Array(all_vertices)
	var uv_vertices:PackedVector2Array = []
	for v in all_vertices:
		uv_vertices.append(v + offset)
	polygon_2d.uv = PackedVector2Array(uv_vertices)

func triangles_to_polygons(triangles: Array) -> Array:
	var result = []
	for triangle in triangles:
		var indices = []
		for vertex in triangle:
			indices.append(outer_vertices.find(vertex) if vertex in outer_vertices else outer_vertices.size() + inner_vertices.find(vertex))
		result.append(indices)
	print(result.size())
	return result

func sort_vertices_clockwise():
	if outer_vertices.size() < 3:
		return
	var center = Vector2.ZERO
	for v in outer_vertices:
		center += v
	center /= outer_vertices.size()
	outer_vertices.sort_custom(func(a, b): return (a - center).angle() < (b - center).angle())

func process_outer_geometry():
	if outer_vertices.size() < 3:
		outer_triangles.clear()
		return
	
	outer_triangles.clear()
	var triangulation = Geometry2D.triangulate_polygon(outer_vertices)
	for i in range(0, triangulation.size(), 3):
		var triangle = [
			outer_vertices[triangulation[i]],
			outer_vertices[triangulation[i + 1]],
			outer_vertices[triangulation[i + 2]]
		]
		outer_triangles.append(triangle)

func process_inner_geometry():
	if outer_vertices.size() < 3:
		inner_triangles.clear()
		return

	inner_triangles.clear()
	var all_points = outer_vertices + inner_vertices
	var triangulation = Geometry2D.triangulate_delaunay(all_points)
	#var triangulation = Geometry2D.triangulate_polygon(all_points)
	
	var points:PackedInt32Array = []
	
	for i in range(0, triangulation.size(), 3):
		var triangle = [
			all_points[triangulation[i]],
			all_points[triangulation[i + 1]],
			all_points[triangulation[i + 2]]
		]
		
		var valid = true
		for point in triangle:
			if not (point in outer_vertices or Geometry2D.is_point_in_polygon(point, PackedVector2Array(outer_vertices))):
				valid = false
				break
		
		var center = (triangle[0] + triangle[1] + triangle[2]) / 3.0
		if not Geometry2D.is_point_in_polygon(center, PackedVector2Array(outer_vertices)):
			valid = false
		
		#for j in range(3):
			#var edge_start = triangle[j]
			#var edge_end = triangle[(j + 1) % 3]
			#if is_edge_intersecting_boundary(edge_start, edge_end):
				#valid = false
				#break
		
		if valid:
			inner_triangles.append(triangle)
			points.append_array(all_points)

func is_edge_intersecting_boundary(start: Vector2, end: Vector2) -> bool:
	var segments = outer_vertices.size()
	for i in range(segments):
		var boundary_start = outer_vertices[i]
		var boundary_end = outer_vertices[(i + 1) % segments]
		
		if (start == boundary_start and end == boundary_end) or \
			(start == boundary_end and end == boundary_start):
			continue
		
		if start in outer_vertices or end in outer_vertices:
			continue
		
		if Geometry2D.segment_intersects_segment(start, end, boundary_start, boundary_end):
			return true
	return false

func add_outer_point(point: Vector2):
	outer_vertices.append(point)
	#sort_vertices_clockwise()
	process_outer_geometry()
	update_inner_points()
	process_inner_geometry()
	queue_redraw()
	changed.emit()

func add_outer_internal_point(point: Vector2):
	# 既存の線と選択した位置との垂直の交点を算出する
	var nearest_dic = get_nearest_outer_line_pos(point)
	if nearest_dic.index == -1:
		return
	var nearest_pos = nearest_dic.point
	outer_vertices.insert(nearest_dic.index + 1, nearest_pos)
	process_outer_geometry()
	update_inner_points()
	process_inner_geometry()
	queue_redraw()
	changed.emit()

func add_inner_point(point: Vector2):
	if not Geometry2D.is_point_in_polygon(point, PackedVector2Array(outer_vertices)):
		return
	inner_vertices.append(point)
	process_inner_geometry()
	queue_redraw()
	changed.emit()

func get_nearest_outer_point_index(pos: Vector2):
	var nearest_index = -1
	var nearest_distance = 1000000.0
	
	for i in range(outer_vertices.size()):
		#print(i,"  ",pos,"  ",outer_vertices[i])
		var distance = (outer_vertices[i] - pos).length()
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_index = i
	#print(nearest_index)
	return nearest_index

func get_nearest_outer_line_pos(pos: Vector2) -> Dictionary:
	var nearest_index = -1
	var nearest_distance = 1000000.0
	var nearest_position:Vector2
	
	for i in range(outer_vertices.size()):
		var start:= outer_vertices[i]
		var end:= outer_vertices[(i + 1) % outer_vertices.size()]
		var point:= Geometry2D.get_closest_point_to_segment(pos, start, end)
		var distance = (point - pos).length()
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_index = i
			nearest_position = point
	
	return {"index":nearest_index, "point":nearest_position}

func get_nearest_inner_point_index(pos: Vector2):
	var nearest_index = -1
	var nearest_distance = 1000000.0
	for i in range(inner_vertices.size()):
		var distance = (inner_vertices[i] - pos).length()
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_index = i
	
	return nearest_index

func move_outer_point(pos: Vector2):
	outer_vertices[current_outer_moving_index] = pos
	process_outer_geometry()
	process_inner_geometry()
	queue_redraw()

func move_inner_point(pos: Vector2):
	inner_vertices[current_inner_moving_index] = pos
	process_inner_geometry()
	queue_redraw()

func update_inner_points():
	# outerより外側にある点を削除する
	var new_inner_vertices:Array[Vector2] = []
	for point in inner_vertices:
		if Geometry2D.is_point_in_polygon(point, PackedVector2Array(outer_vertices)):
			new_inner_vertices.append(point)
	inner_vertices = new_inner_vertices

func start_move_outer(index:int):
	current_outer_moving_index = index
	current_outer_moving_before_point = outer_vertices[current_outer_moving_index]

func start_move_inner(index:int):
	current_inner_moving_index = index
	current_inner_moving_before_point = inner_vertices[current_inner_moving_index]

func cancel_move_outer():
	outer_vertices[current_outer_moving_index] = current_outer_moving_before_point
	process_outer_geometry()
	queue_redraw()

func cancel_move_inner():
	inner_vertices[current_inner_moving_index] = current_inner_moving_before_point
	process_inner_geometry()
	queue_redraw()

func is_outer_point_moving() -> bool:
	return current_outer_moving_index != -1

func is_inner_point_moving() -> bool:
	return current_inner_moving_index != -1

func fix_outer_point():
	current_outer_moving_index = -1
	current_outer_moving_before_point = Vector2.ZERO
	changed.emit()

func fix_inner_point():
	current_inner_moving_index = -1
	current_inner_moving_before_point = Vector2.ZERO
	changed.emit()

func remove_outer_point(index: int):
	outer_vertices.remove_at(index)
	process_outer_geometry()
	update_inner_points()
	process_inner_geometry()
	queue_redraw()
	changed.emit()

func remove_inner_point(index: int):
	inner_vertices.remove_at(index)
	process_inner_geometry()
	queue_redraw()
	changed.emit()
