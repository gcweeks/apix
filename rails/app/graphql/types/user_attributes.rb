class Types::UserAttributes < Types::BaseInputObject
  argument :username,    String, required: false
  argument :fname,       String, required: false
  argument :lname,       String, required: false
  argument :email,       String, required: false
  argument :preferences, String, required: false
end
