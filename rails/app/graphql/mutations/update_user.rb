class Mutations::UpdateUser < Mutations::BaseMutation
  null true

  argument :attributes, Types::UserAttributes, required: true

  field :user, Types::UserType, null: true
  field :errors, [String], null: false

  def resolve(attributes:)
    user = context[:current_user]
    if user.blank?
      return {
        user: nil,
        errors: ['Invalid token']
      }
    end

    # Update User
    attributes.each do |attribute|
      user[attribute[0]] = attribute[1]
    end

    # Save and check for validation errors
    if user.save
      # Successful creation, return the created object with no errors
      {
        user: user,
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
