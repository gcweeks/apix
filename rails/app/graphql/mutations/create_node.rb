class Mutations::CreateNode < Mutations::BaseMutation
  null true

  argument :attributes, Types::NodeAttributes, required: true
  argument :reponame, String, required: true

  field :node, Types::NodeType, null: true
  field :errors, [String], null: false

  def resolve(attributes:, reponame:)
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

    # Create new Repo
    node = Node.new(label: attributes.label.downcase)
    # TODO Properties

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
