class CreateRepo < ActiveRecord::Migration[5.0]
  def change
    create_table :repos, id: :uuid, default: 'uuid_generate_v4()' do |t|
      t.string :name
      t.uuid   :user_id

      t.timestamps null: false

      t.index :user_id
    end
  end
end
