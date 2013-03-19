class Registration < ActiveRecord::Base
  belongs_to :sip_user
  attr_accessible :location
end
