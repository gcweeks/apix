class UsersController < ApplicationController
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

  # GET /users/me
  def get_me
    render json: @authed_user, status: :ok
  end

  private

  def user_params
    params.require(:user).permit(:fname, :lname, :email)
  end
end
