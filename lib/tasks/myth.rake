namespace :myth do

    desc "Setup"
    task setup: :environment do 
        Rake::Task['db:seed'].invoke
        Rake::Task['myth:setup_forums'].invoke
        Rake::Task['myth:create'].invoke
        Rake::Task['myth:create_gm'].invoke
    end

    desc "Create a new game"
    task :create, [:name, :map, :frequency] => :environment  do |name, args|
        name = args[:name] || 'The Crucible (Playtest)'
        map = args[:map] || '1'
        frequency = args[:frequency] || 1
        puts "Creating game '#{name}' of map #{map} with cycle frequency of #{frequency}"
        Game.create!(name: name, map_name: map, cycle_frequency: frequency)
    end

    desc "Create gamesmaster"
    task :create_gm, [:password] => :environment do |name, args|
        p = args[:password] || 'password'
        g = Game.first
        u = User.create(name: 'World Shaker', email: 'monkeyx@gmail.com', forem_admin: true, password: p, password_confirmation: p, character_type: 'Dragon')
        create_character(g, u) && SetupUser.setup!(u)
        Item.not_magical.not_hidden.each{|i| s = u.character.settlements.first; s.add_items!(i, 1000)} if Rails.env.development?
        u = User.create(name: 'Gamesmaster', email: 'gm@mythchronicles.com', forem_admin: true, password: p, password_confirmation: p, character_type: 'Lord')
        create_character(g, u) && SetupUser.setup!(u)
        Item.not_magical.not_hidden.each{|i| s = u.character.settlements.first; s.add_items!(i, 1000)} if Rails.env.development?
        u = User.create(name: 'Odysseus', email: 'gm-hero@mythchronicles.com', forem_admin: true, password: p, password_confirmation: p, character_type: 'Hero')
        create_character(g, u) && SetupUser.setup!(u)
        Item.not_magical.not_hidden.each{|i| s = u.character.settlements.first; s.add_items!(i, 1000)} if Rails.env.development?
        u = User.create(name: 'White Wizard', email: 'gm-necromancer@mythchronicles.com', forem_admin: true, password: p, password_confirmation: p, character_type: 'Necromancer')
        create_character(g, u) && SetupUser.setup!(u)
        Item.not_magical.not_hidden.each{|i| s = u.character.settlements.first; s.add_items!(i, 1000)} if Rails.env.development?
        u = User.create(name: 'Simar', email: 'gm-dragon@mythchronicles.com', forem_admin: true, password: p, password_confirmation: p, character_type: 'Dragon')
        create_character(g, u) && SetupUser.setup!(u)
        Item.not_magical.not_hidden.each{|i| s = u.character.settlements.first; s.add_items!(i, 1000)} if Rails.env.development?
    end

    desc "Setup test database - drops, loads schema, migrates and seeds the test db"
    task test_db_setup: :environment do
        Rails.env = ENV['RAILS_ENV'] = 'test'
        Rake::Task['db:drop'].invoke
        Rake::Task['db:create'].invoke
        Rake::Task['db:schema:load'].invoke
        Rake::Task['db:seed'].invoke
        ActiveRecord::Base.establish_connection
        Rake::Task['db:migrate'].invoke
        game = Game.create!(name: 'Test', map_size: 100)
    end

    desc "Opens a game"
    task :open, [:id] => :environment do |name, args|
        id = args[:id]
        g = nil
        raise "Invalid game" unless id && (g = Game.find(id)).setup_complete
        g.update_attributes!(open: true)
        g.create_forum!
    end

    desc "Schedule cycles for games"
    task schedule_cycle: :environment do 
        Game.due_cycle.each do |game|
            CycleGame.schedule(game)
        end
    end

    desc "Schedule game cycle"
    task :cycle, [:id] => :environment do |name, args|
        game = Game.where(id: args[:id]).first || Game.first
        puts CycleGame.schedule(game)
    end

    desc "Create pregen maps"
    task :create_maps, [:quantity, :offset] => :environment do |name, args|
        quantity = args[:quantity] || 5
        offset = args[:offset] || 1
        MapGenerator.bulk_generate!(7, quantity, offset)
    end

    desc "Setup forums"
    task setup_forums: :environment do 
        general =Forem::Category.create(name: 'Myths')
        games = Forem::Category.create(name: 'Chronicles')

        Forem::Forum.create(title: "Inn of Immortals", description: "General discussion", category_id: general.id, position: 0)
        Forem::Forum.create(title: "Arcane Lore", description: "Discussions around the game mechanics", category_id: general.id, position: 1)
        Forem::Forum.create(title: "Sage Advice", description: "Share hints and tips with other players", category_id: general.id, position: 2)
        
        Game.open.each do |game|
            g.create_forum!
        end
    end

    task 'resque:setup' => :environment

    def create_character(game, user)
        Position.create_character!(game, user, user.name, user.character_type)
    end
end
