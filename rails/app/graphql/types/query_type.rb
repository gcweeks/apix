module Types
  class QueryType < Types::BaseObject
    description 'The query root of this schema'

    field :user, UserType, null: true do
      description 'Find a user by ID or username'
      argument :username, String, required: true
    end

    def user(username:)
      User.find_by(username: username)
    end
  end
end
