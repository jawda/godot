class_name DropData extends Resource

@export var item : ItemData
@export_range( 0, 100, 1, "suffix:%" ) var probablity : float = 100
@export_range( 1, 10, 1, "suffix:items") var min_amount : int = 1
@export_range( 1, 10, 1, "suffix:items") var max_amount : int = 1

func get_drop_count() ->  int:
	##if random number is higher or equal to drop percentage
	if randf_range(0, 100) >= probablity:
		return 0 ## dont drop
	## otherwise drop 
	return randi_range( min_amount, max_amount)
		
		
