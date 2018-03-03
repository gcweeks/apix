class CreateUser < ActiveRecord::Migration[5.0]
  def change
    create_table :users, id: :uuid, default: 'uuid_generate_v4()' do |t|
      t.string   :fname
      t.string   :lname
      t.string   :token
      t.string   :email, default: '', null: false
      t.string   :password_digest, default: '', null: false

      t.timestamps null: false

      t.index :email, unique: true
    end
  end
end
