require 'test_helper'

class RelationshipTest < ActiveSupport::TestCase
  test 'validations' do
    author = nodes(:author)
    book = nodes(:book)

    relationship = relationships(:wrote)
    relationship.from_node = author
    relationship.to_node = book
    assert relationship.save, "Couldn't save valid Relationship"

    relationship.from_node = nil
    assert_not relationship.save, 'Saved Relationship without from_node'
    relationship.from_node = author

    relationship.to_node = nil
    assert_not relationship.save, 'Saved Relationship without to_node'
    relationship.to_node = book

    relationship.rel_type = nil
    assert_not relationship.save, 'Saved Relationship without rel_type'
    relationship.rel_type = 'WROTE'
    relationship.save!

    new_rel = Relationship.new(rel_type: 'WROTE')
    new_rel.from_node = author
    new_rel.to_node = book
    assert_not new_rel.save, 'Saved duplicate Relationship'
    new_rel.rel_type = 'COWROTE'
    assert new_rel.save, "Couldn't save valid Relationship"
    new_rel.rel_type = 'WROTE'
    new_node = Node.create(label: 'freelancer')
    new_rel.from_node = new_node
    assert new_rel.save, "Couldn't save valid Relationship"
  end
end
