# Resources
Rails.logger.info "SEED: Creating Resources"
Item.create!(name: 'Hide', complexity: 5, terrain: 'Plains', resource: true, sea_transport_capacity: -1, land_transport_capacity: -1, air_transport_capacity: -1)
Item.create!(name: 'Wood', complexity: 5, terrain: 'Forest', resource: true, sea_transport_capacity: -1, land_transport_capacity: -1, air_transport_capacity: -1)
Item.create!(name: 'Iron', complexity: 5, terrain: 'Mountain', resource: true, sea_transport_capacity: -1, land_transport_capacity: -1, air_transport_capacity: -1)
Item.create!(name: 'Stone', complexity: 5, terrain: 'Hill', resource: true, sea_transport_capacity: -1, land_transport_capacity: -1, air_transport_capacity: -1)

Item.create!(name: 'Water Essence', complexity: 1, ritualable: false, hidden: true, resource: true, sea_transport_capacity: -1, land_transport_capacity: -1, air_transport_capacity: -1)
Item.create!(name: 'Air Essence', complexity: 1, ritualable: false, hidden: true, resource: true, sea_transport_capacity: -1, land_transport_capacity: -1, air_transport_capacity: -1)
Item.create!(name: 'Fire Essence', complexity: 1, ritualable: false, hidden: true, resource: true, sea_transport_capacity: -1, land_transport_capacity: -1, air_transport_capacity: -1)
Item.create!(name: 'Earth Essence', complexity: 1, ritualable: false, hidden: true, resource: true, sea_transport_capacity: -1, land_transport_capacity: -1, air_transport_capacity: -1)

# Humanoids
Rails.logger.info "SEED: Creating Humanoids"
Item.create!(name: 'Human', complexity: 100, terrain: 'Plains', race: 'Human', humanoid: true, sea_transport_capacity: -1, land_transport_capacity: 1, air_transport_capacity: -1)
Item.create!(name: 'Elf', complexity: 100, terrain: 'Forest', race: 'Elf', humanoid: true, sea_transport_capacity: -1, land_transport_capacity: 1, air_transport_capacity: -1)
Item.create!(name: 'Dwarf', complexity: 100, terrain: 'Hill', race: 'Dwarf', humanoid: true, sea_transport_capacity: -1, land_transport_capacity: 1, air_transport_capacity: -1)
Item.create!(name: 'Orc', complexity: 100, terrain: 'Barren', race: 'Orc', humanoid: true, sea_transport_capacity: -1, land_transport_capacity: 1, air_transport_capacity: -1)
Item.create!(name: 'Goblin', complexity: 10, terrain: 'Scrubland', race: 'Goblin', humanoid: true, sea_transport_capacity: -1, land_transport_capacity: 1, air_transport_capacity: -1)
Item.create!(name: 'Ogre', complexity: 1000, terrain: 'Wasteland', race: 'Ogre', humanoid: true, sea_transport_capacity: -1, land_transport_capacity: 2, air_transport_capacity: -1)
Item.create!(name: 'Giant', complexity: 1000, terrain: 'Mountain', race: 'Giant', humanoid: true, sea_transport_capacity: -1, land_transport_capacity: 4, air_transport_capacity: -1)

# Beasts
Rails.logger.info "SEED: Creating Beasts"
#Item.create!(name: 'Camel', complexity: 5, terrain: 'Desert', beast: true, sea_transport_capacity: -1, land_transport_capacity: 1, air_transport_capacity: -1)
Item.create!(name: 'Gryphon', complexity: 1000, terrain: 'Mountain', beast: true, flying: true, sea_transport_capacity: -1, land_transport_capacity: 1, air_transport_capacity: 1)
Item.create!(name: 'Horse', complexity: 10, terrain: 'Plains', beast: true, sea_transport_capacity: -1, land_transport_capacity: 1, air_transport_capacity: -1)
Item.create!(name: 'Wolf', complexity: 10, terrain: 'Forest', beast: true, sea_transport_capacity: -1, land_transport_capacity: 1, air_transport_capacity: -1)

# Undead
Rails.logger.info "SEED: Creating Undead"
Item.create!(name: 'Skeleton', complexity: 100, terrain: 'Plains', undead: true, race: 'Skeleton', sea_transport_capacity: -1, land_transport_capacity: 1, air_transport_capacity: -1)
Item.create!(name: 'Zombie', complexity: 100, terrain: 'Forest', undead: true, race: 'Zombie', sea_transport_capacity: -1, land_transport_capacity: 1, air_transport_capacity: -1)
Item.create!(name: 'Vampire', complexity: 1000, terrain: 'Mountain', undead: true, flying: true, race: 'Vampire', sea_transport_capacity: -1, land_transport_capacity: 1, air_transport_capacity: 1)

# Elementals
Rails.logger.info "SEED: Creating Elementals"
Item.create!(name: 'Imp', complexity: 10, terrain: 'Desert', elemental: true, race: 'Imp', sea_transport_capacity: -1, land_transport_capacity: 0, air_transport_capacity: -1)
Item.create!(name: 'Serpent', complexity: 100, terrain: 'Sea', elemental: true, race: 'Serpent', sea_transport_capacity: 1, land_transport_capacity: 1, air_transport_capacity: -1)
Item.create!(name: 'Valkyrie', complexity: 1000, terrain: 'Mountain', elemental: true, flying: true, race: 'Valkyrie', sea_transport_capacity: 0, land_transport_capacity: 1, air_transport_capacity: 1)

