class Mutations::UpdateNode < Mutations::BaseMutation
  null true

  argument :reponame, String, required: true
  argument :id, ID, required: true
  argument :attributes, Types::NodeAttributes, required: true

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

    query = CypherHelper.node_query(node.scoped_label)
    needs_query = false
    label = attributes.label.downcase
    props = attributes.properties

    # Update node
    if label.present? && label != node.label
      query = node.update_label(query, label)
      needs_query = true
    end
    if props.present?
      # Validate properties
      props.each { |_k, vt| TemplateHelper.validate_type(vt) }
      # Store validated properties as new NodeProperty instances
      new_props = []
      props.each do |key, value_type|
        existing_prop = node.properties.find_by(key: key)
        if existing_prop.nil?
          value_type = value_type.to_s
          property = NodeProperty.new(key: key, value_type: value_type)
          raise BadRequest.new(property.errors) if property.invalid?
          new_props << property
        elsif existing_prop.value_type != value_type
          if value_type.nil?
            query = node.destroy_property(query, property)
            property.destroy!
          else
            query = node.update_prop_type(query, existing_prop, value_type)
            existing_prop.save!
          end
          needs_query = true
        end
      end
      # No validation issues, add new properties to node
      new_props.each do |prop|
        prop.save!
        node.properties << prop
      end
    end

    # Save and check for validation errors
    if node.save
      query.exec if needs_query

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
