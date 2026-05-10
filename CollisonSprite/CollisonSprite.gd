@tool
extends CollisionPolygon2D
class_name CollisonSprite2D

@export var texture:Texture2D
var canvas_item_rid:RID

@export_tool_button("Generate Smooth Convex Polygon", "CollisionPolygon2D") var generate_polygon_action = generate_convex_polygon
@export_tool_button("Generate Smooth Concave Polygon", "CollisionPolygon2D") var generate_smooth_concave_action = generate_smooth_concave_polygon
@export_tool_button("Generate Concave Polygon", "ConvexPolygonShape2D") var generate_concave_action = generate_concave_polygon

@export var shadow:Polygon2D 

func _ready() -> void:
	
	#creates canvas item for sprite
	if canvas_item_rid != null:
		RenderingServer.free_rid(canvas_item_rid)
		
	canvas_item_rid = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(canvas_item_rid, get_canvas())
	RenderingServer.canvas_item_set_visibility_layer(canvas_item_rid, -1)
	
	#sets the texture position,rotation and then draws the sprite
	update_sprite()

	pass
	
func _process(delta: float) -> void:
	
	

	
	#update the texture position, rotation and then redraws the sprite
	update_sprite()

func generate_convex_polygon():
	
	#Gets the pixel positions - minus half the texture size so they are centered on the node
	var pixel_positions:Array[Vector2] = get_non_transparent_pixels(-(texture.get_size())/2)
	
	var convex_triangles:PackedInt32Array = Geometry2D.triangulate_delaunay(pixel_positions)
	
	var convex_triangle_edges:Array[Vector2] = triangles_to_edges(convex_triangles)
	
	var unique_edges:Array[Vector2] = unique_edges(convex_triangle_edges)
	
	var ordered_points:Array[int] = order_connected_edges(unique_edges)
	
	var convex_hull:Array[Vector2] = []
	
	for index in ordered_points:
		convex_hull.append(pixel_positions[index])
	
	var output = smooth_ordered_positions(convex_hull)
	
	polygon = output
	return output

func generate_smooth_concave_polygon():
	
	#puts all the non-transparent pixels x and y coords in an array.  [(x1,y1),(x2,y2)...]
	var pixel_positions:Array[Vector2] = get_non_transparent_pixels(-(texture.get_size())/2)

	#converts the pixel positions into a list of triangles that make a convex hull of the pixel_positions. (a1,b1,c1,a2,b2,c2...)
	var convex_hull_triangles:PackedInt32Array = Geometry2D.triangulate_delaunay(pixel_positions)
	
	#removes triangles with a side longer than 3 this removes all tringles that connect nodes that are further than double adjacent sqrt(2) if you want singley adjacent
	var concave_hull_triangles:Array[int] = remove_triangles_by_longest_side_length(convex_hull_triangles, pixel_positions, 5)#place holder longest
	
	#turns list of points that for triangles into a list of edges expresses as Vector2. ex (a1,b1,c1,a2,b2,c2...) => [(a1,b1),(b1,c1),(c1,a1),(a2,b2),(b2, c2),(c2, a2)... ]
	var concave_hull_triangle_edges:Array[Vector2] = triangles_to_edges(concave_hull_triangles)
	
	#removes the edges that occur multiple times, this leaves only the external edges of a concave hull
	var concave_hull_unordered_edges:Array[Vector2] = unique_edges(concave_hull_triangle_edges)
	
	#orders the points to that every point is connected to the next with the last connecting to the first [(i1,i2),(i2,i3),(i3,i1)...] => (i1, i2, i3, ...)
	var concave_hull_ordered_points:Array[int] = order_connected_edges(concave_hull_unordered_edges)
	
	var concave_hull_ordered_positions:Array[Vector2] = []
	
	for index in concave_hull_ordered_points:
		concave_hull_ordered_positions.append(pixel_positions[index])
	
	var output = smooth_ordered_positions(concave_hull_ordered_positions)
	
	polygon = output
	return output
	
func generate_concave_polygon():
	
	#puts all the non-transparent pixels x and y coords in an array.  [(x1,y1),(x2,y2)...]
	var pixel_positions:Array[Vector2] = get_non_transparent_pixels(-(texture.get_size())/2)

	#converts the pixel positions into a list of triangles that make a convex hull of the pixel_positions. (a1,b1,c1,a2,b2,c2...)
	var convex_hull_triangles:PackedInt32Array = Geometry2D.triangulate_delaunay(pixel_positions)
	
	#removes triangles with a side longer than 3 this removes all tringles that connect nodes that are further than double adjacent sqrt(2) if you want singley adjacent
	var concave_hull_triangles:Array[int] = remove_triangles_by_longest_side_length(convex_hull_triangles, pixel_positions, 3)#place holder longest
	
	#turns list of points that for triangles into a list of edges expresses as Vector2. ex (a1,b1,c1,a2,b2,c2...) => [(a1,b1),(b1,c1),(c1,a1),(a2,b2),(b2, c2),(c2, a2)... ]
	var concave_hull_triangle_edges:Array[Vector2] = triangles_to_edges(concave_hull_triangles)
	
	#removes the edges that occur multiple times, this leaves only the external edges of a concave hull
	var concave_hull_unordered_edges:Array[Vector2] = unique_edges(concave_hull_triangle_edges)
	
	for edge in concave_hull_unordered_edges:
		if pixel_positions[edge.x].distance_to(pixel_positions[edge.y]) > 1:
			
			var remove_index = concave_hull_triangle_edges.find(edge)
			var remove_highest = max(remove_index % 3, (remove_index + 1) % 3, (remove_index+2) % 3) + (floor(remove_index/3))*3
			concave_hull_triangle_edges.remove_at(remove_highest) 
			concave_hull_triangle_edges.remove_at(remove_highest-1) 
			concave_hull_triangle_edges.remove_at(remove_highest-2)
			
	concave_hull_unordered_edges = unique_edges(concave_hull_triangle_edges)
	
	#orders the points to that every point is connected to the next with the last connecting to the first [(i1,i2),(i2,i3),(i3,i1)...] => (i1, i2, i3, ...)
	var concave_hull_ordered_points:Array[int] = order_connected_edges(concave_hull_unordered_edges)
	
	var concave_hull_ordered_positions:Array[Vector2] = []
	
	for index in concave_hull_ordered_points:
		concave_hull_ordered_positions.append(pixel_positions[index])
	
	var output = smooth_ordered_positions(concave_hull_ordered_positions)
	
	polygon = output
	return output

