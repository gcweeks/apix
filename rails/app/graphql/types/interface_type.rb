class Types::InterfaceType < Types::BaseObject
  field :id, ID, null: false
  field :type, String, null: false
  field :label, String, null: false
  field :repo_id, ID, null: false
  field :properties, [Types::PropertyType, null:true], null: false
end
