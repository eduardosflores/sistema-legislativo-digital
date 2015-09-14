class Norma < ActiveRecord::Base

  # == Associations
  has_and_belongs_to_many :clasificacions
  has_and_belongs_to_many :circuitos
  has_and_belongs_to_many :boletin_oficials
  has_and_belongs_to_many :otra_publicacions
  has_and_belongs_to_many :tags
  has_many :capitulos_normas
  has_many :capitulos, through: :capitulos_normas
  has_many :destinos

  belongs_to :expediente

  has_many :estado_expedientes, as: :ref

  # == Recursive associations
  has_many :relationship_modificadas, class_name: 'ModificaRelationship', foreign_key: 'me_modifica_id'
  has_many :modificadas, through: :relationship_modificadas, source: :modifica
  has_many :relationship_me_modifican, class_name: 'ModificaRelationship', foreign_key: 'modifica_id'
  has_many :me_modifican, through: :relationship_me_modifican, source: :me_modifica

  def expedientes
    self.circuitos.map { |x| x.expediente }
  end

  def com_date
    date = self.destinos.where(tipo: 0).first()
    date.nil? ? nil : date.fecha
  end

  def com_dest
    dest = self.destinos.where(tipo: 0).first()
    dest.nil? ? "" : dest.destino
  end

  def not_date
    date = self.destinos.where(tipo: 1).first()
    date.nil? ? nil : date.fecha
  end

  def not_dest
    dest = self.destinos.where(tipo: 1).first()
    dest.nil? ? "" : dest.destino
  end  
end
