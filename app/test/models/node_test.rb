require 'test_helper'

class NodeTest < ActiveSupport::TestCase
  test 'validations' do
    lynx = users(:lynx)
    repo = repos(:bookdb)
    author = nodes(:author)

    # Repo
    assert_not author.save, 'Saved Node without repo'
    repo.user = lynx
    assert repo.save, 'Couldn\'t save valid Repo'
    author.repo = repo
    assert author.save, "Couldn't save valid Node"

    author.label = nil
    assert_not author.save, 'Saved Node without label'
    author.label = 'Capital'
    assert_not author.save, 'Saved Node with invalid character'
    author.label = 'author'
    author.save!

    new_author = Node.new(label: 'author')
    assert_not new_author.save, 'Saved Node with duplicate label'
  end
end
