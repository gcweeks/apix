class AddRepoToNodes < ActiveRecord::Migration[5.0]
  def change
    add_column :nodes, :repo_id, :uuid
    add_index  :nodes, [:label, :repo_id], unique: true
  end
end
