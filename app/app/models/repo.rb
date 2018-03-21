class Repo < ApplicationRecord
  belongs_to :user
  
  validates :name, presence: true, uniqueness: { scope: :user }
  validates :user, presence: true
end
