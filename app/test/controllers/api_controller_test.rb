require 'test_helper'

class ApiControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:lynx)
    @user.password = 'SecurePa55word'
    @user.generate_token
    @user.save!
  end

  test 'should get version' do
    get '/'
    assert_response :success
    res = JSON.parse(@response.body)
    assert_match(/^[0-9]*\.[0-9]*\.[0-9]*$/, res['version'])
  end

  test 'should get' do
    get '/test'
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal 'GET Request', res['body']
  end

  test 'should post' do
    post '/test', params: { test1: 'test2' }
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal 'POST Request: test1=test2', res['body']
  end

  test 'should auth' do
    headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }
    # Incorrect password
    get '/auth', headers: headers, params: { user: {
      username: @user.username,
      password: 'incorrect'
    } }
    # Nonexistent username
    assert_response :unauthorized
    get '/auth', headers: headers, params: { user: {
      username: 'doesnotexist',
      password: @user.password
    } }
    assert_response :not_found
    get '/auth', headers: headers, params: { user: {
      username: @user.username,
      password: @user.password
    } }
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal @user.token, res['token']
  end
end
