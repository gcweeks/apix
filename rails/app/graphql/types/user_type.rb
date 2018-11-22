class Types::UserType < Types::BaseObject
  description 'A user'
  field :id, ID, null: false
  field :username, String, null: false
  field :fname, String, null: false
  field :lname, String, null: false
  field :token, String, null: true
  field :email, String, null: false
  field :repos, [Types::RepoType, null: true], null: false
  field :repo, Types::RepoType, null: true do
    argument :id, String, required: false, default_value: nil
    argument :name, String, required: false, default_value: nil
  end
  field :preferences, String, null: false

  def repo(id:, name:)
    if id.present?
      @object.repos.find_by(id: id)
    elsif name.present?
      @object.repos.find_by(name: name)
    else
      msg = 'Field \'repo\' is missing one of the following arguments: id, name'
      GraphQL::ExecutionError.new(msg)
    end
  end

  # Examples

  field :uname, String, null: false, hash_key: 'username', description: 'A description'
  field :dep, String, null: true, method: :dep_method, deprecation_reason: 'This is deprecated'
  field :fullname, String, null: false
  field :namearr, [String, null: true], null: false, method: :arr_method
  # err = { field: "fluffy", field2: "fluffier" }
  # GraphQL::ExecutionError.new("some message", options: err)

  def fullname
    object.fname + ' ' + object.lname
  end

  def dep_method
    'depped'
  end

  def arr_method
    [object.fname, object.lname]
  end
end
