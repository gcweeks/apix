class Mutations::UpdateRelationship < Mutations::BaseMutation
  null true

  argument :attributes, Types::RelationshipAttributes, required: true
  argument :reponame, String, required: true
  argument :id, ID, required: true

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

    relationship = repo.relationships.find_by(id: id)
    if relationship.blank?
      return {
        relationship: nil,
        errors: ['Relationship ' + id + ' not found']
      }
    end

    # Update Relationship
    attributes.each do |attribute|
      relationship[attribute[0]] = attribute[1]
    end

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
