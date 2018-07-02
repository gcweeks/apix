class Relationship < ApplicationRecord
  has_many :properties, class_name: 'RelationshipProperty'
  belongs_to :to_node, class_name: 'Node'
  belongs_to :from_node, class_name: 'Node'

  validates :rel_type, presence: true, uniqueness: {
    scope: [:to_node, :from_node]
  }
  validates :to_node, presence: true
  validates :from_node, presence: true

  def as_json(options = {})
    json = super({}.merge(options))
    # Manually call as_json (implicitly) for fields that are models
    json['properties'] = properties
    json
  end

  def update_rel_type(query, new_rel_type)
    query = CypherHelper.add_all_rels_update_rel_type(query, new_rel_type)
    self.rel_type = new_rel_type
    query
  end

  def update_prop_type(query, property, new_type)
    query = CypherHelper.add_all_rels_update_prop_type(query,
                                                       property.key,
                                                       property.value_type,
                                                       new_type)
    property.value_type = new_type
    query
  end

  def destroy_property(property)
    CypherHelper.add_all_rels_remove_prop(query, property.key)
  end

  def destroy_instances(query)
    CypherHelper.add_all_rels_destroy(query)
  end
end
