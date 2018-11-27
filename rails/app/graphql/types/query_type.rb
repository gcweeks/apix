class Types::QueryType < Types::BaseObject
  field :user, Types::UserType, null: true do
    argument :username, String, required: true
  end

  field :repo, Types::RepoType, null: true do
    argument :username, String, required: true
    argument :reponame, String, required: true
  end

  field :node, Types::NodeType, null: true do
    argument :username, String, required: true
    argument :reponame, String, required: true
    argument :id, ID, required: true
  end

  field :relationship, Types::RelationshipType, null: true do
    argument :username, String, required: true
    argument :reponame, String, required: true
    argument :id, ID, required: true
  end

  field :interface, Types::InterfaceType, null: true do
    argument :username, String, required: true
    argument :reponame, String, required: true
    argument :id, ID, required: true
  end

  def user(username:)
    User.find_by(username: username)
  end

  def repo(username:, reponame:)
    user = User.find_by(username: username)
    return nil if user.blank?
    user.repos.find_by(name: reponame)
  end

  def node(username:, reponame:, id:)
    user = User.find_by(username: username)
    return nil if user.blank?
    repo = user.repos.find_by(name: reponame)
    return nil if repo.blank?
    repo.nodes.find_by(id: id)
  end

  def relationship(username:, reponame:, id:)
    user = User.find_by(username: username)
    return nil if user.blank?
    repo = user.repos.find_by(name: reponame)
    return nil if repo.blank?
    repo.relationships.find_by(id: id)
  end

  def interface(username:, reponame:, id:)
    user = User.find_by(username: username)
    return nil if user.blank?
    repo = user.repos.find_by(name: reponame)
    return nil if repo.blank?
    repo.interfaces.find_by(id: id)
  end
end
