class Types::RelationshipType < Types::BaseObject
  field :id, ID, null: false
  field :rel_type, String, null: false
  field :properties, Types::JSON, null: false
  field :to_node, Types::NodeType, null: false
  field :from_node, Types::NodeType, null: false
end
