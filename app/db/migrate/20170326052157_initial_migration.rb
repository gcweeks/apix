class InitialMigration < ActiveRecord::Migration[5.0]
  def change
    enable_extension 'plpgsql'
    enable_extension 'uuid-ossp'

    create_table :nodes, id: :uuid, default: 'uuid_generate_v4()' do |t|
      t.string :label

      t.timestamps
    end

    create_table :node_properties, id: :uuid, default: 'uuid_generate_v4()' do |t|
      t.string :key
      t.string :value_type
      t.uuid   :node_id

      t.timestamps

      t.index :node_id
    end

    create_table :relationship_properties, id: :uuid, default: 'uuid_generate_v4()' do |t|
      t.string :key
      t.string :value_type
      t.uuid   :relationship_id

      t.timestamps

      t.index :relationship_id
    end

    create_table :relationships, id: :uuid, default: 'uuid_generate_v4()' do |t|
      t.string :rel_type
      t.uuid   :to_node_id
      t.uuid   :from_node_id

      t.timestamps

      t.index :to_node_id
      t.index :from_node_id
    end
  end
end
