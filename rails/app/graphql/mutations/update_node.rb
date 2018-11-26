class Mutations::UpdateNode < Mutations::BaseMutation
  null true

  argument :attributes, Types::NodeAttributes, required: true
  argument :reponame, String, required: true
  argument :id, ID, required: true

  field :node, Types::NodeType, null: true
  field :errors, [String], null: false

  def resolve(attributes:, reponame:, id:)
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

    # Update Node
    attributes.each do |attribute|
      node[attribute[0]] = attribute[1]
    end

    # Save and check for validation errors
    if node.save
      # Successful creation, return the created object with no errors
      {
        node: node,
        errors: []
      }
    else
      # Failed save, return the errors to the client
      {
        node: nil,
        errors: node.errors.full_messages
      }
    end
  end
end
