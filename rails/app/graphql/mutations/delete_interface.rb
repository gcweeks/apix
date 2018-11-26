class Mutations::DeleteInterface < Mutations::BaseMutation
  null true

  argument :reponame, String, required: true
  argument :id, ID, required: true

  field :interface, Types::InterfaceType, null: true
  field :errors, [String], null: false

  def resolve(reponame:, id:)
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

    # Delete Interface
    {
      interface: nil,
      errors: ['Not implemented']
    }
  end
end
