class Types::RepoType < Types::BaseObject
  description 'A repo'
  field :id, ID, null: false
  field :name, String, null: false
  field :user_id, ID, null: false
  field :nodes, [Types::NodeType, null: true], null: false
  field :node, Types::NodeType, null: true do
    argument :id, String, required: false, default_value: nil
    argument :label, String, required: false, default_value: nil
  end
  field :interfaces, [Types::InterfaceType, null: true], null: false
  field :interface, Types::InterfaceType, null: true do
    argument :id, String, required: false, default_value: nil
    argument :label, String, required: false, default_value: nil
  end

  def node(id:, label:)
    if id.present?
      @object.nodes.find_by(id: id)
    elsif label.present?
      @object.nodes.find_by(label: label)
    else
      msg = 'Field \'node\' is missing one of the following arguments: id, label'
      GraphQL::ExecutionError.new(msg)
    end
  end

  def node(id:, label:)
    if id.present?
      @object.interfaces.find_by(id: id)
    elsif label.present?
      @object.interfaces.find_by(label: label)
    else
      msg = 'Field \'node\' is missing one of the following arguments: id, label'
      GraphQL::ExecutionError.new(msg)
    end
  end
end
