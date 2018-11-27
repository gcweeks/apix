class Mutations::CreateInterface < Mutations::BaseMutation
  null true

  argument :reponame, String, required: true
  argument :attributes, Types::InterfaceAttributes, required: true

  field :interface, Types::InterfaceType, null: true
  field :errors, [String], null: false

  def resolve(attributes:, reponame:)
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

    # Create new Interface
    interface = Interface.new(name: attributes.label.downcase)
    # TODO Properties

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