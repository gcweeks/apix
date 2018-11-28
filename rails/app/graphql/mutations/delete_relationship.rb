class Mutations::DeleteRelationship < Mutations::BaseMutation
  null true

  argument :reponame, String, required: true
  argument :id, ID, required: true

  field :errors, [String], null: false

  def resolve(reponame:, id:)
    user = context[:current_user]
    if user.blank?
      return {
        errors: ['Invalid token']
      }
    end

    repo = user.repos.find_by(name: reponame)
    if repo.blank?
      return {
        errors: ['Repo ' + user.username + '/' + reponame + ' not found']
      }
    end

    rel = repo.relationships.find_by(id: id)
    if rel.blank?
      return {
        errors: ['Relationship ' + id + ' not found']
      }
    end

    # Delete Relationship
    query = CypherHelper.relationship_query(
      rel.from_node.scoped_label,
      rel.to_node.scoped_label,
      rel.rel_type)

    # Destroy all instances. This call will also destroy the template itself
    # when done.
    rel.destroy_instances(query).exec
    rel.destroy!

    {
      errors: nil
    }
  end
end
