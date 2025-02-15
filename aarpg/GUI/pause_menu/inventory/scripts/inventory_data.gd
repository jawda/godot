class_name InventoryData extends Resource

## this will be for the container that holds our inventory items
@export var slots : Array[ SlotData ]


func _init() -> void:
	connect_slots()
	pass

## needs to check if item in inventory and add it or increase quantity
func add_item( item : ItemData, count : int = 1) -> bool:
	
	## see if item in inventory
	for s in slots: 
		if s:
			if s.item_data == item:
				s.quantity += count #increase quantity
				return true
				
	## dont have item do have empty slots?
	for i in slots.size():
		if slots[ i ] == null:
			var new = SlotData.new()
			new.item_data = item
			new.quantity = count
			slots[ i ] = new ## add to slot we are at then return
			new.changed.connect( slot_changed )
			return true
			
	print( "inventory was full!" )
	return false

func connect_slots() -> void:
	for s in slots:
		if s:
			s.changed.connect( slot_changed )
			
func slot_changed() -> void:
	#everytime a slot changes we check to see if need to remove item because its at zero
	for s in slots:
		if s:
			if s.quantity < 1:
				s.changed.disconnect( slot_changed )
				var index = slots.find( s )
				slots[ index ] = null
				emit_changed()
	pass
