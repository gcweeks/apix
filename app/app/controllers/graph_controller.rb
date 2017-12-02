class GraphController < ApplicationController
  include GraphHelper
  include ErrorHelper

  def index
    query = CypherHelper.get_nodes(params[:node_label])
    node_struct_arr = CypherHelper.add_relationships(query).return(:n, :r)
    render json: format_nodes(node_struct_arr), status: :ok
  end

  def create
    node = Node.find_by(label: params[:node_label])
    raise NotFound unless node

    # Properties
    if params[:properties].blank? || !params[:properties].respond_to?('each')
      raise BadRequest.new(property: 'required')
    end
    props = params[:properties].to_unsafe_h
    raise BadRequest.new(property: 'required') if props.size.zero?
    props = TemplateHelper.validate_props(props, node)
    prop_types = TemplateHelper.get_prop_types(props, node)
    # Start building CREATE query
    query = CypherHelper.create_node(node.label, props, prop_types)

    # Relationships
    rel = params[:relationships]
    if rel.present? && !(rel[:in].blank? && rel[:out].blank?)
      query = add_relationships(query, rel, node)
      node_struct = query.return(:n, :r).first
    else
      node_struct = query.return(:n).first
    end

    render json: format_node(node_struct), status: :ok
  end

  def search
    node = Node.find_by(label: params[:node_label])
    raise NotFound if node.blank?
    if params[:properties].blank? || !params[:properties].respond_to?('each') ||
       params[:properties].to_unsafe_h.size.zero?

      raise BadRequest.new(property: 'required')
    end
    page = params[:page].blank? ? 1 : params[:page].to_i
    raise BadRequest.new(page: 'invalid') if page <= 0
    props = params[:properties].to_unsafe_h
    props = TemplateHelper.validate_props(props, node)
    prop_types = TemplateHelper.get_prop_types(props, node)
    props.each { |k, v| props[k] = v.to_s }
    node_struct_arr = CypherHelper.search(params[:node_label],
                                          props,
                                          prop_types,
                                          page).return(:n, :r)
    render json: format_nodes(node_struct_arr), status: :ok
  end

  def show
    node_id = params[:id].to_i.to_s
    raise BadRequest.new(id: 'invalid') if node_id != params[:id]
    query = CypherHelper.get_node(node_id)
    node_struct = CypherHelper.add_relationships(query).return(:n, :r).first
    raise NotFound if node_struct.nil?
    render json: format_node(node_struct), status: :ok
  end

  def update
    node_id = params[:id].to_i.to_s
    raise BadRequest.new(id: 'invalid') if node_id != params[:id]
    node = Node.find_by(label: params[:node_label])
    raise NotFound if node.nil?
    query = CypherHelper.get_node(node_id)
    node_instance = query.return(:n).first
    raise NotFound if node_instance.nil?

    # Properties
    props = params[:properties]
    props = if props.blank? || !props.respond_to?('each')
              {}
            else
              props.to_unsafe_h
            end
    props = TemplateHelper.validate_props(props, node)
    prop_types = TemplateHelper.get_prop_types(props, node)
    props.each { |k, v| props[k] = v.to_s }
    # Start building SET query
    query = CypherHelper.set_node(node_id, props, prop_types)

    # Relationships
    rel = params[:relationships]
    if rel.present? && !(rel[:in].blank? && rel[:out].blank?)
      query = update_relationships(query, rel, node)
      node_struct = query.return(:n, :r).first
    else
      node_struct = query.return(:n).first
    end

    render json: format_node(node_struct), status: :ok
  end

  def destroy
    node_id = params[:id].to_i.to_s
    raise BadRequest.new(id: 'invalid') if node_id != params[:id]
    node = Node.find_by(label: params[:node_label])
    raise NotFound if node.nil?
    query = CypherHelper.get_node(node_id)
    node_instance = query.return(:n).first
    raise NotFound if node_instance.nil?
    rel = params[:relationships]

    # Properties
    props = params[:properties]
    props = [] if props.blank? || !props.respond_to?('each')
    if props.empty?
      if rel.blank? || (rel[:in].blank? && rel[:out].blank?)
        # Start building DELETE query
        query = CypherHelper.delete_node(node_id)
        return head :ok if query.exec
        raise InternalServerError
      end
    else
      # Start building REMOVE query
      props.each do |key|
        # Verify that the properties exist in the template
        property = node.properties.find_by(key: key)
        if property.blank?
          raise BadRequest.new(property: 'does not exist (' + key.to_s + ')')
        end
      end
      query = CypherHelper.remove_node_props(node_id, props)
    end

    # Relationships
    if rel.present? && !(rel[:in].blank? && rel[:out].blank?)
      query = destroy_relationships(query, rel, node)
      begin
        node_struct = query.return(:n, :r).first
      rescue Neo4j::Session::CypherError => e
        # Relationship won't be found if we deleted it, so check if that's the
        # case, and return just the node if so.
        raise InternalServerError unless e.message == 'Relationship not found'
        node_struct = query.return(:n).first
      end
    else
      node_struct = query.return(:n).first
    end

    render json: format_node(node_struct), status: :ok
  end
end
