class Types::UserAttributes < Types::BaseInputObject
  description 'Attributes for creating a user'
  argument :username, String, required: true
  argument :fname, String, required: true
  argument :lname, String, required: true
  argument :email, String, required: true
  argument :password, String, required: true
end

