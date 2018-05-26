class NodesController < ApplicationController
  include NodeHelper
  include ErrorHelper
  include TemplateHelper

  before_action :restrict_access, only: %i(create update destroy)
  before_action :assign_repo

  # GET /users/:user_name/repos/:repo_name/nodes
  def index
    return render json: @repo.nodes, status: :ok if params[:label].blank?
    node = @repo.nodes.find_by(label: params[:label])
    raise NotFound if node.nil?
    render json: node, status: :ok
  end

  # POST /users/:user_name/repos/:repo_name/nodes
  def create
    node = Node.new(label: params[:label].downcase)
    node.repo = @repo
    raise BadRequest.new(node.errors) if node.invalid?
    if params[:properties].present? && params[:properties].respond_to?('each')
      props_json = params[:properties].to_unsafe_h
      # Validate properties
      props_json.each { |_k, vt| TemplateHelper.validate_type(vt) }
      # Store validated properties as new NodeProperty instances
      properties = []
      props_json.each do |key, value_type|
        value_type = value_type.to_s
        property = NodeProperty.new(key: key, value_type: value_type)
        raise BadRequest.new(property.errors) if property.invalid?
        properties << property
      end
      properties.each do |property|
        property.save!
        node.properties << property
      end
    end
    node.save!
    render json: node, status: :created
  end

  # GET /users/:user_name/repos/:repo_name/nodes/:id
  def show
    node = @repo.nodes.find_by(id: params[:id])
    raise NotFound if node.nil?
    render json: node, status: :ok
  end

  # PATCH/PUT /users/:user_name/repos/:repo_name/nodes/:id
  def update
    node = @repo.nodes.find_by(id: params[:id])
    raise NotFound if node.nil?

    query = CypherHelper.node_query(node.scoped_label)
    # Keep track of if we need to execute this query
    needs_query = false
    if params[:label].present? && params[:label] != node.label
      query = node.update_label(query, params[:label])
      needs_query = true
    end

    if params[:properties].present?
      unless params[:properties].respond_to?('each')
        raise BadRequest.new(properties: 'bad format')
      end
      params[:properties].each do |key, value_type|
        existing_prop = node.properties.find_by(key: key)
        if existing_prop.nil?
          node.properties << NodeProperty.create(key: key,
                                                 value_type: value_type)
        elsif value_type != existing_prop.value_type
          if value_type.nil?
            query = node.destroy_property(query, property)
            property.destroy!
          else
            query = node.update_prop_type(query, existing_prop, value_type)
            existing_prop.save!
          end
          needs_query = true
        end
      end
    elsif params[:label].blank?
      raise BadRequest.new(params: 'must contain properties and/or label')
    end
    query.exec if needs_query
    node.save!
    render json: node, status: :ok
  end

  # DELETE /users/:user_name/repos/:repo_name/nodes/:id
  def destroy
    node = @repo.nodes.find_by(id: params[:id])
    raise NotFound if node.nil?

    query = CypherHelper.node_query(node.scoped_label)

    # Destroy all instances. This call will also destroy the template itself
    # when done.
    node.destroy_instances(query).exec
    node.destroy!
    head :ok
  end
end
