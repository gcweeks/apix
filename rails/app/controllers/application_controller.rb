class ApplicationController < ActionController::API
  include ErrorHelper
  rescue_from BadRequest, with: :bad_request
  rescue_from Unauthorized, with: :unauthorized
  rescue_from PaymentRequired, with: :payment_required
  rescue_from NotFound, with: :not_found
  rescue_from UnprocessableEntity, with: :unprocessable_entity
  rescue_from InternalServerError, with: :internal_server_error

  def restrict_access
    token = request.headers['Authorization']
    return head :unauthorized unless token
    @authed_user = User.find_by(token: token)
    raise Unauthorized unless @authed_user
  end

  def assign_repo
    user = User.find_by(username: params[:user_name])
    raise NotFound if user.nil?
    @repo = user.repos.where('lower(name) = ?', params[:repo_name].downcase).take
    raise NotFound if @repo.nil?
  end

  private

  def bad_request(exception)
    return render json: exception.data, status: :bad_request if exception.data
    head :bad_request
  end

  def unauthorized(exception)
    return render json: exception.data, status: :unauthorized if exception.data
    head :unauthorized
  end

  def payment_required(exception)
    if exception.data
      return render json: exception.data, status: :payment_required
    end
    head :payment_required
  end

  def not_found(exception)
    return render json: exception.data, status: :not_found if exception.data
    head :not_found
  end

  def unprocessable_entity(exception)
    if exception.data
      return render json: exception.data, status: :unprocessable_entity
    end
    head :unprocessable_entity
  end

  def internal_server_error(exception)
    if exception.data
      return render json: exception.data, status: :internal_server_error
    end
    head :internal_server_error
  end
end
