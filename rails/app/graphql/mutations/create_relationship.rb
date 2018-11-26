class Mutations::CreateRelationship < Mutations::BaseMutation
  null true

  argument :attributes, Types::RelationshipAttributes, required: true
  argument :reponame, String, required: true

  field :repo, Types::InterfaceType, null: true
  field :errors, [String], null: false

  def resolve(attributes:, reponame:)
    user = context[:current_user]
    if user.blank?
      return {
        relationship: nil,
        errors: ['Invalid token']
      }
    end

    repo = user.repos.find_by(name: reponame)
    if repo.blank?
      return {
        relationship: nil,
        errors: ['Repo ' + user.username + '/' + reponame + ' not found']
      }
    end

    # Find to/from
    errors = []
    to = repo.nodes.find_by(id: attributes.to)
    erros.push 'Not found: to' if to.blank?
    from = repo.nodes.find_by(id: attributes.from)
    erros.push 'Not found: from' if from.blank?
    unless errors.empty?
      return {
        relationship: nil,
        errors: errors
      }
    end

    # Create new Repo
    relationship = Relationship.new(rel_type: attributes.rel_type)
    relationship.to_node = to
    relationship.from_node = from
    # TODO Properties

    # Save and check for validation errors
    if relationship.save
      # Successful creation, return the created object with no errors
      {
        relationship: relationship,
        errors: []
      }
    else
      # Failed save, return the errors to the client
      {
        relationship: nil,
        errors: relationship.errors.full_messages
      }
    end
  end
end
