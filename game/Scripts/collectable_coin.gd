extends Area2D

class_name CollectableCoin

func _on_body_entered(body):
	if (body is Player):
		var sound = AudioStreamPlayer.new()
		sound.stream = preload("res://Assets/sounds/coin.wav")
		get_tree().current_scene.add_child(sound)
		sound.play()
		queue_free()
		get_tree().get_first_node_in_group("level_manager").on_coin_collected()
