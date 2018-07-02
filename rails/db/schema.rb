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

ActiveRecord::Schema.define(version: 20180701163300) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "abstract_nodes", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "type",       null: false
    t.string   "label",      null: false
    t.uuid     "repo_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["label", "repo_id"], name: "index_abstract_nodes_on_label_and_repo_id", unique: true, using: :btree
  end

  create_table "node_properties", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "key",              null: false
    t.string   "value_type",       null: false
    t.uuid     "abstract_node_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.index ["abstract_node_id"], name: "index_node_properties_on_abstract_node_id", using: :btree
  end

  create_table "relationship_properties", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "key",             null: false
    t.string   "value_type",      null: false
    t.uuid     "relationship_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.index ["relationship_id"], name: "index_relationship_properties_on_relationship_id", using: :btree
  end

  create_table "relationships", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "rel_type",     null: false
    t.uuid     "to_node_id"
    t.uuid     "from_node_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["from_node_id"], name: "index_relationships_on_from_node_id", using: :btree
    t.index ["to_node_id"], name: "index_relationships_on_to_node_id", using: :btree
  end

  create_table "repos", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "name",       null: false
    t.uuid     "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_repos_on_user_id", using: :btree
  end

  create_table "users", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "username",        null: false
    t.string   "fname",           null: false
    t.string   "lname",           null: false
    t.string   "token"
    t.string   "email",           null: false
    t.string   "password_digest"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.index "lower((username)::text) varchar_pattern_ops", name: "index_users_on_lower_username_varchar_pattern_ops", unique: true, using: :btree
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
  end

end
