class ApiController < ApplicationController
  include ApiHelper
  include ErrorHelper
  # include CypherHelper
  # include Secured

  # GET /
  def version
    render json: { 'version' => '0.2.0' }, status: :ok
  end

  # GET /test
  def request_get
    render json: { 'body' => 'GET Request' }, status: :ok
  end

  # POST /test
  def request_post
    render json: { 'body' => "POST Request: #{request.body.read}" }, status: :ok
  end

  # GET /auth
  def auth
    # Alternative to users_get call that returns the User token in addition to
    # the rest of the model, provided proper authentication is given.

    unless request.headers['Content-Type'] == 'application/x-www-form-urlencoded'
      error_array = ['must be application/x-www-form-urlencoded']
      if request.headers['Content-Type'].present?
        error_array.push('cannot be ' + request.headers['Content-Type'])
      else
        error_array.push('cannot be nil')
      end
      errors = { content_type: error_array }
      raise BadRequest.new(errors)
    end
    if params[:user].blank?
      errors = {
        username: ['cannot be blank'],
        password: ['cannot be blank']
      }
      raise BadRequest.new(errors)
    end

    errors = {}
    if params[:user][:username].blank?
      (errors[:username] ||= []).push('cannot be blank')
    end
    if params[:user][:password].blank?
      (errors[:password] ||= []).push('cannot be blank')
    end
    raise BadRequest.new(errors) if errors.present?

    user = User.find_by(username: params[:user][:username])
    return head :not_found unless user
    # # Log this authentication event
    # ip_addr = IPAddr.new(request.remote_ip)
    # auth_event = AuthEvent.new(ip_address: ip_addr)
    # auth_event.user = user
    user = user.try(:authenticate, params[:user][:password])
    unless user
      # auth_event.success = false
      # auth_event.save!
      errors = { password: ['is incorrect'] }
      return render json: errors, status: :unauthorized
    end
    # auth_event.success = true
    # auth_event.save!
    if user.token.blank?
      # Generate access token for User
      user.generate_token
      # Save and check for validation errors
      raise UnprocessableEntity.new(user.errors) unless user.save
    end
    # Send User model with token
    render json: user.with_token, status: :ok
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

  # POST /reset
  def reset
    AbstractNode.all.each(&:destroy) # Nodes and Interfaces
    NodeProperty.all.each(&:destroy)
    Relationship.all.each(&:destroy)
    RelationshipProperty.all.each(&:destroy)
    Repo.all.each(&:destroy)
    User.all.each(&:destroy)
    # Create new User
    user = User.new(username: 'gweeks', fname: 'Chris', lname: 'Weeks',
                    email: 'chris@apix.rocks', password: 'itsasecret')
    user.generate_token
    raise UnprocessableEntity.new(user.errors) unless user.save
    # Send User model with token
    render json: user.with_token, status: :ok
  end
end
