require 'test_helper'

class AbstractNodeTest < ActiveSupport::TestCase
  test 'validations' do
    lynx = users(:lynx)
    repo = repos(:bookdb)
    author = nodes(:author)
    book = nodes(:book)
    person = interfaces(:person)

    repo.user = lynx
    assert repo.save, "Couldn't save valid Repo"
    author.repo = repo
    assert author.save, "Couldn't save valid Node"
    book.repo = repo
    assert book.save, "Couldn't save valid Node"
    person.repo = repo
    assert person.save, "Couldn't save valid Interface"
    assert_equal 3, AbstractNode.all.count
    assert_equal 2, Node.all.count
    assert_equal 1, Interface.all.count
    assert_equal 'Node', author.type
    assert_equal 'Node', book.type
    assert_equal 'Interface', person.type
    person.type = nil
    assert_not person.save, 'Saved AbstractNode without type'
  end
end
