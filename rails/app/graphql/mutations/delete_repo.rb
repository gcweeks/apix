class Mutations::DeleteRepo < Mutations::BaseMutation
  null true

  argument :reponame, String, required: true

  field :errors, [String], null: false

  def resolve(reponame:)
    user = context[:current_user]
    if user.blank?
      return {
        errors: ['Invalid token']
      }
    end

    repo = user.repos.find_by(name: reponame)
    if repo.blank?
      return {
        errors: ['Repo ' + user.username + '/' + reponame + ' not found']
      }
    end

    # Delete Repo
    {
      errors: ['Not implemented']
    }
  end
end
