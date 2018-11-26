class Mutations::UpdateInterface < Mutations::BaseMutation
  null true

  argument :attributes, Types::InterfaceAttributes, required: true
  argument :reponame, String, required: true
  argument :id, ID, required: true

  field :Interface, Types::InterfaceType, null: true
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

    # Update Interface
    attributes.each do |attribute|
      interface[attribute[0]] = attribute[1]
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
