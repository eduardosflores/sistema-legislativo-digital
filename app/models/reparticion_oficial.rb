class ReparticionOficial < ActiveRecord::Base
  has_and_belongs_to_many :tramites

  def type
    'ReparticionOficial'
  end
end
