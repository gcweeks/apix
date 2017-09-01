ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical
  # order.
  fixtures :all

  def fixture_json(name)
    JSON.parse(File.read('test/fixtures/files/' + name + '.json'))
  end

  def fixture(name)
    fixture_json(name).to_json
  end

  # Add more helper methods to be used by all tests here...
end
