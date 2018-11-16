class Mutations::CreateUser < Mutations::BaseMutation
  null true

  argument :attributes, Types::UserAttributes, required: true

  field :user, Types::UserType, null: true
  field :errors, [String], null: false

  def resolve(attributes:)
    # Create new User
    user = User.new
    user.username = attributes.username
    user.fname = attributes.fname
    user.lname = attributes.lname
    user.email = attributes.email
    user.password = attributes.password
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
