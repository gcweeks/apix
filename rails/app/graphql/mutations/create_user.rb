class Mutations::CreateUser < GraphQL::Schema::RelayClassicMutation
  null true

  argument :username, String, required: true
  argument :fname, String, required: true
  argument :lname, String, required: true
  argument :email, String, required: true
  argument :password, String, required: true

  field :user, Types::UserType, null: true
  field :errors, [String], null: false

  def resolve(username:, fname:, lname:, email:, password:)
    # Create new User
    user = User.new
    user.username = username
    user.fname = fname
    user.lname = lname
    user.email = email
    user.password = password
    # Generate the User's auth token
    user.generate_token
    # Save and check for validation errors
    if user.save
      # Successful creation, return the created object with no errors
      {
        user: user.with_token,
        errors: []
      }
    else
      # Failed save, return the errors to the client
      {
        user: nil,
        errors: user.errors.full_messages
      }
    end
  end
end
