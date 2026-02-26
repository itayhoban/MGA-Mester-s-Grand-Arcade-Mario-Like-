extends Enemy

var life = 1

func die():
	if life <= 1:
		super.die()
		set_collision_layer_value(3, false)
		set_collision_mask_value(1, false)
		var sound = AudioStreamPlayer.new()
		sound.stream = preload("res://Assets/sounds/goomba die.mp3")
		get_tree().current_scene.add_child(sound)
		sound.play()
		get_tree().create_timer(1.5).timeout.connect(queue_free)
		return
	life = -1
	toRegular()
	
func toRegular():
	set_collision_layer_value(4, false)
	set_collision_mask_value(1, false)
