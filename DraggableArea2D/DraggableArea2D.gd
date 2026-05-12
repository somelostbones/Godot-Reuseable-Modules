@tool
extends Area2D
class_name DraggableArea2D


@export var sprite:Sprite2D
@export var grab_action:String = ""

@export_category("Custom Parameters")

@export var drag_speed:float = 10

var is_dragging:bool = false
var position_grabbed:Vector2 = Vector2.ZERO
var target_position:Vector2 = Vector2.ZERO

var last_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	pass 


func _process(delta: float) -> void:
	if !Engine.is_editor_hint():
		if is_dragging:
			target_position =  get_global_mouse_position() - position_grabbed
			
			last_position = global_position
			global_position = global_position.move_toward(target_position, delta * drag_speed * target_position.distance_to(global_position))
			
			var velocity = (last_position - global_position)
			
			velocity = Vector2(-velocity.y, velocity.x)
			velocity = velocity * position_grabbed.normalized()
			
			rotation = deg_to_rad(velocity.x + velocity.y)
		


func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	var is_mouse_button = event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT 
	
	if (grab_action == "" && is_mouse_button && event.pressed) || (grab_action != "" && event.is_action_pressed(grab_action)):
		is_dragging = true
		position_grabbed =  get_global_mouse_position() - global_position
		
func _input(event: InputEvent) -> void:
	var is_mouse_button = event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT 
	if (grab_action == "" && is_mouse_button && !event.pressed) || (grab_action != "" && event.is_action_released(grab_action)):
		is_dragging = false
		position_grabbed = Vector2.ZERO
		pass
	
		

func _get_configuration_warnings() -> PackedStringArray:
	var found_sprite:bool = false
	for child in get_children():
		if child is Sprite2D:
			found_sprite = true
	if !found_sprite:
		return ["Parent has to be Sprite2D for node to function"]
	return []
