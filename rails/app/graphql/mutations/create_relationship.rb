class Mutations::CreateRelationship < Mutations::BaseMutation
  null true

  argument :reponame, String, required: true
  argument :attributes, Types::RelationshipAttributes, required: true

  field :relationship, Types::RelationshipType, null: true
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

    # Create new Relationship
    rel = Relationship.new(rel_type: attributes.rel_type.upcase)
    rel.to_node = to
    rel.from_node = from
    if attributes.properties.present?
      # Validate properties
      attributes.properties.each { |_k, vt| TemplateHelper.validate_type(vt) }
      # Store validated properties as new NodeProperty instances
      new_props = []
      attributes.properties.each do |key, value_type|
        value_type = value_type.to_s
        property = RelationshipProperty.new(key: key, value_type: value_type)
        raise BadRequest.new(property.errors) if property.invalid?
        new_props << property
      end
      # No validation issues, add new properties to rel
      new_props.each do |prop|
        prop.save!
        rel.properties << prop
      end
    end

    # Save and check for validation errors
    if rel.save
      # Successful creation, return the created object with no errors
      {
        relationship: rel,
        errors: []
      }
    else
      # Failed save, return the errors to the client
      {
        relationship: nil,
        errors: rel.errors.full_messages
      }
    end
  end
end
