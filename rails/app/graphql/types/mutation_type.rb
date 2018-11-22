class Types::MutationType < Types::BaseObject
  field :create_user, mutation: Mutations::CreateUser
  field :update_user, mutation: Mutations::UpdateUser
  field :update_prefs, mutation: Mutations::UpdatePrefs
end
