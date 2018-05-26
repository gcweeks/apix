class User < ApplicationRecord
  PASSWORD_FORMAT = /\A
  (?=.{9,})          # Must contain 9 or more characters
  # (?=.*\d)           # Must contain a digit
  # (?=.*[a-z])        # Must contain a lower case character
  # (?=.*[A-Z])        # Must contain an upper case character
  # (?=.*[[:^alnum:]]) # Must contain a symbol
  /x

  has_many :repos
  has_secure_password

  # Validations
  # TODO validate username across capitalizations
  validates :username, presence: true, uniqueness: true, format: {
    with: /\A[a-zA-Z0-9_-]+\z/,
    message: 'only allows letters, numbers, and the - and _ characters'
  }
  validates :email, presence: true, uniqueness: true, format: {
    with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  }
  validates :password, presence: true, format: { with: PASSWORD_FORMAT },
                       on: :create
  validates :password, allow_nil: true, format: { with: PASSWORD_FORMAT },
                       on: :update
  validates :fname, presence: true
  validates :lname, presence: true
  validates :token, presence: true

  def as_json(options = {})
    json = super({
      except: %i(token password_digest created_at updated_at)
    }.merge(options))
    # Manually call as_json (implicitly) for fields that are models
    json['repos'] = repos
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

  def username_is(other_username)
    username.downcase == other_username.downcase
  end
end
