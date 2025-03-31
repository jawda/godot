class_name InventoryData extends Resource

signal equipment_changed

## this will be for the container that holds our inventory items
@export var slots : Array[ SlotData ]
var equipment_slot_count : int = 4

func _init() -> void:
	connect_slots()
	pass

func inventory_slots() -> Array[ SlotData ]:
	return slots.slice( 0, -equipment_slot_count)
	
	
func equipment_slots()-> Array[ SlotData ]:
	return slots.slice( -equipment_slot_count, slots.size())

## needs to check if item in inventory and add it or increase quantity
func add_item( item : ItemData, count : int = 1) -> bool:
	
	## see if item in inventory
	for s in slots: 
		if s:
			if s.item_data == item:
				s.quantity += count #increase quantity
				return true
				
	## dont have item do have empty slots?
	for i in inventory_slots().size():
		if slots[ i ] == null:
			var new = SlotData.new()
			new.item_data = item
			new.quantity = count
			slots[ i ] = new ## add to slot we are at then return
			new.changed.connect( slot_changed )
			return true
			
	print( "inventory was full!" )
	return false

#func remove_item(item : ItemData, count : int = 1) -> void:
### see if item in inventory
	#for s in slots: 
		#if s:
			#if s.item_data == item:
				#s.quantity += count #increase quantity
				#if s.quantity == 0
					#s
				#return
				
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
	
func equip_item( slot : SlotData ) -> void:
	if slot == null or not slot.item_data is EquipableItemData:
		return
		
	var item : EquipableItemData = slot.item_data
	var slot_index : int = slots.find( slot )#get index for where the item was
	var equipment_index : int = slots.size() - equipment_slot_count
	
	match item.type:
		EquipableItemData.Type.ARMOR:
			equipment_index += 0 # 20
			pass
		EquipableItemData.Type.WEAPON:
			equipment_index += 1 # 21
			pass
		EquipableItemData.Type.AMULET:
			equipment_index += 2 # 22
			pass
		EquipableItemData.Type.RING:
			equipment_index += 3 # 23
			pass
	var unequpped_slot : SlotData = slots[ equipment_index ]
	
	#swap two items
	slots[ slot_index ] = unequpped_slot
	slots[ equipment_index ] = slot
	
	equipment_changed.emit()
	PauseMenu.focused_item_changed( unequpped_slot )
	pass

func get_attack_bonus() -> int:
	return get_equipment_bonus( EquipableItemModifier.Type.ATTACK ) # return bonus
	
func get_attack_bonus_diff( item : EquipableItemData ) -> int:
	var before : int = get_attack_bonus()
	var after : int = get_equipment_bonus( EquipableItemModifier.Type.ATTACK, item)
	
	return after - before
	
func get_defence_bonus() -> int:
	return get_equipment_bonus( EquipableItemModifier.Type.DEFENSE ) # return bonus
	
func get_defense_bonus_diff( item : EquipableItemData ) -> int:
	var before : int = get_attack_bonus()
	var after : int = get_equipment_bonus( EquipableItemModifier.Type.DEFENSE, item)
	
	return after - before
	
func get_equipment_bonus( bonus_type : EquipableItemModifier.Type, compare : EquipableItemData = null ) -> int:
	var bonus : int = 0
	# loop thru all equipment equipped and get all bonuses
	for s in equipment_slots():
		if s == null:
			continue
		var e : EquipableItemData = s.item_data
		if compare:
			if e.type == compare.type:
				e = compare
		for m in e.modifiers:
			if m.type == bonus_type:
				bonus += m.value
	return bonus
