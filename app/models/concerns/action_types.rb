module ActionTypes
	extend ActiveSupport::Concern

	include Training
	include Tactics

	ACTION_CLASSES = [
		AcceptChallengeAction,
		AcceptMembershipAction,
		AttackArmyAction,
		BecomeImmortalAction,
		BesiegeSettlementAction,
		BuyItemAction,
		CaptureSettlementAction,
		CastSpellAction,
		ChallengeCharacterAction,
		ChangeNameAction,
		CreateArmyAction,
		CreateUnitAction,
		DistributeGoodsAction,
		EquipMagicAction,
		EquipUnitAction,
		ExpandCityAction,
		ExploreDungeonAction,
		FormAllianceAction,
		GivePermissionsAction,
		GuardSettlementAction,
		ImproveDefencesAction,
		InspireCityAction,
		InviteMemberAction,
		KickMemberAction,
		LeaveAllianceAction,
		LeaveArmyAction,
		MoveArmyAction,
		PermitMemberAction,
		PickupItemsAction,
		ProduceItemAction,
		PublishNewsAction,
		RallyTroopsAction,
		RazeSettlementAction,
		RecruitHumanoidsAction,
		ScoutHexAction,
		SellItemAction,
		SpendExperienceAction,
		SubvertCityAction,
		TaxCityAction,
		TrainUnitAction,
		TransferGoldAction,
		TransferItemAction,
		TransferLeadershipAction,
		TransferPositionAction,
		TransferUnitAction,
		UnitTacticsAction
	]

	PARAMS_WITH_OPTIONS = ['challenge_id', 'alliance_id', 'army_id', 'item_id', 'owned_item_id', 'produceable_item_id', 'ritualable_item_id', 'race_item_id', 'trade_good_id', 'spell', 'character_id', 'member_id','unit_id', 'direction', 'attribute', 'training', 'tactic', 'position_id', 'owned_position_id']

	def action_name(klass)
		klass.to_s.gsub('Action','')
	end

	def action_display_name(klass)
		action_name(klass).split(/(?=[A-Z])/).join(' ')
	end

	def param_display_name(param_key)
		param_key.to_s.gsub('id','').gsub('_', ' ').capitalize
	end

	def icon_name(klass)
		klass.to_s.gsub('Action','').split(/(?=[A-Z])/).join('_').downcase
	end

	def at_settlement?
		Settlement.in_game(self.game).at_loc(self.location).count > 0
	end

	def param_options(param_key)
		return case param_key
		when 'challenge_id'
			@param_challenges ||= CharacterChallenge.where(character: self.character).sort{|a,b| a.character.name <=> b.character.name}.map{|cc| {value: cc.id, display: cc.challenger.to_s }}
		when 'alliance_id'
			@param_alliances ||= AllianceMember.for_character(self).pending.sort{|a,b| a.member.name <=> b.member.name}.map{|a| {value: a.alliance_id, display: a.alliance.to_s }}
		when 'army_id'
			@param_armies ||= Army.in_game(game).at_loc(location).where(["positions.id <> ?",id]).order_by_name.map{|a| {value: a.id, display: a.to_s }}
		when 'item_id'
			@param_items ||= Item.not_hidden.not_magical.order_by_name.map{|a| {value: a.id, display: a.to_s }} + Item.magical.order_by_name.map{|a| {value: a.id, display: a.to_s }}
		when 'trade_good_id'
			@param_trade_goods ||= Item.trade_good.order_by_name.map{|a| {value: a.id, display: a.to_s }}
		when 'owned_item_id'
			@param_owned_items ||= items.where("quantity > 0").order_by_name.map{|i| {value: i.item_id, display: i.item.to_s }}
		when 'produceable_item_id'
			@param_produceable_items ||= Item.produceable.order_by_name.map{|a| {value: a.id, display: a.to_s }}
		when 'ritualable_item_id'
			@param_ritualable_items ||= Item.ritualable.not_magical.order_by_name.map{|a| {value: a.id, display: a.to_s }}
		when 'race_item_id'
			@param_race_items ||= items.joins(:item).where("items.race <> '' AND position_items.quantity > 0").order_by_name.map{|i| {value: i.item_id, display: i.item.to_s }}
		when 'spell'
			@param_spells ||= Character::CHARACTER_SPELLS[self.character.character_type].map{|s| {value: s, display: s}}
		when 'character_id'
			@param_character ||= Character.in_game(game).where(["positions.id <> ?",id]).order_by_name.map{|a| {value: a.id, display: a.to_s }}
		when 'member_id'
			@param_member ||= AllianceMember.for_alliance(alliance).where(["member_id <> ?",id]).sort{|a,b| a.member.name <=> b.member.name}.map{|a| {value: a.member.id, display: a.member.to_s }}
		when 'unit_id'
			@param_units ||= Unit.for_army((self.army || self.character.army)).map{|a| {value: a.id, display: a.to_s }}
		when 'direction'
			@param_directions ||= Spatial::DIRECTION_NAMES.map{|s| {value: s, display: s}}
		when 'attribute'
			@param_attributes ||= Character::CHARACTER_ATTRIBUTES.map{|a| {value: a.to_s, display: a.to_s.gsub('_rating','').capitalize}} 
		when 'training'
			@param_training ||= Training::ALL_TRAINING.map{|s| {value: s, display: s}}
		when 'tactic'
			@param_tactic ||= Tactics::ALL_TACTICS.map{|s| {value: s, display: s}}
		when 'position_id'
			@param_positions ||= Position.in_game(game).at_loc(location).where(["positions.id <> ?",id]).order_by_name.map{|a| {value: a.id, display: a.to_s }}
		when 'owned_position_id'
			@param_owned_positions ||= Position.in_game(game).owned_by(self.owner_or_self).where(["positions.id <> ?",id]).order_by_name.map{|a| {value: a.id, display: a.to_s }}
		end
	end

	def spell_action_options
		options = {}
		if self.character.can_cast?('Heal')
			options['heal'] = param_options('unit_id')
		end
		if self.character.can_cast?('Bless')
			options['bless'] = param_options('unit_id')
		end
		if self.character.can_cast?('Ritual')
			options['ritual'] = param_options('ritualable_item_id')
		end
		options
	end

	def valid_actions
		actions = []
		ActionTypes::ACTION_CLASSES.each do |klass|
			name = action_name(klass)
			display_name = action_display_name(klass)
			icon = icon_name(klass)
			action = {
				'name' => name,
				'icon' => icon,
				'display_name' => display_name,
				'types' => klass::POSITION_TYPE,
				'subtypes' => klass::SUBTYPE,
				'description' => klass::DESCRIPTION,
				'alliance_required' => klass::ALLIANCE,
				'not_allied_required' => klass::NO_ALLIANCE,
				'settlement_required' => klass::SETTLEMENT_REQUIRED,
				'params' => []
			}
			if action['types'].include?(self.subclass) && 
				(action['subtypes'] == :any || action['subtypes'].include?(self.subtype)) &&
				(!action['alliance_required'] || self.alliance)  &&
				(!action['not_allied_required'] || self.alliance.nil?) &&
				(!action['settlement_required'] || at_settlement?) &&
				(klass != ExploreDungeonAction || hex.dungeon)
				params_valid = true
				action.merge!(spell_action_options) if klass == CastSpellAction
				klass::PARAMETERS.keys.each do |param_key|
					options = param_options("#{param_key}")
					if klass::PARAMETERS[param_key][:required] && ActionTypes::PARAMS_WITH_OPTIONS.include?("#{param_key}") && (options.nil? || options.empty?)
						params_valid = false
					elsif !ActionTypes::PARAMS_WITH_OPTIONS.include?("#{param_key}") || !(options.nil? || options.empty?)
						action['params'] << {
							'name' => "#{param_key}",
							'display_name' => param_display_name(param_key).strip,
							'required' => klass::PARAMETERS[param_key][:required],
							'type' => (options.nil? || options.empty?) ? klass::PARAMETERS[param_key][:type] : 'options',
							'options' => options,
							'options_required' => ActionTypes::PARAMS_WITH_OPTIONS.include?("#{param_key}")
						}
					end
				end 
				if params_valid
					action['types'] = action['types'].map{|t| t.to_s }
					actions << action
				end
			end
		end
		actions
	end
end