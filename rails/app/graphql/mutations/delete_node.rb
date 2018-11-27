class Mutations::DeleteNode < Mutations::BaseMutation
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

    node = repo.nodes.find_by(id: id)
    if node.blank?
      return {
        errors: ['Node ' + id + ' not found']
      }
    end

    # Delete Node
    {
      errors: ['Not implemented']
    }
  end
end
