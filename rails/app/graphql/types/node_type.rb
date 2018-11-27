class Types::NodeType < Types::BaseObject
  field :id, ID, null: false
  field :type, String, null: false
  field :label, String, null: false
  field :repo_id, ID, null: false
  field :properties, Types::JSON, null: false
  field :in_relationships, [Types::RelationshipType, null: true], null: false
  field :out_relationships, [Types::RelationshipType, null: true], null: false
end
