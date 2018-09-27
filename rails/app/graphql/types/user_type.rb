class Types::UserType < Types::BaseObject
  description 'A user'
  field :id,       ID,     null: false
  field :username, String, null: false
  field :fname,    String, null: false
  field :lname,    String, null: false
  field :token,    String, null: true
  field :email,    String, null: false

  field :uname, String, null: false, hash_key: 'username', description: 'A description'
  field :dep, String, null: true, method: :dep_method, deprecation_reason: 'This is deprecated'
  field :fullname, String, null: false
  field :namearr, [String, null: true], null: false, method: :arr_method
  # field :add2, Integer, null: false do
  #   argument :number, Integer, required: false, default_value: false
  # end

  # field :items, Types::TodoItem.connection_type, "Tasks on this list", null: false do
  #   argument :status, TodoStatus, "Restrict items to this status", required: false
  # end

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
