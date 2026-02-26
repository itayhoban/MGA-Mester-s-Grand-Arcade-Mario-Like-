extends Area2D

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

func _enter_tree():
	if get_parent().get_node("../Node2D") == null:
		$AnimationPlayer.play("jump")

func _on_AnimationPlayer_animation_finished(anim_name):
	queue_free()

func _on_coin_body_entered(body):
	if body is Player:  # Ensure only player collects
		audio_player.stream = load("res://Assets/sounds/coin.wav")
		audio_player.play()
		# Wait for sound to finish playing before removing
		await audio_player.finished
		queue_free()
