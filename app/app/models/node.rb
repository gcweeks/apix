class Node < ApplicationRecord
  has_many :in_relationships,
           class_name: 'Relationship',
           foreign_key: :to_node_id
  has_many :out_relationships,
           class_name: 'Relationship',
           foreign_key: :from_node_id
  has_many :properties, class_name: 'NodeProperty'

  validates :label, presence: true, uniqueness: true

  def as_json(options = {})
    json = super({}.merge(options))
    # Manually call as_json (implicitly) for fields that are models
    json['properties'] = properties
    json['in_relationships'] = in_relationships
    json['out_relationships'] = out_relationships
    json
  end

  def update_label(query, new_label)
    query = CypherHelper.add_all_nodes_update_label(query, label, new_label)
    self.label = new_label
    query
  end

  def update_prop_type(query, property, new_type)
    query = CypherHelper.add_all_nodes_update_prop_type(query,
                                                        property.key,
                                                        property.value_type,
                                                        new_type)
    property.value_type = new_type
    query
  end

  def destroy_property(query, property)
    CypherHelper.add_all_nodes_remove_prop(query, property.key)
  end

  def destroy_instances(query)
    CypherHelper.add_all_nodes_destroy(query)
  end
end
