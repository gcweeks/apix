class NodeProperty < ApplicationRecord
  belongs_to :abstract_node

  validates :key, presence: true
  validates :value_type, presence: true
end
