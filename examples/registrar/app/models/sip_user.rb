class SipUser < ActiveRecord::Base
  has_one :registration, :dependent => :destroy
  attr_accessible :first_name, :last_name, :user_name
end
