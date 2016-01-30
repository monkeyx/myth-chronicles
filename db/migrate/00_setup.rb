class Setup < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.string :name, null: false
      t.integer :cycle, default: 1
      t.integer :season, default: 1
      t.integer :year, default: 1
      t.integer :age, default: 1
      t.timestamp :last_cycle
      t.integer :cycle_frequency, default: 24
      t.integer :map_size
      t.string :map_name
      t.boolean :setup_complete, default: false
      t.integer :neutral_guilds, default: 0
      t.integer :neutral_cities, default: 0
      t.integer :neutral_towers, default: 0
      t.integer :neutral_lairs, default: 0
      t.boolean :open, default: false

      t.timestamps null: false
    end

    create_table(:users) do |t|
      t.string :provider, :null => false, :default => "email"
      t.string :uid, :null => false, :default => ""
      t.string :name, null: false
      t.string :nickname
      t.string :image
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.inet     :current_sign_in_ip
      t.inet     :last_sign_in_ip
      t.timestamps null: false
      t.string :character_type, default: ""
      t.boolean :setup_complete, default: false
      t.string :colour, null: false
      t.json :tokens
      t.datetime :status_email_sent_at
    end

    add_index :users, [:uid, :provider],     :unique => true
    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    
    create_table :hexes do |t|
      t.integer :x, null: false
      t.integer :y, null: false
      t.string :location_id, null: false
      t.string :terrain
      t.integer :territory_id, default: 0
      t.integer :game_id, null: false

      t.timestamps null: false
    end

    add_index :hexes, [:game_id, :x, :y, :terrain, :territory_id], name: 'idx_hexes'

    create_table :positions do |t|
      t.string :name, null: false
      t.string :position_type, null: false
      t.integer :x, null: false
      t.integer :y, null: false
      t.string :location_id, null: false
      t.integer :owner_id, default: 0, null: false
      t.integer :game_id, null: false
      t.integer :cycle, default: 1
      t.integer :season, default: 1
      t.integer :year, default: 1
      t.integer :age, default: 1
      t.boolean :killed, default: false

      t.timestamps null: false
    end

    add_index :positions, [:game_id, :y, :x, :position_type], name: 'idx_pos_location'
    add_index :positions, [:owner_id, :position_type], name: 'idx_pos_owner'

     create_table :position_items do |t|
      t.integer :position_id, null: false
      t.integer :item_id, null: false
      t.integer :quantity, default: 0

      t.timestamps null: false
    end

    add_index :position_items, [:position_id, :item_id], name: 'idx_pos_items'

    create_table :characters do |t|
      t.integer :position_id, null: false
      t.integer :leadership_rating, default: 0
      t.integer :cunning_rating, default: 0
      t.integer :craft_rating, default: 0
      t.integer :strength_rating, default: 0
      t.integer :armour_rating, default: 0
      t.integer :speed_rating, default: 0
      t.string :character_type, null: false
      t.integer :action_points, default: 0
      t.integer :mana_points, default: 0
      t.integer :experience_points, default: 0
      t.integer :renown, default: 0
      t.integer :gold, default: 0
      t.integer :armour_id, default: 0
      t.integer :weapon_id, default: 0
      t.integer :ring_id, default: 0
      t.integer :amulet_id, default: 0
      t.integer :alliance_id, default: 0
      t.integer :user_id, null: false

      t.timestamps null: false
    end

    add_index :characters, [:position_id, :character_type, :user_id], name: 'idx_characters'

    create_table :character_challenges do |t|
      t.integer :character_id, null: false
      t.integer :challenger_id, null: false
      t.integer :x, null: false
      t.integer :y, null: false
      t.string :location_id, null: false
      t.integer :game_id, null: false
      t.integer :cycle, default: 1
      t.integer :season, default: 1
      t.integer :year, default: 1
      t.integer :age, default: 1
    end

    add_index :character_challenges, [:character_id, :challenger_id, :x, :y, :cycle, :season, :year, :age, :game_id], name: 'idx_challenges'

    create_table :character_rumours do |t|
      t.integer :character_id, null: false
      t.integer :rumour_id, null: false
      t.integer :x, null: false
      t.integer :y, null: false
      t.string :location_id, null: false
      t.integer :game_id, null: false
      t.integer :cycle, default: 1
      t.integer :season, default: 1
      t.integer :year, default: 1
      t.integer :age, default: 1
    end

    add_index :character_rumours, [:character_id, :rumour_id, :x, :y, :cycle, :season, :year, :age, :game_id], name: 'idx_character_rumours'

    create_table :armies do |t|
      t.integer :position_id, null: false
      t.integer :air_capacity, default: 0
      t.integer :sea_capacity, default: 0
      t.integer :land_capacity, default: 0
      t.integer :scouting, default: 0
      t.boolean :guarding, default: false
      t.integer :sieging_id, default: false
      t.integer :unit_count, default: 0
      t.integer :character_count, default: 0

      t.timestamps null: false
    end

    add_index :armies, :position_id

    create_table :units do |t|
      t.integer :army_id, null: false
      t.string :race, null: false
      t.string :training, default: ''
      t.integer :armour_id, default: 0
      t.integer :weapon_id, default: 0
      t.integer :mount_id, default: 0
      t.integer :transport_id, default: 0
      t.integer :siege_equipment_id, default: 0
      t.integer :health, default: 100
      t.integer :strength_rating, default: 0
      t.integer :armour_rating, default: 0
      t.integer :range, default: 0
      t.integer :speed_rating, default: 0
      t.integer :morale_rating, default: 0
      t.integer :scouting_rating, default: 0
      t.string :tactic, default: 'Swarm'
      t.integer :character_id, default: 0
      t.integer :bless_rating, default: 0

      t.timestamps null: false
    end

    add_index :units, [:army_id, :character_id, :health, :speed_rating], name: 'idx_units'

    create_table :settlements do |t|
      t.integer :position_id, null: false
      t.string :settlement_type, null: false
      t.string :population_race, default: ''
      t.integer :population_size, default: 0
      t.integer :population_growth, default: 0
      t.integer :population_loyalty, default: 0
      t.integer :city_id, default: 0
      t.integer :defence_rating, default: 0
      t.boolean :under_siege, default: false
      t.integer :year_last_taxed, default: 0

      t.timestamps null: false
    end

    add_index :settlements, [:position_id, :settlement_type], name: 'idx_settlements'

    create_table :settlement_permissions do |t|
      t.integer :settlement_id, null: false
      t.integer :position_id, default: 0
      t.integer :alliance_id, default: 0
      t.boolean :full, default: false
      t.integer :item_id, default: 0
      t.integer :quantity, default: 0

      t.timestamps null: false
    end

    add_index :settlement_permissions, [:settlement_id, :position_id, :alliance_id, :item_id, :full], name: 'idx_permissions'

    create_table :items do |t|
      t.string :name, null: false
      t.boolean :resource, default: false
      t.integer :complexity, default: 1
      t.string :terrain, default: ''
      t.boolean :humanoid, default: false
      t.string :race, default: ''
      t.boolean :beast, default: false
      t.boolean :flying, default: false
      t.boolean :undead, default: false
      t.boolean :elemental, default: false
      t.boolean :armour, default: false
      t.boolean :weapon, default: false
      t.integer :armour_rating, default: 0
      t.integer :hide, default: 0
      t.integer :wood, default: 0
      t.integer :iron, default: 0
      t.integer :stone, default: 0
      t.string :training_required, default: ''
      t.integer :range, default: 0
      t.integer :strength_rating, default: 0
      t.integer :speed_rating, default: 0
      t.boolean :mounted_only, default: false
      t.boolean :vehicle, default: false
      t.integer :sea_transport_capacity, default: 0
      t.integer :land_transport_capacity, default: 0
      t.integer :air_transport_capacity, default: 0
      t.boolean :siege_equipment, default: false
      t.integer :siege_effectiveness, default: 0
      t.boolean :trade_good, default: false
      t.boolean :magical, default: false
      t.string :magical_type, default: ''
      t.string :stat_modified, default: ''
      t.integer :stat_modifier, default: 0
      t.integer :carry_required, default: 0
      t.boolean :hidden, default: false
      t.boolean :ritualable, default: true

      t.timestamps null: false
    end

    add_index :items, [:terrain, :humanoid, :beast, :undead, :elemental], name: 'idx_item_recruit'

    create_table :markets do |t|
      t.integer :position_id, null: false
      t.string :market_type, null: false
      t.integer :item_id, null: false
      t.integer :price, default: 0
      t.integer :quantity, default: 0

      t.timestamps null: false
    end

    add_index :markets, [:position_id, :item_id], name: 'idx_markets'

    create_table :dungeons do |t|
      t.integer :x, null: false
      t.integer :y, null: false
      t.string :location_id, null: false
      t.integer :game_id, null: false
      t.integer :max_levels, null: false
      t.string :name, null: false

      t.timestamps null: false
    end

    add_index :dungeons, [:game_id, :x, :y], name: 'idx_dungeons'

    create_table :dungeon_exploreds do |t|
      t.integer :dungeon_id, null: false
      t.integer :hero_id, null: false
      t.integer :level, null: false

      t.timestamps null: false
    end

    add_index :dungeon_exploreds, [:dungeon_id, :hero_id], name: 'idx_explored'

    create_table :battle_reports do |t|
      t.integer :attacker_id, null: false
      t.integer :defender_id, null: false
      t.string :battle_type, null: false
      t.integer :x, null: false
      t.integer :y, null: false
      t.integer :game_id, null: false
      t.string :location_id, null: false
      t.text :summary
      t.text :attacker_units_table 
      t.text :defender_units_table
      t.boolean :attacker_won, default: false
      t.boolean :defender_won, default: false
      t.integer :attacker_units_destroyed, default: 0
      t.integer :defender_units_destroyed, default: 0
      t.integer :year, null: false
      t.integer :cycle, null: false
      t.integer :season, null: false
      t.integer :age, null: false
      t.timestamps null: false
    end

    add_index :battle_reports, [:attacker_id, :defender_id, :year, :cycle, :season, :age, :x, :y], name: 'idx_battles'

    create_table :alliances do |t|
      t.string :name, null: false
      t.integer :year, null: false
      t.integer :cycle, null: false
      t.integer :season, null: false
      t.integer :age, null: false
      t.integer :leader_id, null: false

      t.timestamps null: false
    end

    add_index :alliances, :leader_id

    create_table :alliance_members do |t|
      t.integer :alliance_id, null: false
      t.integer :member_id, null: false
      t.integer :year, null: false
      t.integer :cycle, null: false
      t.integer :season, null: false
      t.integer :age, null: false
      t.boolean :publish_news, default: false
      t.boolean :invite_member, default: false
      t.boolean :accepted_invite, default: false
      t.boolean :kick_member, default: false

      t.timestamps null: false
    end

    add_index :alliance_members, [:alliance_id, :member_id], name: 'idx_ally'

    create_table :rumours do |t|
      t.integer :game_id, null: false
      t.integer :x, null: false
      t.integer :y, null: false
      t.string :location_id, null: false
      t.integer :spread_rate, default: 5
      t.integer :year, null: false
      t.integer :cycle, null: false
      t.integer :season, null: false
      t.integer :age, null: false
      t.integer :alliance_id, default: 0
      t.text :summary
      t.integer :current_distance, default: 0
      t.string :rumour_type, null: false

      t.timestamps null: false
    end

    add_index :rumours, [:x, :y, :current_distance], name: 'idx_rumours'

    create_table :immortals do |t|
      t.string :name, null: false
      t.string :character_type, null: false
      t.integer :year, null: false
      t.integer :cycle, null: false
      t.integer :season, null: false
      t.integer :age, null: false
      t.integer :game_id, null: false
      t.integer :user_id

      t.timestamps null: false
    end

    create_table :action_reports do |t|
      t.integer :position_id, null: false
      t.integer :caused_by_id, default: 0
      t.string :name, null: false
      t.integer :year, null: false
      t.integer :cycle, null: false
      t.integer :season, null: false
      t.integer :age, null: false
      t.text :summary

      t.timestamps null: false
    end

    add_index :action_reports, [:position_id, :year, :cycle, :season, :age, :name], name: 'idx_actions'

    create_table :quests do |t|
      t.integer :character_id, null: false
      t.string :name 
      t.string :status
      t.text :description
      t.string :class_name
      t.text :data
      t.boolean :completed, default: false

      t.timestamps null: false
    end

    add_index :quests, [:character_id, :completed], name: 'idx_quests'
  end
end
