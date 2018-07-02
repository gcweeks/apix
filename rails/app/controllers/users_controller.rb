class UsersController < ApplicationController
  before_action :restrict_access, only: %i(show_me update_me)
  # 'create' is obviously unrestricted

  # GET /me
  def show_me
    render json: @authed_user, status: :ok
  end

  # PATCH/PUT /me
  def update_me
    unless @authed_user.update(user_update_params)
      raise UnprocessableEntity.new(@authed_user.errors)
    end
    render json: @authed_user, status: :ok
  end

  # POST /users
  def create
    # Create new User
    user = User.new(user_params)
    # Generate the User's auth token
    user.generate_token
    # Save and check for validation errors
    raise UnprocessableEntity.new(user.errors) unless user.save
    # Send User model with token
    render json: user.with_token, status: :ok
  end

  # GET /users/:name
  def show
    user = User.find_by(username: params[:name])
    raise NotFound if user.blank?
    render json: user, status: :ok
  end

  private

  def user_params
    params.require(:user).permit(:username, :email, :password, :fname, :lname)
  end

  def user_update_params
    # No :username or :email
    params.require(:user).permit(:fname, :lname, :password)
  end
end
