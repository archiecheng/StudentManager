require "active_record"

class Student < ActiveRecord::Base
  validates :name, presence: true
end
