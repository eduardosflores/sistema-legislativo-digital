class Person < ActiveRecord::Base

  #== Concejal Associations
  # has_and_belongs_to_many :periodos
  # has_and_belongs_to_many :comisions
  # belongs_to :bloque

  #== Associations
  has_and_belongs_to_many :tramites

  has_many :estado_tramites, as: :ref

  def full_name
    "#{self.nombre} #{self.apellido}"
  end
end