extends Node2D
class_name DraggableManager

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child in get_children():
		if child is DraggableArea2D:
			child.dropped.connect(check_grab_attempt)


func check_grab_attempt(draggable:DraggableArea2D):
	draggable.grab_allowed = true
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
