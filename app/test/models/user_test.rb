require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'validations' do
    user = users(:lynx)

    # Token
    assert_not user.save, 'Saved User without token'
    user.generate_token

    # Password
    assert_not user.save, 'Saved User without password'
    password = 'verySecurePa55word'
    user.password = password
    assert user.save, 'Couldn\'t save valid User'
    user.reload
    user.password = 'short'
    assert_not user.save, 'Saved User with short password'
    # user.password = 'password123'
    # assert_not user.save, 'Saved User without capital letter in password'
    # user.password = 'BadPassword'
    # assert_not user.save, 'Saved User without number in password'
    user.password = password

    # Username
    username = user.username
    user.username = nil
    assert_not user.save, 'Saved User without username'
    user.username = username
    new_user = User.new(fname: user.fname, lname: user.lname,
                        username: user.username, email: 'another@email.com',
                        password: 'AnotherPa55word')
    new_user.generate_token
    assert_not new_user.save, 'Saved new User with duplicate username'

    # Email
    email = user.email
    user.email = nil
    assert_not user.save, 'Saved User without email'
    user.email = '@gmail.com'
    assert_not user.save, 'Saved User with improper email format 1'
    user.email = 'lynx@gmail.'
    assert_not user.save, 'Saved User with improper email format 2'
    user.email = email
    new_user = User.new(fname: user.fname, lname: user.lname,
                        username: 'anotheruser', email: user.email,
                        password: 'AnotherPa55word')
    new_user.generate_token
    assert_not new_user.save, 'Saved new User with duplicate email'

    # Name
    fname = user.fname
    user.fname = ''
    assert_not user.save, 'Saved User without first name'
    user.fname = fname
    lname = user.lname
    user.lname = nil
    assert_not user.save, 'Saved User without last name'
    user.lname = lname
    # user.reload
  end

  test 'should generate token' do
    user = users(:lynx)

    # Token
    assert_nil user.token
    user.generate_token
    assert_not_nil user.token
  end
end
