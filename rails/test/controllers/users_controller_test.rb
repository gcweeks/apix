require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
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

  test 'should get me' do
    # Requires auth
    get '/me'
    assert_response :unauthorized

    get '/me', headers: @headers
    assert_response :success

    # Check Response
    res = JSON.parse(@response.body)
    assert_equal res['fname'], @user.fname
    assert_equal res['lname'], @user.lname
    assert_equal res['username'], @user.username
    assert_equal res['email'], @user.email
  end

  test 'should update me' do
    # Requires auth
    put '/me'
    assert_response :unauthorized

    fname = 'Test'
    lname = 'User'
    password = 'NewPa55word'
    put '/me', headers: @headers, params: { user: {
      fname: fname,
      lname: lname,
      password: password
    } }
    assert_response :success

    res = JSON.parse(@response.body)
    assert_equal res['fname'], fname
    assert_equal res['lname'], lname

    # Assert new password works and old one doesn't
    headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }
    get '/auth', headers: headers, params: { user: {
      username: @user.username,
      password: password
    } }
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal @user.token, res['token']
    get '/auth', headers: headers, params: { user: {
      username: @user.username,
      password: @user.password
    } }
    assert_response :unauthorized
  end

  test 'should get prefs' do
    @user.preferences = {
      hello: 'world'
    }
    @user.save

    # Requires auth
    get '/preferences'
    assert_response :unauthorized

    get '/preferences', headers: @headers
    assert_response :success

    # Check Response
    res = JSON.parse(@response.body)
    assert_equal res['hello'], 'world'
    assert_equal res, @user.preferences
  end

  test 'should set prefs' do
    # Requires auth
    post '/preferences'
    assert_response :unauthorized

    post '/preferences', headers: @headers, params: {
      key: 'value'
    }
    assert_response :success

    res = JSON.parse(@response.body)
    assert_equal res['key'], 'value'
    @user.reload
    assert_equal res, @user.preferences
  end

  test 'should create' do
    new_username = 'newbie'
    new_email = 'new@email.com'
    # Missing fname
    post '/users', params: { user: {
      lname:    @user.lname,
      username: new_username,
      email:    new_email,
      password: @user.password
    } }
    assert_response :unprocessable_entity
    # Missing lname
    post '/users', params: { user: {
      fname:    @user.fname,
      username: new_username,
      email:    new_email,
      password: @user.password
    } }
    assert_response :unprocessable_entity
    # Missing username
    post '/users', params: { user: {
      fname:    @user.fname,
      lname:    @user.lname,
      email:    new_email,
      password: @user.password
    } }
    assert_response :unprocessable_entity
    # Existing username
    post '/users', params: { user: {
      fname:    @user.fname,
      lname:    @user.lname,
      username: @user.username,
      email:    new_email,
      password: @user.password
    } }
    assert_response :unprocessable_entity
    # Missing email
    post '/users', params: { user: {
      fname: @user.fname,
      lname: @user.lname,
      username: new_username,
      password: @user.password
    } }
    assert_response :unprocessable_entity
    # Invalid email
    post '/users', params: { user: {
      fname:    @user.fname,
      lname:    @user.lname,
      username: new_username,
      email:    'bad@email',
      password: @user.password
    } }
    assert_response :unprocessable_entity
    # Existing email
    post '/users', params: { user: {
      fname:    @user.fname,
      lname:    @user.lname,
      username: new_username,
      email:    @user.email,
      password: @user.password
    } }
    assert_response :unprocessable_entity
    # Missing password
    post '/users', params: { user: {
      fname:    @user.fname,
      lname:    @user.lname,
      username: new_username,
      email:    new_email
    } }
    assert_response :unprocessable_entity
    # Invalid password
    post '/users', params: { user: {
      fname:    @user.fname,
      lname:    @user.lname,
      username: new_username,
      email:    new_email,
      password: 'short'
    } }
    assert_response :unprocessable_entity
    # Valid User
    post '/users', params: { user: {
      fname:    @user.fname,
      lname:    @user.lname,
      username: new_username,
      email:    new_email,
      password: @user.password
    } }
    assert_response :success

    # Check Response
    res = JSON.parse(@response.body)
    assert_equal 24, res['token'].length
    assert_equal res['fname'], @user.fname
    assert_equal res['lname'], @user.lname
    assert_equal res['username'], new_username
    assert_equal res['email'], new_email
  end

  test 'should show' do
    get '/users/' + @user.username
    assert_response :success

    # Check Response
    res = JSON.parse(@response.body)
    assert_equal res['fname'], @user.fname
    assert_equal res['lname'], @user.lname
    assert_equal res['username'], @user.username
    assert_equal res['email'], @user.email
  end
end
