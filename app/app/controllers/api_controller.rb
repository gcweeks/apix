class ApiController < ApplicationController
  include ApiHelper
  include ErrorHelper
  include CypherHelper

  def version
    render json: { 'version' => '0.1.2' }, status: :ok
  end

  def request_get
    render json: { 'body' => 'GET Request' }, status: :ok
  end

  def request_post
    render json: { 'body' => "POST Request:\n\n#{request.body.read}\n" },
           status: :ok
  end
end
