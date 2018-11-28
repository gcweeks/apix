class Mutations::UpdateRelationship < Mutations::BaseMutation
  null true

  argument :reponame, String, required: true
  argument :id, ID, required: true
  argument :attributes, Types::RelationshipAttributes, required: true

  field :relationship, Types::RelationshipType, null: true
  field :errors, [String], null: false

  def resolve(attributes:, reponame:, id:)
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

    rel = Relationships.find_by(id: id) # TODO refine
    if rel.blank?
      return {
        relationship: nil,
        errors: ['Relationship ' + id + ' not found']
      }
    end

    query = CypherHelper.relationship_query(
      rel.from_node.scoped_label,
      rel.to_node.scoped_label,
      rel.rel_type)
    needs_query = false
    rel_type = attributes.rel_type.upcase
    props = attributes.properties

    # Update rel
    if rel_type.present? && rel_type != rel.rel_type
      query = rel.update_rel_type(query, rel_type)
      needs_query = true
    end
    if props.present?
      # Validate properties
      props.each { |_k, vt| TemplateHelper.validate_type(vt) }
      # Store validated properties as new RelationshipProperty instances
      new_props = []
      props.each do |key, value_type|
        existing_prop = rel.properties.find_by(key: key)
        if existing_prop.nil?
          value_type = value_type.to_s
          property = RelationshipProperty.new(key: key, value_type: value_type)
          raise BadRequest.new(property.errors) if property.invalid?
          new_props << property
        elsif existing_prop.value_type != value_type
          if value_type.nil?
            query = rel.destroy_property(query, property)
            property.destroy!
          else
            query = rel.update_prop_type(query, existing_prop, value_type)
            existing_prop.save!
          end
          needs_query = true
        end
      end
      # No validation issues, add new properties to rel
      new_props.each do |prop|
        prop.save!
        rel.properties << prop
      end
    end

    # Save and check for validation errors
    if rel.save
      query.exec if needs_query

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
