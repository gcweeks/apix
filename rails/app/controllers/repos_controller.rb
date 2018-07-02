class ReposController < ApplicationController
  before_action :restrict_access, only: %i(create update destroy)

  # GET /users/:user_name/repos
  def index
    user = User.find_by(username: params[:user_name])
    raise NotFound if user.blank?
    render json: user.repos, status: :ok
  end

  # POST /users/:user_name/repos
  def create
    raise Unauthorized unless @authed_user.username_is(params[:user_name])
    # Create new Repo
    repo = Repo.new(repo_params)
    repo.user = @authed_user
    # Save and check for validation errors
    raise UnprocessableEntity.new(repo.errors) unless repo.save
    # Send Repo model
    render json: repo, status: :ok
  end

  # GET /users/:user_name/repos/:name
  def show
    user = User.find_by(username: params[:user_name])
    raise NotFound if user.blank?
    repo = user.repos.find_by(name: params[:name])
    raise NotFound if repo.blank?
    render json: repo, status: :ok
  end

  # PATCH/PUT /users/:user_name/repos/:name
  def update
    # TODO
    render json: { 'status' => 'Not implemented' }, status: :ok
  end

  # DELETE /users/:user_name/repos/:name
  def destroy
    # TODO
    render json: { 'status' => 'Not implemented' }, status: :ok
  end

  private

  def repo_params
    params.fetch(:repo, {}).permit(:name)
  end
end
