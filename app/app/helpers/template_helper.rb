module TemplateHelper
  include ErrorHelper

  @neo4j_primitives = %w(string integer boolean float)

  # 'object' is a node or relation
  def self.validate_props(properties, object)
    properties.each do |key, value|
      # Verify that the properties exist in the template
      property = object.properties.find_by(key: key)
      if property.nil?
        raise BadRequest.new(property: 'does not exist (' + key.to_s + ')')
      end

      next if @neo4j_primitives.include?(property.value_type)

      # We have to dig deeper to validate against json strings
      json = eval(property.value_type)
      validate_against(value, json)
    end
    properties
  end

  def self.get_prop_types(properties, object)
    prop_types = {}
    properties.each do |key, _value|
      property = object.properties.find_by(key: key)
      prop_types[key] = property.value_type
    end
    prop_types
  end

  def self.validate_rel(rel, related_node, direction)
    # Verify rel_type exists as a template
    raise BadRequest.new(in_relationship: 'does not exist') if rel.nil?
    # Verify nid points to existing node, and that it has the proper
    # label for the given relationship according to the template
    if related_node.blank?
      errors = { related_node: 'does not exist (' + rel.rel_type + ')' }
      raise BadRequest.new(errors)
    end
    node_template = direction == :in ? rel.from_node : rel.to_node
    label = node_template.label
    scoped_label = node_template.scoped_label
    return if related_node.n.labels.include?(scoped_label.to_sym)
    raise BadRequest.new(related_node: 'invalid label (' + label + ')')
  end

  def self.validate_type(value_type)
    if value_type.is_a?(Hash)
      value_type.each { |_k, vt| validate_type(vt) }
    elsif value_type.is_a?(Array)
      unless value_type.count == 1 && validate_type(value_type[0])
        errors = { value_type: 'is invalid (' + value_type.to_s + ')' }
        raise BadRequest.new(errors)
      end
    elsif value_type.is_a?(String)
      unless validate_individual_type(value_type)
        errors = { value_type: 'is invalid (' + value_type + ')' }
        raise BadRequest.new(errors)
      end
    else
      errors = { value_type: 'is invalid (' + value_type.to_s + ')' }
      raise BadRequest.new(errors)
    end
    value_type.to_s
  end

  def self.validate_individual_type(value_type)
    @neo4j_primitives.include?(value_type)
  end

  def self.validate_against(data, template)
    if template.is_a?(Hash)
      unless data.is_a?(Hash)
        raise BadRequest.new(value_type: 'is invalid (' + data.to_s + ')')
      end
      data.each do |key, value|
        unless template[key].present?
          raise BadRequest.new(value_type: 'is invalid (' + key + ')')
        end
        validate_against(value, template[key])
      end
    elsif template.is_a?(Array)
      unless data.is_a?(Array)
        raise BadRequest.new(value_type: 'is invalid (' + data.to_s + ')')
      end
      data.each do |value|
        validate_against(value, template[0])
      end
    elsif template.is_a?(String)
      unless data.is_a?(String)
        raise BadRequest.new(value_type: 'is invalid (' + data.to_s + ')')
      end
      # End of recursion, do nothing
    else
      raise InternalServerError
    end
  end

  def self.format_type(value, value_type)
    if %w(integer float boolean).include?(value_type)
      value.to_s
    elsif value_type == 'string'
      '"' + value.to_s + '"'
    else # JSON or Array
      data = eval(value_type)
      return '"' + value.to_s.gsub('"', '\\"') + '"' unless data.is_a?(Array)
      unless %w(integer float boolean).include?(data[0])
        value = eval(value) if value.is_a?(String)
        value.map!(&:to_s)
      end
      value.to_s
    end
  end

  def self.format_node_props(props, label)
    label = label.to_s.tr('`', '')
    username, label = label.split('/')
    repo_name, label = label.split(':')
    user = User.find_by(username: username)
    raise InternalServerError if user.blank?
    # Repo name is already downcased in Neo4j, but not in SQL
    repo = user.repos.where('lower(name) = ?', repo_name).take
    raise InternalServerError if repo.blank?
    node_template = repo.nodes.find_by(label: label)
    raise InternalServerError if node_template.blank?
    props.each do |key, value|
      prop_template = node_template.properties.find_by(key: key)
      next if @neo4j_primitives.include?(prop_template.value_type)
      type = eval(prop_template.value_type)
      if type.is_a?(Array)
        unless @neo4j_primitives.include?(type[0])
          value.map! { |json| eval(json) }
        end
      else
        props[key] = eval(value)
      end
    end
    props
  end

  def self.format_rel_props(props, rel_type)
    rel_template = Relationship.find_by(rel_type: rel_type)
    props.each do |key, value|
      prop_template = rel_template.properties.find_by(key: key)
      next if @neo4j_primitives.include?(prop_template.value_type)
      type = eval(prop_template.value_type)
      if type.is_a?(Array)
        unless @neo4j_primitives.include?(type[0])
          value.map! { |json| eval(json) }
        end
      else
        props[key] = eval(value)
      end
    end
    props
  end
end
