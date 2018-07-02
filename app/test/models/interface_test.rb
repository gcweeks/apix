require 'test_helper'

class InterfaceTest < ActiveSupport::TestCase
  test 'validations' do
    lynx = users(:lynx)
    repo = repos(:bookdb)
    person = interfaces(:person)

    # Repo
    assert_not person.save, 'Saved Interface without repo'
    repo.user = lynx
    assert repo.save, "Couldn't save valid Repo"
    person.repo = repo
    assert person.save, "Couldn't save valid Interface"

    person.label = nil
    assert_not person.save, 'Saved Interface without label'
    person.label = 'Capital'
    assert_not person.save, 'Saved Interface with invalid character'
    person.label = 'person'
    person.save!

    # Duplicates
    new_person = Interface.new(label: 'person')
    assert_not new_person.save, 'Saved Interface with duplicate label'
  end
end
