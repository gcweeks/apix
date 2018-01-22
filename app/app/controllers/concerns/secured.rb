# frozen_string_literal: true
module Secured
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request!
  end

  SCOPES = {
    '/restricted_resource' => ['read:messages'],
    '/another_resource'    => ['some:scope', 'some:other_scope']
  }

  private

  def authenticate_request!
    if request.headers['Auth0'].present?
      @auth_payload, @auth_header = auth_token
      # render json: { errors: @auth_payload }, status: :unauthorized unless scope_included
    elsif request.headers['Authorization'].present?
      # TODO
    else
      render json: { errors: ['Not Authenticated'] }, status: :unauthorized
    end
  rescue JWT::VerificationError, JWT::DecodeError
    render json: { errors: ['Not Authenticated'] }, status: :unauthorized
  end

  def scope_included
    # The intersection of the scopes included in the given JWT and the ones in the SCOPES hash needed to access
    # the PATH_INFO, should contain at least one element
    return true unless SCOPES[request.env['PATH_INFO']]
    (String(@auth_payload['scope']).split(' ') & (SCOPES[request.env['PATH_INFO']])).any?
  end

  def auth_token
    JsonWebToken.verify(request.headers['Auth0'].split(' ').last)
  end
end
