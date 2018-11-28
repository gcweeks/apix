class Mutations::CreateNode < Mutations::BaseMutation
  null true

  argument :reponame, String, required: true
  argument :attributes, Types::NodeAttributes, required: true

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

    # Create new Node
    node = Node.new(label: attributes.label.downcase)
    node.repo = repo
    if attributes.properties.present?
      # Validate properties
      attributes.properties.each { |_k, vt| TemplateHelper.validate_type(vt) }
      # Store validated properties as new NodeProperty instances
      new_props = []
      attributes.properties.each do |key, value_type|
        value_type = value_type.to_s
        property = NodeProperty.new(key: key, value_type: value_type)
        raise BadRequest.new(property.errors) if property.invalid?
        new_props << property
      end
      # No validation issues, add new properties to node
      new_props.each do |prop|
        prop.save!
        node.properties << prop
      end
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
