class Types::RelationshipType < Types::BaseObject
  description 'A relationship'
  field :id, ID, null: false
  field :rel_type, String, null: false
  # field :properties, RelationshipPropertyType, null: false
  field :to_node, Types::NodeType, null: false
  field :from_node, Types::NodeType, null: false
end
