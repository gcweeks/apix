class InterfacesController < ApplicationController
  include ErrorHelper
  include TemplateHelper

  before_action :restrict_access, only: %i(create update destroy)
  before_action :assign_repo

  # GET /users/:user_name/repos/:repo_name/interfaces
  def index
    return render json: @repo.interfaces, status: :ok if params[:label].blank?
    interface = @repo.interfaces.find_by(label: params[:label])
    raise NotFound if interface.nil?
    render json: interface, status: :ok
  end

  # POST /users/:user_name/repos/:repo_name/interfaces
  def create
    interface = Interface.new(label: params[:label].downcase)
    interface.repo = @repo
    raise BadRequest.new(interface.errors) if interface.invalid?
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
        interface.properties << property
      end
    end
    interface.save!
    render json: interface, status: :created
  end

  # GET /users/:user_name/repos/:repo_name/interfaces/:id
  def show
    interface = @repo.interfaces.find_by(id: params[:id])
    raise NotFound if interface.nil?
    render json: interface, status: :ok
  end

  # PATCH/PUT /users/:user_name/repos/:repo_name/interfaces/:id
  def update
    interface = @repo.interfaces.find_by(id: params[:id])
    raise NotFound if interface.nil?

    interface.label = params[:label] if params[:label].present?

    if params[:properties].present?
      unless params[:properties].respond_to?('each')
        raise BadRequest.new(properties: 'bad format')
      end
      params[:properties].each do |key, value_type|
        existing_prop = interface.properties.find_by(key: key)
        if existing_prop.nil?
          interface.properties << NodeProperty.create(key: key,
                                                      value_type: value_type)
        elsif value_type != existing_prop.value_type
          if value_type.nil?
            property.destroy!
          else
            existing_prop.value_type = value_type
            existing_prop.save!
          end
        end
      end
    elsif params[:label].blank?
      raise BadRequest.new(params: 'must contain properties and/or label')
    end
    interface.save!
    render json: interface, status: :ok
  end

  # DELETE /users/:user_name/repos/:repo_name/interfaces/:id
  def destroy
    interface = @repo.interfaces.find_by(id: params[:id])
    raise NotFound if interface.nil?

    interface.destroy!
    head :ok
  end
end
