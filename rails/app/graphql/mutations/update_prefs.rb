class Mutations::UpdatePrefs < Mutations::BaseMutation
  null true

  argument :username, String, required: true
  argument :token, String, required: true
  argument :preferences, String, required: true

  field :user, Types::UserType, null: true
  field :errors, [String], null: false

  def resolve(username:, token:, preferences:)
    user = User.where(username: username).first
    if user.blank?
      return {
        user: nil,
        errors: ['User not found']
      }
    end
    unless user.token == token
      return {
        user: nil,
        errors: ['Invalid token']
      }
    end

    # Update Prefs
    user.preferences = preferences if preferences.present?

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
