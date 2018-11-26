class Mutations::UpdateRepo < Mutations::BaseMutation
  null true

  argument :attributes, Types::RepoAttributes, required: true
  argument :reponame, String, required: true

  field :repo, Types::RepoType, null: true
  field :errors, [String], null: false

  def resolve(attributes:, reponame:)
    user = context[:current_user]
    if user.blank?
      return {
        repo: nil,
        errors: ['Invalid token']
      }
    end

    repo = user.repos.find_by(name: reponame)
    if repo.blank?
      return {
        repo: nil,
        errors: ['Repo ' + user.username + '/' + reponame + ' not found']
      }
    end

    # Update Repo
    attributes.each do |attribute|
      repo[attribute[0]] = attribute[1]
    end

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
