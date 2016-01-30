# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "action_reports", force: :cascade do |t|
    t.integer  "position_id",              null: false
    t.integer  "caused_by_id", default: 0
    t.string   "name",                     null: false
    t.integer  "year",                     null: false
    t.integer  "cycle",                    null: false
    t.integer  "season",                   null: false
    t.integer  "age",                      null: false
    t.text     "summary"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "action_reports", ["position_id", "year", "cycle", "season", "age", "name"], name: "idx_actions", using: :btree

  create_table "alliance_members", force: :cascade do |t|
    t.integer  "alliance_id",                     null: false
    t.integer  "member_id",                       null: false
    t.integer  "year",                            null: false
    t.integer  "cycle",                           null: false
    t.integer  "season",                          null: false
    t.integer  "age",                             null: false
    t.boolean  "publish_news",    default: false
    t.boolean  "invite_member",   default: false
    t.boolean  "accepted_invite", default: false
    t.boolean  "kick_member",     default: false
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  add_index "alliance_members", ["alliance_id", "member_id"], name: "idx_ally", using: :btree

  create_table "alliances", force: :cascade do |t|
    t.string   "name",       null: false
    t.integer  "year",       null: false
    t.integer  "cycle",      null: false
    t.integer  "season",     null: false
    t.integer  "age",        null: false
    t.integer  "leader_id",  null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "alliances", ["leader_id"], name: "index_alliances_on_leader_id", using: :btree

  create_table "armies", force: :cascade do |t|
    t.integer  "position_id",                     null: false
    t.integer  "air_capacity",    default: 0
    t.integer  "sea_capacity",    default: 0
    t.integer  "land_capacity",   default: 0
    t.integer  "scouting",        default: 0
    t.boolean  "guarding",        default: false
    t.integer  "sieging_id",      default: 0
    t.integer  "unit_count",      default: 0
    t.integer  "character_count", default: 0
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  add_index "armies", ["position_id"], name: "index_armies_on_position_id", using: :btree

  create_table "battle_reports", force: :cascade do |t|
    t.integer  "attacker_id",                              null: false
    t.integer  "defender_id",                              null: false
    t.string   "battle_type",                              null: false
    t.integer  "x",                                        null: false
    t.integer  "y",                                        null: false
    t.integer  "game_id",                                  null: false
    t.string   "location_id",                              null: false
    t.text     "summary"
    t.text     "attacker_units_table"
    t.text     "defender_units_table"
    t.boolean  "attacker_won",             default: false
    t.boolean  "defender_won",             default: false
    t.integer  "attacker_units_destroyed", default: 0
    t.integer  "defender_units_destroyed", default: 0
    t.integer  "year",                                     null: false
    t.integer  "cycle",                                    null: false
    t.integer  "season",                                   null: false
    t.integer  "age",                                      null: false
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
  end

  add_index "battle_reports", ["attacker_id", "defender_id", "year", "cycle", "season", "age", "x", "y"], name: "idx_battles", using: :btree

  create_table "character_challenges", force: :cascade do |t|
    t.integer "character_id",              null: false
    t.integer "challenger_id",             null: false
    t.integer "x",                         null: false
    t.integer "y",                         null: false
    t.string  "location_id",               null: false
    t.integer "game_id",                   null: false
    t.integer "cycle",         default: 1
    t.integer "season",        default: 1
    t.integer "year",          default: 1
    t.integer "age",           default: 1
  end

  add_index "character_challenges", ["character_id", "challenger_id", "x", "y", "cycle", "season", "year", "age", "game_id"], name: "idx_challenges", using: :btree

  create_table "character_rumours", force: :cascade do |t|
    t.integer "character_id",             null: false
    t.integer "rumour_id",                null: false
    t.integer "x",                        null: false
    t.integer "y",                        null: false
    t.string  "location_id",              null: false
    t.integer "game_id",                  null: false
    t.integer "cycle",        default: 1
    t.integer "season",       default: 1
    t.integer "year",         default: 1
    t.integer "age",          default: 1
  end

  add_index "character_rumours", ["character_id", "rumour_id", "x", "y", "cycle", "season", "year", "age", "game_id"], name: "idx_character_rumours", using: :btree

  create_table "characters", force: :cascade do |t|
    t.integer  "position_id",                   null: false
    t.integer  "leadership_rating", default: 0
    t.integer  "cunning_rating",    default: 0
    t.integer  "craft_rating",      default: 0
    t.integer  "strength_rating",   default: 0
    t.integer  "armour_rating",     default: 0
    t.integer  "speed_rating",      default: 0
    t.string   "character_type",                null: false
    t.integer  "action_points",     default: 0
    t.integer  "mana_points",       default: 0
    t.integer  "experience_points", default: 0
    t.integer  "renown",            default: 0
    t.integer  "gold",              default: 0
    t.integer  "armour_id",         default: 0
    t.integer  "weapon_id",         default: 0
    t.integer  "ring_id",           default: 0
    t.integer  "amulet_id",         default: 0
    t.integer  "alliance_id",       default: 0
    t.integer  "user_id",                       null: false
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "characters", ["position_id", "character_type", "user_id"], name: "idx_characters", using: :btree

  create_table "dungeon_exploreds", force: :cascade do |t|
    t.integer  "dungeon_id", null: false
    t.integer  "hero_id",    null: false
    t.integer  "level",      null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "dungeon_exploreds", ["dungeon_id", "hero_id"], name: "idx_explored", using: :btree

  create_table "dungeons", force: :cascade do |t|
    t.integer  "x",           null: false
    t.integer  "y",           null: false
    t.string   "location_id", null: false
    t.integer  "game_id",     null: false
    t.integer  "max_levels",  null: false
    t.string   "name",        null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "dungeons", ["game_id", "x", "y"], name: "idx_dungeons", using: :btree

  create_table "forem_categories", force: :cascade do |t|
    t.string   "name",                   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
    t.integer  "position",   default: 0
  end

  add_index "forem_categories", ["slug"], name: "index_forem_categories_on_slug", unique: true, using: :btree

  create_table "forem_forums", force: :cascade do |t|
    t.string  "name"
    t.text    "description"
    t.integer "category_id"
    t.integer "views_count", default: 0
    t.string  "slug"
    t.integer "position",    default: 0
  end

  add_index "forem_forums", ["slug"], name: "index_forem_forums_on_slug", unique: true, using: :btree

  create_table "forem_groups", force: :cascade do |t|
    t.string "name"
  end

  add_index "forem_groups", ["name"], name: "index_forem_groups_on_name", using: :btree

  create_table "forem_memberships", force: :cascade do |t|
    t.integer "group_id"
    t.integer "member_id"
  end

  add_index "forem_memberships", ["group_id"], name: "index_forem_memberships_on_group_id", using: :btree

  create_table "forem_moderator_groups", force: :cascade do |t|
    t.integer "forum_id"
    t.integer "group_id"
  end

  add_index "forem_moderator_groups", ["forum_id"], name: "index_forem_moderator_groups_on_forum_id", using: :btree

  create_table "forem_posts", force: :cascade do |t|
    t.integer  "topic_id"
    t.text     "text"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "reply_to_id"
    t.string   "state",       default: "pending_review"
    t.boolean  "notified",    default: false
  end

  add_index "forem_posts", ["reply_to_id"], name: "index_forem_posts_on_reply_to_id", using: :btree
  add_index "forem_posts", ["state"], name: "index_forem_posts_on_state", using: :btree
  add_index "forem_posts", ["topic_id"], name: "index_forem_posts_on_topic_id", using: :btree
  add_index "forem_posts", ["user_id"], name: "index_forem_posts_on_user_id", using: :btree

  create_table "forem_subscriptions", force: :cascade do |t|
    t.integer "subscriber_id"
    t.integer "topic_id"
  end

  create_table "forem_topics", force: :cascade do |t|
    t.integer  "forum_id"
    t.integer  "user_id"
    t.string   "subject"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "locked",       default: false,            null: false
    t.boolean  "pinned",       default: false
    t.boolean  "hidden",       default: false
    t.datetime "last_post_at"
    t.string   "state",        default: "pending_review"
    t.integer  "views_count",  default: 0
    t.string   "slug"
  end

  add_index "forem_topics", ["forum_id"], name: "index_forem_topics_on_forum_id", using: :btree
  add_index "forem_topics", ["slug"], name: "index_forem_topics_on_slug", unique: true, using: :btree
  add_index "forem_topics", ["state"], name: "index_forem_topics_on_state", using: :btree
  add_index "forem_topics", ["user_id"], name: "index_forem_topics_on_user_id", using: :btree

  create_table "forem_views", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "viewable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "count",             default: 0
    t.string   "viewable_type"
    t.datetime "current_viewed_at"
    t.datetime "past_viewed_at"
  end

  add_index "forem_views", ["updated_at"], name: "index_forem_views_on_updated_at", using: :btree
  add_index "forem_views", ["user_id"], name: "index_forem_views_on_user_id", using: :btree
  add_index "forem_views", ["viewable_id"], name: "index_forem_views_on_viewable_id", using: :btree

  create_table "games", force: :cascade do |t|
    t.string   "name",                            null: false
    t.integer  "cycle",           default: 1
    t.integer  "season",          default: 1
    t.integer  "year",            default: 1
    t.integer  "age",             default: 1
    t.datetime "last_cycle"
    t.integer  "cycle_frequency", default: 24
    t.integer  "map_size"
    t.string   "map_name"
    t.boolean  "setup_complete",  default: false
    t.integer  "neutral_guilds",  default: 0
    t.integer  "neutral_cities",  default: 0
    t.integer  "neutral_towers",  default: 0
    t.integer  "neutral_lairs",   default: 0
    t.boolean  "open",            default: false
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  create_table "hexes", force: :cascade do |t|
    t.integer  "x",                        null: false
    t.integer  "y",                        null: false
    t.string   "location_id",              null: false
    t.string   "terrain"
    t.integer  "territory_id", default: 0
    t.integer  "game_id",                  null: false
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "hexes", ["game_id", "x", "y", "terrain", "territory_id"], name: "idx_hexes", using: :btree

  create_table "immortals", force: :cascade do |t|
    t.string   "name",           null: false
    t.string   "character_type", null: false
    t.integer  "year",           null: false
    t.integer  "cycle",          null: false
    t.integer  "season",         null: false
    t.integer  "age",            null: false
    t.integer  "game_id",        null: false
    t.integer  "user_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  create_table "items", force: :cascade do |t|
    t.string   "name",                                    null: false
    t.boolean  "resource",                default: false
    t.integer  "complexity",              default: 1
    t.string   "terrain",                 default: ""
    t.boolean  "humanoid",                default: false
    t.string   "race",                    default: ""
    t.boolean  "beast",                   default: false
    t.boolean  "flying",                  default: false
    t.boolean  "undead",                  default: false
    t.boolean  "elemental",               default: false
    t.boolean  "armour",                  default: false
    t.boolean  "weapon",                  default: false
    t.integer  "armour_rating",           default: 0
    t.integer  "hide",                    default: 0
    t.integer  "wood",                    default: 0
    t.integer  "iron",                    default: 0
    t.integer  "stone",                   default: 0
    t.string   "training_required",       default: ""
    t.integer  "range",                   default: 0
    t.integer  "strength_rating",         default: 0
    t.integer  "speed_rating",            default: 0
    t.boolean  "mounted_only",            default: false
    t.boolean  "vehicle",                 default: false
    t.integer  "sea_transport_capacity",  default: 0
    t.integer  "land_transport_capacity", default: 0
    t.integer  "air_transport_capacity",  default: 0
    t.boolean  "siege_equipment",         default: false
    t.integer  "siege_effectiveness",     default: 0
    t.boolean  "trade_good",              default: false
    t.boolean  "magical",                 default: false
    t.string   "magical_type",            default: ""
    t.string   "stat_modified",           default: ""
    t.integer  "stat_modifier",           default: 0
    t.integer  "carry_required",          default: 0
    t.boolean  "hidden",                  default: false
    t.boolean  "ritualable",              default: true
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
  end

  add_index "items", ["terrain", "humanoid", "beast", "undead", "elemental"], name: "idx_item_recruit", using: :btree

  create_table "mailboxer_conversation_opt_outs", force: :cascade do |t|
    t.integer "unsubscriber_id"
    t.string  "unsubscriber_type"
    t.integer "conversation_id"
  end

  add_index "mailboxer_conversation_opt_outs", ["conversation_id"], name: "index_mailboxer_conversation_opt_outs_on_conversation_id", using: :btree
  add_index "mailboxer_conversation_opt_outs", ["unsubscriber_id", "unsubscriber_type"], name: "index_mailboxer_conversation_opt_outs_on_unsubscriber_id_type", using: :btree

  create_table "mailboxer_conversations", force: :cascade do |t|
    t.string   "subject",    default: ""
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "mailboxer_notifications", force: :cascade do |t|
    t.string   "type"
    t.text     "body"
    t.string   "subject",              default: ""
    t.integer  "sender_id"
    t.string   "sender_type"
    t.integer  "conversation_id"
    t.boolean  "draft",                default: false
    t.string   "notification_code"
    t.integer  "notified_object_id"
    t.string   "notified_object_type"
    t.string   "attachment"
    t.datetime "updated_at",                           null: false
    t.datetime "created_at",                           null: false
    t.boolean  "global",               default: false
    t.datetime "expires"
  end

  add_index "mailboxer_notifications", ["conversation_id"], name: "index_mailboxer_notifications_on_conversation_id", using: :btree
  add_index "mailboxer_notifications", ["notified_object_id", "notified_object_type"], name: "index_mailboxer_notifications_on_notified_object_id_and_type", using: :btree
  add_index "mailboxer_notifications", ["sender_id", "sender_type"], name: "index_mailboxer_notifications_on_sender_id_and_sender_type", using: :btree
  add_index "mailboxer_notifications", ["type"], name: "index_mailboxer_notifications_on_type", using: :btree

  create_table "mailboxer_receipts", force: :cascade do |t|
    t.integer  "receiver_id"
    t.string   "receiver_type"
    t.integer  "notification_id",                            null: false
    t.boolean  "is_read",                    default: false
    t.boolean  "trashed",                    default: false
    t.boolean  "deleted",                    default: false
    t.string   "mailbox_type",    limit: 25
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
  end

  add_index "mailboxer_receipts", ["notification_id"], name: "index_mailboxer_receipts_on_notification_id", using: :btree
  add_index "mailboxer_receipts", ["receiver_id", "receiver_type"], name: "index_mailboxer_receipts_on_receiver_id_and_receiver_type", using: :btree

  create_table "markets", force: :cascade do |t|
    t.integer  "position_id",             null: false
    t.string   "market_type",             null: false
    t.integer  "item_id",                 null: false
    t.integer  "price",       default: 0
    t.integer  "quantity",    default: 0
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "markets", ["position_id", "item_id"], name: "idx_markets", using: :btree

  create_table "position_items", force: :cascade do |t|
    t.integer  "position_id",             null: false
    t.integer  "item_id",                 null: false
    t.integer  "quantity",    default: 0
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "position_items", ["position_id", "item_id"], name: "idx_pos_items", using: :btree

  create_table "positions", force: :cascade do |t|
    t.string   "name",                          null: false
    t.string   "position_type",                 null: false
    t.integer  "x",                             null: false
    t.integer  "y",                             null: false
    t.string   "location_id",                   null: false
    t.integer  "owner_id",      default: 0,     null: false
    t.integer  "game_id",                       null: false
    t.integer  "cycle",         default: 1
    t.integer  "season",        default: 1
    t.integer  "year",          default: 1
    t.integer  "age",           default: 1
    t.boolean  "killed",        default: false
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "positions", ["game_id", "y", "x", "position_type"], name: "idx_pos_location", using: :btree
  add_index "positions", ["owner_id", "position_type"], name: "idx_pos_owner", using: :btree

  create_table "quests", force: :cascade do |t|
    t.integer  "character_id",                 null: false
    t.string   "name"
    t.string   "status"
    t.text     "description"
    t.string   "class_name"
    t.text     "data"
    t.boolean  "completed",    default: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "quests", ["character_id", "completed"], name: "idx_quests", using: :btree

  create_table "rumours", force: :cascade do |t|
    t.integer  "game_id",                      null: false
    t.integer  "x",                            null: false
    t.integer  "y",                            null: false
    t.string   "location_id",                  null: false
    t.integer  "spread_rate",      default: 5
    t.integer  "year",                         null: false
    t.integer  "cycle",                        null: false
    t.integer  "season",                       null: false
    t.integer  "age",                          null: false
    t.integer  "alliance_id",      default: 0
    t.text     "summary"
    t.integer  "current_distance", default: 0
    t.string   "rumour_type",                  null: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "rumours", ["x", "y", "current_distance"], name: "idx_rumours", using: :btree

  create_table "settlement_permissions", force: :cascade do |t|
    t.integer  "settlement_id",                 null: false
    t.integer  "position_id",   default: 0
    t.integer  "alliance_id",   default: 0
    t.boolean  "full",          default: false
    t.integer  "item_id",       default: 0
    t.integer  "quantity",      default: 0
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "settlement_permissions", ["settlement_id", "position_id", "alliance_id", "item_id", "full"], name: "idx_permissions", using: :btree

  create_table "settlements", force: :cascade do |t|
    t.integer  "position_id",                        null: false
    t.string   "settlement_type",                    null: false
    t.string   "population_race",    default: ""
    t.integer  "population_size",    default: 0
    t.integer  "population_growth",  default: 0
    t.integer  "population_loyalty", default: 0
    t.integer  "city_id",            default: 0
    t.integer  "defence_rating",     default: 0
    t.boolean  "under_siege",        default: false
    t.integer  "year_last_taxed",    default: 0
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  add_index "settlements", ["position_id", "settlement_type"], name: "idx_settlements", using: :btree

  create_table "units", force: :cascade do |t|
    t.integer  "army_id",                              null: false
    t.string   "race",                                 null: false
    t.string   "training",           default: ""
    t.integer  "armour_id",          default: 0
    t.integer  "weapon_id",          default: 0
    t.integer  "mount_id",           default: 0
    t.integer  "transport_id",       default: 0
    t.integer  "siege_equipment_id", default: 0
    t.integer  "health",             default: 100
    t.integer  "strength_rating",    default: 0
    t.integer  "armour_rating",      default: 0
    t.integer  "range",              default: 0
    t.integer  "speed_rating",       default: 0
    t.integer  "morale_rating",      default: 0
    t.integer  "scouting_rating",    default: 0
    t.string   "tactic",             default: "Swarm"
    t.integer  "character_id",       default: 0
    t.integer  "bless_rating",       default: 0
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
  end

  add_index "units", ["army_id", "character_id", "health", "speed_rating"], name: "idx_units", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "provider",               default: "email",          null: false
    t.string   "uid",                    default: "",               null: false
    t.string   "name",                                              null: false
    t.string   "nickname"
    t.string   "image"
    t.string   "email",                  default: "",               null: false
    t.string   "encrypted_password",     default: "",               null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,                null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
    t.string   "character_type",         default: ""
    t.boolean  "setup_complete",         default: false
    t.string   "colour",                                            null: false
    t.json     "tokens"
    t.datetime "status_email_sent_at"
    t.boolean  "forem_admin",            default: false
    t.string   "forem_state",            default: "pending_review"
    t.boolean  "forem_auto_subscribe",   default: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true, using: :btree

  add_foreign_key "mailboxer_conversation_opt_outs", "mailboxer_conversations", column: "conversation_id", name: "mb_opt_outs_on_conversations_id"
  add_foreign_key "mailboxer_notifications", "mailboxer_conversations", column: "conversation_id", name: "notifications_on_conversation_id"
  add_foreign_key "mailboxer_receipts", "mailboxer_notifications", column: "notification_id", name: "receipts_on_notification_id"
end
