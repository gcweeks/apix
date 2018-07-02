require 'test_helper'

class ReposControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:lynx)
    @user.password = 'SecurePa55word'
    @user.generate_token
    @user.save!
    @headers = { 'Authorization' => @user.token }
    @repo = repos(:bookdb)
    @repo.user = @user
    @repo.save!
  end

  test 'should index' do
    get '/users/' + @user.username + '/repos'
    assert_response :success

    # Check Response
    res = JSON.parse(@response.body)
    assert_equal res.count, 1
    assert_equal res[0]['name'], @repo.name
  end

  test 'should create' do
    # Requires auth
    post '/users/' + @user.username + '/repos', params: { repo: {
      name: @repo.name
    } }
    assert_response :unauthorized
    # Missing name
    post '/users/' + @user.username + '/repos', headers: @headers
    assert_response :unprocessable_entity
    # Invalid name
    post '/users/' + @user.username + '/repos', headers: @headers, params: { repo: {
      name: 'bad name'
    } }
    assert_response :unprocessable_entity
    # Valid Repo
    post '/users/' + @user.username + '/repos', headers: @headers, params: { repo: {
      name: 'NewDB'
    } }
    assert_response :success

    # Check Response
    res = JSON.parse(@response.body)
    assert_equal res['name'], 'NewDB'
  end

  test 'should show' do
    get '/users/' + @user.username + '/repos/' + @repo.name, headers: @headers
    assert_response :success

    # Check Response
    res = JSON.parse(@response.body)
    assert_equal res['name'], @repo.name
  end
end
