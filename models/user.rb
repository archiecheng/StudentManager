require "active_record"
require "bcrypt"

class User < ActiveRecord::Base
  has_secure_password   # 需要 bcrypt；提供 password= / authenticate 等方法
  validates :email, presence: true, uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }

  validates :password, presence: true, length: { minimum: 6 },
                       format: { with: /\A(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]+\z/,
                                 message: "must include at least one letter and one number" },
                       if: -> { new_record? || !password.nil? }
end
