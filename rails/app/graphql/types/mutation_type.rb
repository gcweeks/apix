class Types::MutationType < Types::BaseObject
  field :create_user, mutation: Mutations::CreateUser
  field :update_user, mutation: Mutations::UpdateUser

  field :create_repo, mutation: Mutations::CreateRepo
  field :update_repo, mutation: Mutations::UpdateRepo
  field :delete_repo, mutation: Mutations::DeleteRepo

  field :create_node, mutation: Mutations::CreateNode
  field :update_node, mutation: Mutations::UpdateNode
  field :delete_node, mutation: Mutations::DeleteNode

  field :create_relationship, mutation: Mutations::CreateRelationship
  field :update_relationship, mutation: Mutations::UpdateRelationship
  field :delete_relationship, mutation: Mutations::DeleteRelationship

  field :create_interface, mutation: Mutations::CreateInterface
  field :update_interface, mutation: Mutations::UpdateInterface
  field :delete_interface, mutation: Mutations::DeleteInterface
end
