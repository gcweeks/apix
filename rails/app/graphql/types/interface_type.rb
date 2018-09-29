class Types::InterfaceType < Types::BaseObject
  description 'An interface'
  field :id, ID, null: false
  field :type, String, null: false
  field :label, String, null: false
  field :repo_id, ID, null: false
end
