class UsersController < ApplicationController
  before_action :restrict_access, except: [:create]

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

  # PATCH/PUT /users/me
  def update_me
    unless @authed_user.update(user_update_params)
      raise UnprocessableEntity.new(@authed_user.errors)
    end
    render json: @authed_user, status: :ok
  end

  # GET /usrs/me/repos
  def get_repos
    render json: @authed_user.repos, status: :ok
  end

  def support
    # # Validate payload
    # unless params[:text]
    #   errors = { text: ['is required'] }
    #   raise BadRequest.new(errors)
    # end
    # unless params[:text].length <= 1000
    #   errors = { text: ['must be 1000 characters or less'] }
    #   raise BadRequest.new(errors)
    # end

    # # Build text
    # text = '```' + params[:text] + '```' + "\n"
    # text += 'FROM: ' + @authed_user.email

    # # Build HTTPS request
    # slack_key = ENV['SLACK_ROUTE']
    # url = URI.parse('https://hooks.slack.com/services/' + slack_key)
    # http = Net::HTTP.new(url.host, url.port)
    # http.use_ssl = true
    # req = Net::HTTP::Post.new(url.to_s)
    # req['Content-Type'] = 'application/json'
    # req.body = {
    #   'text' => text
    # }.to_json

    # # Send Slack message
    # res = http.request(req)

    # # Log response in case of issues
    # logger.info res

    head :ok
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
