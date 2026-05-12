@tool
extends Area2D
class_name DraggableArea2D


@export var sprite:Sprite2D
@export var grab_action:String = ""
@export var rotate_action:String = ""

@export_category("Custom Parameters")

@export var drag_speed:float = 10
@export var rotation_speed:float = 10
@export var sway_multiplyer:float = 1
@export var degree_per_rotate: = 90

@export_category("Effects")

@export var particles:GPUParticles2D
@export var scale_particles_to_sprite:bool = false
@export var scale_factor:float = 1
@export var audio_stream_player:AudioStreamPlayer2D
@export var audio_stream:AudioStream
@export var random_pitch_range:float

var is_dragging:bool = false
var position_grabbed:Vector2 = Vector2.ZERO
var target_position:Vector2 = Vector2.ZERO

var last_position: Vector2 = Vector2.ZERO
var sway_rotation:float = 0

var actual_rotation:float = 0
var target_rotation:float = 0



signal dropped(draggable:DraggableArea2D)

func _ready() -> void:
	var viewport = get_viewport()
	viewport.physics_object_picking_first_only = true
	viewport.physics_object_picking_sort = true
	
	if particles != null && scale_particles_to_sprite:
		if sprite == null:
			push_error("scaling particles requires a sprite to scale too")
		else:
			particles.scale = (sprite.get_rect().size/2) * scale_factor
		
	
	dropped.connect(on_dropped)
	pass 

func _process(delta: float) -> void:
	if !Engine.is_editor_hint():
		if is_dragging:
			target_position =  get_global_mouse_position() - position_grabbed
			
			last_position = global_position
			global_position = global_position.move_toward(target_position, delta * drag_speed * target_position.distance_to(global_position))
			
			if sway_multiplyer != 0:
				var velocity = (last_position - global_position)
			
				velocity = Vector2(-velocity.y, velocity.x)
				velocity = velocity * position_grabbed.normalized() 
			
				sway_rotation = deg_to_rad(velocity.x + velocity.y) * sway_multiplyer
		
		if actual_rotation != target_rotation:
			actual_rotation = move_toward(actual_rotation, target_rotation, delta * rotation_speed * abs(actual_rotation-target_rotation))
		
		rotation = actual_rotation + sway_rotation
		

func on_dropped():
	if particles != null:
		particles.restart()
	
	if audio_stream_player != null && audio_stream != null:
		audio_stream_player.stream = audio_stream
		audio_stream_player.pitch_scale = randf_range(1-random_pitch_range, 1+random_pitch_range)
		audio_stream_player.play()

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	var is_mouse_button = event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT 
	if (grab_action == "" && is_mouse_button && event.pressed) || (grab_action != "" && event.is_action_pressed(grab_action)):
		is_dragging = true
		position_grabbed =  get_global_mouse_position() - global_position
		move_to_front()
	if (grab_action == "" && is_mouse_button && event.double_click || (grab_action != "" && event.is_action_pressed(rotate_action))):
		target_rotation = target_rotation + deg_to_rad(degree_per_rotate)
		
func _input(event: InputEvent) -> void:
	if is_dragging:
		var is_mouse_button = event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT 
		if (grab_action == "" && is_mouse_button && !event.pressed) || (grab_action != "" && event.is_action_released(grab_action)) :
			is_dragging = false
			position_grabbed = Vector2.ZERO
			dropped.emit()
			pass
	

func _get_configuration_warnings() -> PackedStringArray:
	var found_sprite:bool = false
	for child in get_children():
		if child is Sprite2D:
			found_sprite = true
	if !found_sprite:
		return ["Parent has to be Sprite2D for node to function"]
	return []
