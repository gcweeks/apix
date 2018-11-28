class Mutations::UpdateInterface < Mutations::BaseMutation
  null true

  argument :reponame, String, required: true
  argument :id, ID, required: true
  argument :attributes, Types::InterfaceAttributes, required: true

  field :interface, Types::InterfaceType, null: true
  field :errors, [String], null: false

  def resolve(attributes:, reponame:, id:)
    user = context[:current_user]
    if user.blank?
      return {
        interface: nil,
        errors: ['Invalid token']
      }
    end

    repo = user.repos.find_by(name: reponame)
    if repo.blank?
      return {
        interface: nil,
        errors: ['Repo ' + user.username + '/' + reponame + ' not found']
      }
    end

    interface = repo.interfaces.find_by(id: id)
    if interface.blank?
      return {
        interface: nil,
        errors: ['Interface ' + id + ' not found']
      }
    end

    label = attributes.label.downcase
    props = attributes.properties

    # Update interface
    interface.label = label if label.present?
    if props.present?
      # Validate properties
      props.each { |_k, vt| TemplateHelper.validate_type(vt) }
      # Store validated properties as new NodeProperty instances
      new_props = []
      props.each do |key, value_type|
        existing_prop = interface.properties.find_by(key: key)
        if existing_prop.nil?
          value_type = value_type.to_s
          property = NodeProperty.new(key: key, value_type: value_type)
          raise BadRequest.new(property.errors) if property.invalid?
          new_props << property
        elsif existing_prop.value_type != value_type
          if value_type.nil?
            property.destroy!
          else
            existing_prop.value_type = value_type
            existing_prop.save!
          end
        end
      end
      # No validation issues, add new properties to interface
      new_props.each do |prop|
        prop.save!
        interface.properties << prop
      end
    end

    # Save and check for validation errors
    if interface.save
      # Successful creation, return the created object with no errors
      {
        interface: interface,
        errors: []
      }
    else
      # Failed save, return the errors to the client
      {
        interface: nil,
        errors: interface.errors.full_messages
      }
    end
  end
end
