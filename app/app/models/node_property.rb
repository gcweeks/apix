class NodeProperty < ApplicationRecord
  belongs_to :node

  validates :key, presence: true
  validates :value_type, presence: true
end
