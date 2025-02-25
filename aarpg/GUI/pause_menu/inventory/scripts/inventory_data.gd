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

## Gather the inventory into an array
func get_save_data() -> Array:
	var item_save : Array = []
	for i in slots.size():
		item_save.append( item_to_save( slots[i]) )
	return item_save

## convert each item into a dictionary
func item_to_save( slot : SlotData ) -> Dictionary:
	var result = { item = "", quantity = 0 }
	if slot != null:
		result.quantity = slot.quantity
		if slot.item_data != null:
			result.item = slot.item_data.resource_path
			
	return result

## get array of dictionary and convert back to slot data
func parse_save_data(save_data : Array) -> void:
	var array_size = slots.size()
	slots.clear()
	slots.resize( array_size )
	for i in save_data.size():
		slots[ i ] = item_from_save( save_data[ i ] )

	connect_slots()
	
func item_from_save(save_object : Dictionary) -> SlotData:
	if save_object.item == "":
		return null
	var new_slot: SlotData = SlotData.new()
	new_slot.item_data = load( save_object.item )
	new_slot.quantity = int( save_object.quantity )
	
	return new_slot
	
func use_item( item : ItemData, count : int = 1) -> bool:
	for s in slots:
		if s:
			if s.item_data == item and s.quantity >= count:
				s.quantity -= count
				return true
	return false
	
