require 'test_helper'

class NodeTest < ActiveSupport::TestCase
  test 'validations' do
    author = nodes(:author)
    assert author.save, "Couldn't save valid Node"

    author.label = nil
    assert_not author.save, 'Saved Node without label'
    author.label = 'author'
    author.save!

    new_author = Node.new(label: 'author')
    assert_not new_author.save, 'Saved Node with duplicate label'
  end
end
