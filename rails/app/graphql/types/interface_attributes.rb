class Types::InterfaceAttributes < Types::BaseInputObject
  argument :label, String, required: false
  argument :properties, Types::JSON, required: false
end
