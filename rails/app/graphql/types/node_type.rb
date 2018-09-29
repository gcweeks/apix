class Types::NodeType < Types::BaseObject
  description 'A node'
  field :id, ID, null: false
  field :type, String, null: false
  field :label, String, null: false
  field :repo_id, ID, null: false
  field :in_relationships, [Types::RelationshipType, null: true], null: false
  field :out_relationships, [Types::RelationshipType, null: true], null: false
end
