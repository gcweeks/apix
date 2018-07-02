class RelationshipProperty < ApplicationRecord
  belongs_to :relationship

  validates :key, presence: true
  validates :value_type, presence: true
end
