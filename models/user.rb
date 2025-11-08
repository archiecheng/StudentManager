require "active_record"
require "bcrypt"

class User < ActiveRecord::Base
  has_secure_password   # 需要 bcrypt；提供 password= / authenticate 等方法
  validates :email, presence: true, uniqueness: true
end
