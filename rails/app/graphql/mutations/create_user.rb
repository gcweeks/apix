class Mutations::CreateUser < Mutations::BaseMutation
  null true

  argument :attributes, Types::UserAttributes, required: true
  argument :password, String, required: true

  field :user, Types::UserType, null: true
  field :errors, [String], null: false

  def resolve(attributes:, password:)
    # Create new User
    user = User.new(
      username: attributes.username,
      fname: attributes.fname,
      lname: attributes.lname,
      email: attributes.email,
      password: password
    )
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
