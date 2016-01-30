class HomeController < ApplicationController
    GUI = ["action_points", "mana_points", "gold", "army", "city", "documentation", "forums", "guild", "lair", "tower", "dragon", "hero", "necromancer", "lord"]
    ACTIONS = ["accept_challenge", "accept_membership", "attack_army", "become_immortal", "besiege_settlement", "buy_item", "capture_settlement", "cast_spell", "challenge_character", "change_name", "create_army", "create_unit", "distribute_goods", "equip_magic", "equip_unit", "expand_city", "explore_dungeon", "form_alliance", "form_settlement", "give_permissions", "guard_settlement", "improve_defences", "inspire_city", "invite_member", "kick_member", "leave_alliance", "leave_army", "move_army", "permit_member", "pickup_items", "produce_item", "publish_news", "rally_troops", "raze_settlement", "recruit_humanoids", "scout_hex", "sell_item", "spend_experience", "subvert_city", "tax_city", "train_unit", "transfer_gold", "transfer_item", "transfer_leadership", "transfer_position", "transfer_unit", "unit_tactics"]
    ITEMS = ["amulet","armour","artwork","axe","boat","bow","chainmail","clothes","crossbow","dwarf","elf","giant","goblin","gryphon","hide","horse","human","imp","iron","ladders","lance","leather","luxuries","ogre","orc","platemail","ring","serpent","siege_tower","skeleton","spear","stone","sword","trebuchet","valkyrie","vampire","wagon","weapon","wolf","wood","zombie"]

    PRELOAD_IMAGES = GUI + ACTIONS.map{|img| "/actions/#{img}"} + ITEMS.map{|img| "/items/#{img}"}

    def index
        @preload_images = PRELOAD_IMAGES
    end

    def template
        template = params[:template]

        if template.blank? || !File.exist?("#{Rails.root}/app/views/templates/#{template}.html.erb")
            not_found 
        end

        render "/templates/#{template}", layout: false
    end

    def docs
        page = params[:page]
        page = 'index' if page.blank?

        unless File.exist?("#{Rails.root}/app/views/docs/#{page}.html.erb")
            not_found
        else
            render "/docs/#{page}", layout: '/layouts/forums'
        end
    end

    def map
        id = params[:id] 
        game = Game.find(id)
        unless game && File.exist?("#{Rails.root}/public/maps/#{game.map_name}.html")
            not_found
        else
            render text: File.open("#{Rails.root}/public/maps/#{game.map_name}.html").read, layout: false
        end
    end
end
