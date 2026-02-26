extends Block

class_name MysteryBox

enum BonusType {
	COIN,
	SHROOM,
	FLOWER
}

# Bonus References
const COIN_SCENE = preload("res://Scenes/coin.tscn")
const SHROOM_SCENE = preload("res://Scenes/shroom.tscn")
const SHOOTING_FLOWER_SCENE = preload("res://Scenes/shooting_flower.tscn")

@onready var animated_sprite_2d = $AnimatedSprite2D
@export var bonus_type: BonusType = BonusType.COIN
@export var invisible: bool = false

var is_empty = false

func _ready():
	animated_sprite_2d.visible = !invisible
	
func bump(_player_mode: Player.PlayerMode):
	if is_empty:
		return
		
	if invisible:
		animated_sprite_2d.visible = true
		invisible = !invisible
	
	# Perform the bump animation (replacing the parent implementation)
	var bump_tween = get_tree().create_tween()
	bump_tween.tween_property(self, "position", position + Vector2(0, -5), 0.12)
	bump_tween.chain().tween_property(self, "position", position, 0.12)
	
	check_for_enemy_collision()
	
	# MysteryBox-specific logic
	make_empty()
	
	match bonus_type:
		BonusType.COIN:
			spawn_coin()
		BonusType.SHROOM:
			spawn_shroom()
		BonusType.FLOWER:
			spawn_flower()

func make_empty():
	is_empty = true
	animated_sprite_2d.play("empty")	

func spawn_shroom():
	var shroom = SHROOM_SCENE.instantiate()
	shroom.global_position = global_position
	get_tree().root.add_child(shroom)
	
func spawn_coin():
	var coin = COIN_SCENE.instantiate()
	var sound = AudioStreamPlayer.new()
	sound.stream = preload("res://Assets/sounds/Coin Sound.mp3")
	get_tree().current_scene.add_child(sound)
	sound.play()
	coin.global_position = global_position + Vector2(0, -16)
	get_tree().root.add_child(coin)
	get_tree().get_first_node_in_group("level_manager").on_coin_collected()
	
func spawn_flower():
	var flower = SHOOTING_FLOWER_SCENE.instantiate()
	flower.global_position = global_position
	var sound = AudioStreamPlayer.new()
	sound.stream = preload("res://Assets/sounds/takeflowersound.mp3")
	get_tree().current_scene.add_child(sound)
	sound.play()
	get_tree().root.add_child(flower)
