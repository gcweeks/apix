class Types::UserType < Types::BaseObject
  field :id, ID, null: false
  field :username, String, null: false
  field :fname, String, null: false
  field :lname, String, null: false
  field :token, String, null: true do
    argument :password, String, required: true
  end
  field :email, String, null: false
  field :repos, [Types::RepoType, null: true], null: false
  field :reposConnection, Types::RepoType.connection_type, null: false, hash_key: 'repos'
  field :repo, Types::RepoType, null: true do
    argument :id, String, required: false, default_value: nil
    argument :name, String, required: false, default_value: nil
  end
  field :preferences, Types::JSON, null: false

  def token(password:)
    # Request with hash form because 'token' could be called during User
    # creation, where @object is still a Hash and not a User.
    username = @object['username']
    requested_user = User.find_by(username: username)
    if requested_user
      user = requested_user.try(:authenticate, password)
      return user.token if user
    end

    nil
  end

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
  # def search_posts(**args)
  #   if args[:category]
  #     Post.where(category: args[:category]).limit(10)
  #   else
  #     Post.all.limit(10)
  #   end
  # end
  # field :search_posts, [PostType], null: false do
  #   argument :category, String, required: false, default_value: "Programming"
  # end
  # argument :start_date, String, required: true, prepare: ->(startDate, ctx) {
  #   downcase
  # }

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
