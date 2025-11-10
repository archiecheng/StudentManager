require "active_record"
require "bcrypt"

class User < ActiveRecord::Base
  has_secure_password   # Requires bcrypt; provide password= /authenticate and other methods
  validates :email, presence: true, uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }
  # Special characters are allowed; length 6~72 bytes (bcrypt has a 72-byte limit)
  validates :password, presence: true,
                       length: { minimum: 6, maximum: 72 },
                       format: { with: /\A(?=.*[A-Za-z])(?=.*\d).{6,72}\z/,
                                 message: "must include at least one letter and one number" },
                       if: -> { new_record? || !password.nil? }
end
