class User < ApplicationRecord
  has_secure_password

  has_many :time_entries, dependent: :destroy

  ROLES = %w[regular user_manager admin].freeze

  validates :name, presence: true, length: {maximum: 50}
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
            format: { with: VALID_EMAIL_REGEX },
            uniqueness: {case_sensitive: true}
  validates :password,presence:true, length: { minimum: 6 },allow_nil: true
  validates :role, inclusion: { in: ROLES }

  before_create :generate_api_token


  def generate_api_token
    self.api_token = loop do
      token = SecureRandom.hex(24)
      break token unless User.exists?(api_token: token)
    end
  end

  def rotate_api_token!
    update!(api_token: nil)
    generate_api_token
    save!
    api_token
  end

  def admin?
    role == "admin"
  end

  def user_manager?
    role == "user_manager"
  end

  def regular?
    role == "regular"
  end

  private

    def downcase_email
      self.email = email.downcase
    end
end
