class RelationshipsController < ApplicationController
  include RelationshipHelper
  include ErrorHelper
  include TemplateHelper

  before_action :restrict_access, only: %i(create update destroy)
  before_action :assign_repo, only: %i(index create)

  # GET /users/:user_name/repos/:repo_name/relationships
  def index
    # TODO, and assign_repo scope
    render json: { 'status' => 'Not implemented' }, status: :ok
  end

  # POST /users/:user_name/repos/:repo_name/relationships
  def create
    rel = Relationship.new(rel_type: params[:rel_type])
    to = @repo.nodes.find_by(id: params[:to])
    raise BadRequest.new(to: 'does not exist') if to.nil?
    from = @repo.nodes.find_by(id: params[:from])
    raise BadRequest.new(from: 'does not exist') if from.nil?
    rel.to_node = to
    rel.from_node = from
    raise BadRequest.new(rel.errors) if rel.invalid?
    if params[:properties].present? && params[:properties].respond_to?('each')
      props_json = params[:properties].to_unsafe_h
      # Validate properties
      props_json.each { |_k, vt| TemplateHelper.validate_type(vt) }
      # Store validated properties as new NodeProperty instances
      properties = []
      props_json.each do |key, value_type|
        value_type = value_type.to_s
        property = RelationshipProperty.new(key: key, value_type: value_type)
        raise BadRequest.new(property.errors) if property.invalid?
        properties << property
      end
      properties.each do |property|
        property.save!
        rel.properties << property
      end
    end
    rel.save!
    render json: rel, status: :created
  end

  # GET /users/:user_name/repos/:repo_name/relationships
  def show
    rel = Relationship.find_by(id: params[:id])
    raise NotFound if rel.nil?
    render json: rel, status: :ok
  end

  # PATCH/PUT /users/:user_name/repos/:repo_name/relationships/:id
  def update
    rel = Relationship.find_by(id: params[:id])
    raise NotFound if rel.nil?

    query = CypherHelper.relationship_query(rel.from_node.scoped_label,
                                            rel.to_node.scoped_label,
                                            rel.rel_type)
    # Keep track of if we need to execute this query
    needs_query = false
    if params[:rel_type].present? && params[:rel_type] != rel.rel_type
      query = rel.update_rel_type(query, params[:rel_type])
      needs_query = true
    end

    if params[:properties].present?
      unless params[:properties].respond_to?('each')
        raise BadRequest.new(properties: 'bad format')
      end
      new_props = []
      params[:properties].each do |key, value_type|
        new_props.push key
        existing_prop = rel.properties.find_by(key: key)
        if existing_prop.nil?
          rel.properties << RelationshipProperty.create(key: key,
                                                        value_type: value_type)
        elsif value_type != existing_prop.value_type
          query = rel.update_prop_type(query, existing_prop, value_type)
          needs_query = true
          existing_prop.save!
        end
      end
      rel.properties.each do |property|
        next if new_props.include?(property.key)
        query = rel.destroy_property(query, property)
        needs_query = true
        property.destroy!
      end
    elsif params[:rel_type].blank?
      raise BadRequest.new(params: 'must contain properties and/or rel_type')
    end
    query.exec if needs_query
    rel.save!
    render json: rel, status: :ok
  end

  # DELETE /users/:user_name/repos/:repo_name/relationships/:id
  def destroy
    rel = Relationship.find_by(id: params[:id])
    raise NotFound if rel.nil?

    query = CypherHelper.relationship_query(rel.from_node.scoped_label,
                                            rel.to_node.scoped_label,
                                            rel.rel_type)
    # Destroy all instances. This call will also destroy the template itself
    # when done.
    rel.destroy_instances(query).exec
    rel.destroy!
    head :ok
  end
end
