class ReposController < ApplicationController
  before_action :restrict_access

  # POST /repos
  def create
    # Create new Repo
    repo = Repo.new(repo_params)
    repo.user = @authed_user
    # Save and check for validation errors
    raise UnprocessableEntity.new(repo.errors) unless repo.save
    # Send Repo model
    render json: repo, status: :ok
  end

  # GET /repos/:id
  def show
    repo = Repo.where(id: params[:id]) # TODO or find_by?
    raise NotFound if repo.blank?
    render json: repo, status: :ok
  end

  private

  def repo_params
    params.require(:repo).permit(:name)
  end
end
