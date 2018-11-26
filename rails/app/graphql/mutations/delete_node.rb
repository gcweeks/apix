class Mutations::DeleteNode < Mutations::BaseMutation
  null true

  argument :reponame, String, required: true
  argument :id, ID, required: true

  field :node, Types::NodeType, null: true
  field :errors, [String], null: false

  def resolve(reponame:, id:)
    user = context[:current_user]
    if user.blank?
      return {
        node: nil,
        errors: ['Invalid token']
      }
    end

    repo = user.repos.find_by(name: reponame)
    if repo.blank?
      return {
        node: nil,
        errors: ['Repo ' + user.username + '/' + reponame + ' not found']
      }
    end

    node = repo.nodes.find_by(id: id)
    if node.blank?
      return {
        node: nil,
        errors: ['Node ' + id + ' not found']
      }
    end

    # Delete Node
    {
      node: nil,
      errors: ['Not implemented']
    }
  end
end
