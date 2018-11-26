class Mutations::CreateRepo < Mutations::BaseMutation
  null true

  argument :attributes, Types::RepoAttributes, required: true

  field :repo, Types::RepoType, null: true
  field :errors, [String], null: false

  def resolve(attributes:)
    user = context[:current_user]
    if user.blank?
      return {
        repo: nil,
        errors: ['Invalid token']
      }
    end

    # Create new Repo
    repo = Repo.new(name: attributes.name)
    repo.user = user

    # Save and check for validation errors
    if repo.save
      # Successful creation, return the created object with no errors
      {
        repo: repo,
        errors: []
      }
    else
      # Failed save, return the errors to the client
      {
        repo: nil,
        errors: repo.errors.full_messages
      }
    end
  end
end
