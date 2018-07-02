class InitialMigration < ActiveRecord::Migration[5.0]
  def change
    enable_extension 'plpgsql'
    enable_extension 'uuid-ossp'

    create_table :abstract_nodes, id: :uuid, default: 'uuid_generate_v4()' do |t|
      t.string :type,  null: false # STI
      t.string :label, null: false
      t.uuid   :repo_id

      t.timestamps null: false

      t.index [:label, :repo_id], unique: true
    end

    create_table :node_properties, id: :uuid, default: 'uuid_generate_v4()' do |t|
      t.string :key,        null: false
      t.string :value_type, null: false
      t.uuid   :abstract_node_id

      t.timestamps null: false

      t.index :abstract_node_id
    end

    create_table :relationships, id: :uuid, default: 'uuid_generate_v4()' do |t|
      t.string :rel_type, null: false
      t.uuid   :to_node_id
      t.uuid   :from_node_id

      t.timestamps null: false

      t.index :to_node_id
      t.index :from_node_id
    end

    create_table :relationship_properties, id: :uuid, default: 'uuid_generate_v4()' do |t|
      t.string :key,        null: false
      t.string :value_type, null: false
      t.uuid   :relationship_id

      t.timestamps null: false

      t.index :relationship_id
    end

    create_table :users, id: :uuid, default: 'uuid_generate_v4()' do |t|
      t.string :username, null: false
      t.string :fname,    null: false
      t.string :lname,    null: false
      t.string :token
      t.string :email,    null: false
      t.string :password_digest

      t.timestamps null: false

      t.index 'lower(username) varchar_pattern_ops', unique: true
      t.index :email, unique: true
    end

    create_table :repos, id: :uuid, default: 'uuid_generate_v4()' do |t|
      t.string :name, null: false
      t.uuid   :user_id

      t.timestamps null: false

      t.index :user_id
    end
  end
end
