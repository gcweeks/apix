class Mutations::DeleteRelationship < Mutations::BaseMutation
  null true

  argument :reponame, String, required: true
  argument :id, ID, required: true

  field :errors, [String], null: false

  def resolve(reponame:, id:)
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

    relationship = repo.relationships.find_by(id: id)
    if relationship.blank?
      return {
        errors: ['Relationship ' + id + ' not found']
      }
    end

    # Delete Relationship
    {
      errors: ['Not implemented']
    }
  end
end
