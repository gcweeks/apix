class Repo < ApplicationRecord
  has_many :nodes
  has_many :interfaces
  belongs_to :user

  validates :name, presence: true, uniqueness: { scope: :user }, format: {
    with: /\A[a-zA-Z0-9_-]+\z/,
    message: 'only allows letters, numbers, and the - and _ characters'
  }
  validates :user, presence: true
end
