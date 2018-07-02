class AbstractNode < ApplicationRecord
  belongs_to :repo
  has_many :properties, class_name: 'NodeProperty'

  validates :type, presence: true # STI
  validates :label, presence: true, uniqueness: { scope: :repo }, format: {
    with: /\A[a-z0-9_-]+\z/,
    message: 'only allows letters, numbers, and the - and _ characters'
  }
  validates :repo, presence: true
end