# Armour
Rails.logger.info "SEED: Creating Armour"
Item.create!(name: 'Leather', complexity: 10, armour_rating: 1, armour: true, hide: 1, iron: 0, sea_transport_capacity: -1, land_transport_capacity: -1, air_transport_capacity: -1)
Item.create!(name: 'Chainmail', complexity: 15, armour_rating: 2, speed_rating: -1, armour: true, hide: 1, iron: 2, sea_transport_capacity: -1, land_transport_capacity: -1, air_transport_capacity: -1)
Item.create!(name: 'Platemail', complexity: 25, armour_rating: 4, speed_rating: -2, armour: true, hide: 1, iron: 4, training_required: 'Armoured', sea_transport_capacity: -1, land_transport_capacity: -1, air_transport_capacity: -1)

# Weapons
Rails.logger.info "SEED: Creating Weapons"
Item.create!(name: 'Axe', complexity: 5, strength_rating: 2, weapon: true, wood: 1, iron: 1, range: 0, sea_transport_capacity: -1, land_transport_capacity: -1, air_transport_capacity: -1)
Item.create!(name: 'Sword', complexity: 10, strength_rating: 3, weapon: true, wood: 0, iron: 2, range: 0, sea_transport_capacity: -1, land_transport_capacity: -1, air_transport_capacity: -1)
Item.create!(name: 'Lance', complexity: 20, strength_rating: 5, speed_rating: -1, weapon: true, wood: 2, iron: 1, range: 0, training_required: 'Mobile', mounted_only: true, sea_transport_capacity: -1, land_transport_capacity: -1, air_transport_capacity: -1)
Item.create!(name: 'Spear', complexity: 10, strength_rating: 1, weapon: true, wood: 2, iron: 0, range: 1, sea_transport_capacity: -1, land_transport_capacity: -1, air_transport_capacity: -1)
Item.create!(name: 'Bow', complexity: 10, strength_rating: 2, weapon: true, wood: 1, iron: 0, range: 2, training_required: 'Archery', sea_transport_capacity: -1, land_transport_capacity: -1, air_transport_capacity: -1)
Item.create!(name: 'Crossbow', complexity: 15, strength_rating: 3, speed_rating: -1, weapon: true, wood: 2, iron: 1, range: 1, training_required: 'Machinery', sea_transport_capacity: -1, land_transport_capacity: -1, air_transport_capacity: -1)

# Vehicles
Rails.logger.info "SEED: Creating Vehicles"
Item.create!(name: 'Boat', complexity: 1250, sea_transport_capacity: 250, land_transport_capacity: -250, air_transport_capacity: -250, hide: 50, wood: 200, vehicle: true)
Item.create!(name: 'Wagon', complexity: 500, land_transport_capacity: 100, sea_transport_capacity: -100, air_transport_capacity: -100, hide: 50, wood: 50, vehicle: true)

# Siege Equipment
Rails.logger.info "SEED: Creating Siege Equipment"
Item.create!(name: 'Ladders', complexity: 500, hide: 100, wood: 0, iron: 0, sea_transport_capacity: -100, land_transport_capacity: -100, air_transport_capacity: -100, siege_equipment: true, siege_effectiveness: 1)
Item.create!(name: 'Siege Tower', complexity: 1250, hide: 0, wood: 200, iron: 50, sea_transport_capacity: -250, land_transport_capacity: 100, air_transport_capacity: -250, siege_equipment: true, siege_effectiveness: 2)
Item.create!(name: 'Trebuchet', complexity: 2500, hide: 25, wood: 250, iron: 225, sea_transport_capacity: -500, land_transport_capacity: 0, air_transport_capacity: -500, siege_equipment: true, siege_effectiveness: 4)

# Trade Goods
Rails.logger.info "SEED: Creating Trade Goods"
Item.create!(name: 'Clothes', complexity: 10, hide: 2, wood: 0, stone: 0, trade_good: true, sea_transport_capacity: -1, land_transport_capacity: -1, air_transport_capacity: -1)
Item.create!(name: 'Luxuries', complexity: 10, hide: 0, wood: 2, stone: 0, trade_good: true, sea_transport_capacity: -1, land_transport_capacity: -1, air_transport_capacity: -1)
Item.create!(name: 'Artwork', complexity: 10, hide: 0, wood: 0, stone: 2, trade_good: true, sea_transport_capacity: -1, land_transport_capacity: -1, air_transport_capacity: -1)

n = Item.count
m = 100

(n..m).each do
	Item.create!(name: 'RESERVED', hidden: true, ritualable: false)
end

Character::CHARACTER_EQUIPMENT_SLOTS.each do |slot|
	Character::CHARACTER_ATTRIBUTES.each do |stat|
		(1..Item::ARTEFACT_RANK).each do |rank|
			Item.create_magic_item!(slot, stat, rank)
		end
	end
end






