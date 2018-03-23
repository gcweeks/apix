require 'test_helper'

class RepoTest < ActiveSupport::TestCase
  test 'validations' do
    lynx = users(:lynx)
    dolphin = users(:dolphin)
    repo = repos(:movies)

    # User
    assert_not repo.save, 'Saved Repo without user'
    repo.user = lynx
    assert repo.save, 'Couldn\'t save valid Repo'

    # Name
    name = repo.name
    repo.name = nil
    assert_not repo.save, 'Saved Repo without name'
    repo.name = name
    new_repo = Repo.new(name: name)
    new_repo.user = lynx
    assert_not new_repo.save, 'Saved Repo with duplicate name for User'
    new_repo.user = dolphin
    assert new_repo.save, 'Couldn\'t save valid Repo'
  end
end
