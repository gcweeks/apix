class Node < AbstractNode
  has_many :in_relationships,
           class_name: 'Relationship',
           foreign_key: :to_node_id
  has_many :out_relationships,
           class_name: 'Relationship',
           foreign_key: :from_node_id

  def as_json(options = {})
    json = super({}.merge(options))
    # Manually call as_json (implicitly) for fields that are models
    json['properties'] = properties
    json['in_relationships'] = in_relationships
    json['out_relationships'] = out_relationships
    json
  end

  def scoped_label
    repo.user.username.downcase + '/' +
      repo.name.downcase + ':' +
      label
  end

  def update_label(query, new_label)
    new_scoped_label =
      repo.user.username.downcase + '/' +
      repo.name.downcase + ':' +
      new_label
    query = CypherHelper.add_all_nodes_update_label(query, scoped_label,
                                                    new_scoped_label)
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
