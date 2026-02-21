class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :profiles, dependent: :destroy
  has_many :groups, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || password.present? }

  def email_verified?
    email_verified_at.present?
  end
end
