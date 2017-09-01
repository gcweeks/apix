module ApiHelper
  include CypherHelper
  include TemplateHelper

  def format_node(node_struct)
    node_struct = node_struct.to_h
    node = node_struct[:n]
    label = node.labels[0]
    ret = {
      properties: TemplateHelper.format_node_props(node.props, label),
      label: label,
      nid: node.neo_id
    }
    rel = node_struct[:r]
    return ret unless rel
    ret[:relationships] = [{
      properties: TemplateHelper.format_rel_props(rel.props, rel.rel_type),
      rel_type: rel.rel_type,
      from_nid: rel.start_node_neo_id,
      to_nid: rel.end_node_neo_id
    }]
    ret
  end

  def format_nodes(node_struct_arr)
    nodes = {}
    node_struct_arr.each do |node_struct|
      node = format_node(node_struct)
      if nodes[node[:nid]].blank?
        nodes[node[:nid]] = node
      else
        nodes[node[:nid]][:relationships] += node[:relationships]
      end
    end
    nodes.values
  end

  def perform_in_out(query, l, r)
    %i(in out).each do |direction|
      next if r[direction].blank?
      r[direction].each do |rel_json|
        query = l.call(direction, query, rel_json)
      end
    end
    query
  end

  def add_relationships(query, r, node)
    per_direction = lambda do |direction, dir_query, rel_json|
      if rel_json[:nid].blank?
        raise BadRequest.new(nid: 'required (' + rel_json[:rel_type] + ')')
      end
      create_relationship(direction, dir_query, node, rel_json[:rel_type],
                          rel_json[:nid], rel_json[:properties])
    end
    perform_in_out(query, per_direction, r)
  end

  def update_relationships(query, r, node)
    per_direction = lambda do |direction, dir_query, rel_json|
      if rel_json[:nid].blank?
        raise BadRequest.new(nid: 'required (' + rel_json[:rel_type] + ')')
      end

      # Get relationship instance
      rel_query = CypherHelper.add_get_relationship(direction, dir_query,
                                                    rel_json[:rel_type],
                                                    rel_json[:nid])
      rel = rel_query.return(:r).first
      query = if rel.blank?
                # Create new relationship
                create_relationship(direction, dir_query, node,
                                    rel_json[:rel_type], rel_json[:nid],
                                    rel_json[:properties])
              else
                # Update existing relationship
                set_relationship(direction, dir_query, node, rel.r,
                                 rel_json[:properties])
              end
      query
    end
    perform_in_out(query, per_direction, r)
  end

  def destroy_relationships(query, r, node)
    per_direction = lambda do |direction, dir_query, rel_json|
      if rel_json[:nid].blank?
        raise BadRequest.new(nid: 'required (' + rel_json[:rel_type] + ')')
      end

      props = rel_json[:properties]
      if props.present? && !props.respond_to?('each')
        raise BadRequest.new(properties: 'bad format')
      end
      # Get relationship instance
      rel_query = CypherHelper.add_get_relationship(direction, dir_query,
                                                    rel_json[:rel_type],
                                                    rel_json[:nid])
      rel = rel_query.return(:r).first
      if rel.blank?
        errors = {
          relationship: 'does not exist (' + rel_json[:rel_type] + ')'
        }
        raise BadRequest.new(errors)
      elsif props.blank?
        # Delete relationship
        query = delete_relationship(direction, dir_query, rel.r)
      else
        # Remove relationship properties
        query = remove_relationship_props(direction, dir_query, node, rel.r,
                                          props)
      end
      query
    end
    perform_in_out(query, per_direction, r)
  end

  def create_relationship(direction, query, node, rel_type, other_nid, props)
    # Verify that relationship actually exists as a template, and that
    # the nid points to a proper node for that relationship
    rel_template = if direction == :in
                     node.in_relationships.find_by(rel_type: rel_type)
                   else
                     node.out_relationships.find_by(rel_type: rel_type)
                   end
    related_node = CypherHelper.get_node(other_nid).return(:n).first
    TemplateHelper.validate_rel(rel_template, related_node, direction)
    # Verify that the properties exist in the template
    props = if props.blank? || !props.respond_to?('each')
              {}
            else
              props.to_unsafe_h
            end
    props = TemplateHelper.validate_props(props, rel_template)
    prop_types = TemplateHelper.get_prop_types(props, rel_template)
    props.each { |k, v| props[k] = v.to_s }
    # Add relationship to query and return result
    CypherHelper.add_create_relationship(direction, query, rel_type, other_nid,
                                         props, prop_types)
  end

  def set_relationship(direction, query, node, rel, props)
    return query if props.blank? || !props.respond_to?('each')
    rel_type = rel.rel_type.to_s
    if direction == :in
      rel_template = node.in_relationships.find_by(rel_type: rel_type)
      other_nid = rel.start_node_neo_id
    else
      rel_template = node.out_relationships.find_by(rel_type: rel_type)
      other_nid = rel.end_node_neo_id
    end
    props = props.to_unsafe_h
    props = TemplateHelper.validate_props(props, rel_template)
    prop_types = TemplateHelper.get_prop_types(props, rel_template)
    props.each { |k, v| props[k] = v.to_s }
    CypherHelper.add_set_relationship(direction, query, rel_type, other_nid,
                                      props, prop_types)
  end

  def delete_relationship(direction, query, rel)
    rel_type = rel.rel_type.to_s
    other_nid = if direction == :in
                  rel.start_node_neo_id
                else
                  rel.end_node_neo_id
                end
    CypherHelper.add_delete_relationship(direction, query, rel_type, other_nid)
  end

  def remove_relationship_props(direction, query, node, rel, props)
    rel_type = rel.rel_type.to_s
    if direction == :in
      rel_template = node.in_relationships.find_by(rel_type: rel_type)
      other_nid = rel.start_node_neo_id
    else
      rel_template = node.out_relationships.find_by(rel_type: rel_type)
      other_nid = rel.end_node_neo_id
    end
    props.each do |key|
      # Verify that the properties exist in the template
      property = rel_template.properties.find_by(key: key)
      if property.blank?
        raise BadRequest.new(property: 'does not exist (' + key.to_s + ')')
      end
    end
    CypherHelper.add_remove_relationship_props(direction, query, rel_type,
                                               other_nid, props)
  end
end
