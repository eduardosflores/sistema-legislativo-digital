class Clasificacion < ActiveRecord::Base

  # == Associations
  has_and_belongs_to_many :normas

end
