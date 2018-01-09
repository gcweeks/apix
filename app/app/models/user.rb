class User < ApplicationRecord
  has_many :auth_events

  validates :email, presence: true, uniqueness: true, format: {
    with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  }
  validates :fname, presence: true
  validates :lname, presence: true
  validates :token, presence: true

  def as_json(options = {})
    json = super({
      except: [:token]
    }.merge(options))
    # Manually call as_json (implicitly) for fields that are models
    # json['address'] = address
    json
  end

  def with_token
    json = as_json
    json['token'] = token
    json
  end

  def generate_token
    self.token = SecureRandom.base58(24)
  end
end
