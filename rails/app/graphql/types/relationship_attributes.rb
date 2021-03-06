class Types::RelationshipAttributes < Types::BaseInputObject
  argument :rel_type, String, required: false
  argument :to, ID, required: false
  argument :from, ID, required: false
  argument :properties, Types::JSON, required: false
end