func get_non_transparent_pixels(offset:Vector2) -> Array[Vector2]:
	var image:Image = texture.get_image()
	image.decompress()
	
	var pixel_positions:Array[Vector2] = []
	for x in range(0, image.get_width()):
		for y in range(0, image.get_height()):
			if image.get_pixel(x, y).a > 0:
				if !pixel_positions.has(Vector2(x,y) + offset):
					pixel_positions.append(Vector2(x,y) + offset)
				if !pixel_positions.has(Vector2(x,y) + offset+ Vector2(1,0)):
					pixel_positions.append(Vector2(x,y) + offset+ Vector2(1,0))
				if !pixel_positions.has(Vector2(x,y) + offset+ Vector2(0,1)):
					pixel_positions.append(Vector2(x,y) + offset+ Vector2(0,1))
				if !pixel_positions.has(Vector2(x,y) + offset + Vector2(1,1)):
					pixel_positions.append(Vector2(x,y) + offset + Vector2(1,1))
				
	return pixel_positions

func remove_triangles_by_longest_side_length(triangles:Array[int], point_positions:Array[Vector2], longest_allowed_side:float) -> Array[int]:
	var output:Array[int]
	
	for i in range(0, triangles.size(), 3):
		var side_a = point_positions[triangles[i]]-point_positions[triangles[i+1]]
		var side_b = point_positions[triangles[i+1]]-point_positions[triangles[i+2]]
		var side_c = point_positions[triangles[i+2]]-point_positions[triangles[i]]
		var len_a = side_a.distance_to(side_b)
		var len_b = side_b.distance_to(side_c)
		var len_c = side_c.distance_to(side_a)
		
		if max(len_a, len_b, len_c) <= longest_allowed_side:
			output.append(triangles[i])
			output.append(triangles[i+1])
			output.append(triangles[i+2])
	
	return output

func triangles_to_edges(triangles:Array[int]) -> Array[Vector2]:
	
	var output:Array[Vector2] = []
	for i in range(0, triangles.size(), 3):
		output.append(Vector2(triangles[i], triangles[i+1]))
		output.append(Vector2(triangles[i+1], triangles[i+2]))
		output.append(Vector2(triangles[i+2], triangles[i]))
	
	return output

func unique_edges(edges:Array[Vector2]) -> Array[Vector2]:
	var output:Array[Vector2] = []
	for edge in edges:
		if edges.count(edge) + edges.count(Vector2(edge.y, edge.x)) == 1:
			output.append(edge)
		
	return output

func order_connected_edges(edges:Array[Vector2]) -> Array[int]:
	var output:Array[int] = []
	output.append(edges[0].x)
	output.append(edges[0].y)
	edges.remove_at(0)
	
	while !edges.is_empty():
		for i in edges.size():
			var edge = edges[i]
			if edge.x == output[-1]:
				output.append(edge.y)
				edges.remove_at(i)
				break
			elif edge.y == output[-1]:
				output.append(edge.x)
				edges.remove_at(i)
				break
	return output

func smooth_ordered_positions(positions:Array[Vector2]) -> Array[Vector2]:
	var smoothed:Array[Vector2] = [positions[0]]
	
	for i in range(1, positions.size()-2):
		var v1 = positions[i-1]-positions[i]
		var v2 = positions[i]-positions[i+1]
		
		if  !(is_equal_approx(v1.y/v1.x, v2.y/v2.x)):
			smoothed.append(positions[i])
	smoothed.append(positions[positions.size()-1])
	
	return smoothed

#update the texture position, rotation and then redraws
func update_sprite() -> void:
	var texture_transform = Transform2D(global_rotation, global_position)
	RenderingServer.canvas_item_set_transform(canvas_item_rid, texture_transform)
	RenderingServer.canvas_item_clear(canvas_item_rid)
	RenderingServer.canvas_item_add_texture_rect(canvas_item_rid, get_rect(), texture.get_rid())

func get_rect() -> Rect2:
	return Rect2((-texture.get_size()/2)*global_scale, texture.get_size() * global_scale)


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		_ready()
	
func _exit_tree() -> void:
	RenderingServer.free_rid(canvas_item_rid)
	pass
