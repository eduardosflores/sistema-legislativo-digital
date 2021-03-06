class Procedure < ActiveRecord::Base

  ####### Remove it after rename "type" column to "procedure_type" #######
  # disable STI to allow columns named "type"
  self.inheritance_column = :_type_disabled

	#== Associations
	has_and_belongs_to_many :persons
	has_and_belongs_to_many :bloques
	has_and_belongs_to_many :comisions
  has_and_belongs_to_many :organo_de_gobiernos
  has_and_belongs_to_many :reparticion_oficials
  has_and_belongs_to_many :areas
  has_and_belongs_to_many :municipal_offices, through: :municipal_offices_procedures
  has_and_belongs_to_many :legislative_files
  belongs_to :legislative_file_originated, class_name: 'Loop'

  has_many :procedure_states
  has_many :administrative_files
  has_many :uploads
  has_many :processes_signatories
  has_many :procedure_signatories, through: :processes_signatories

  belongs_to :contingency_plan
  has_one :legislative_file_state

  belongs_to :procedure_derivation


  #== Nested attributes
  accepts_nested_attributes_for :uploads, reject_if: :all_blank
  accepts_nested_attributes_for :administrative_files, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :procedure_states, reject_if: :all_blank
  accepts_nested_attributes_for :contingency_plan, reject_if: :all_blank
  # accepts_nested_attributes_for :procedure_signatories, reject_if: :all_blank

  #== Callbacks
  after_create :initial_state

  #== PaperTrail changes tracker
  has_paper_trail

  def full_date
    "#{self.day || '--'}/#{self.month || '--'}/#{self.year || '--'}"
  end

  def initiators
    result = persons.collect(&:full_name)
    result += bloques.collect(&:denominacion)
    result += comisions.collect(&:denominacion)
    result += organo_de_gobiernos.collect(&:denominacion)
    result += reparticion_oficials.collect(&:denominacion)
    result += areas.collect(&:name)
    result.flatten.join("; ")
  end

  def to_date(date)
    date.strftime("%d/%m/%Y") unless date.nil?
  end

  def text
    "##{id}"
  end

  def get_iniciadores
    result = []
    self.organo_de_gobiernos.each { |b| result << "#{b.denominacion}" }
    self.bloques.each { |b| result << "#{b.denominacion}" }
    self.comisions.each { |b| result << "#{b.denominacion}" }
    self.persons.each { |b| result << "#{b.full_name}" }
    self.reparticion_oficials.each { |b| result << "#{b.denominacion}" }
    self.municipal_offices.each { |b| result << "#{b.denominacion}" }
    result.join ' - '
  end

  def to_s
    "Trámite ##{self.id}"
  end

  def is_dispatch?
    type == "Despacho"
  end

  def isnt_dispatch?
    !is_dispatch?
  end

  def initiator_attributes=(initiators={})
    # case initiators[:type]
    # when 'dem'
    # when 'legislative_secretary'
    # when 'partisan_block'
    # when 'commission'
    # when 'councilor'
    # when 'official_distribution'
    # when 'municipal_office'
    # when 'particular_pyshic'
    # when 'particular_legal'
    # end
  end

  def signator_attributes=(signatories={})
    # case initiators[:type]
    # when 'dem'
    # when 'legislative_secretary'
    # when 'partisan_block'
    # when 'commission'
    # when 'councilor'
    # when 'official_distribution'
    # when 'municipal_office'
    # when 'particular_pyshic'
    # when 'particular_legal'
    # end
  end

  private

  def initial_state
    self.procedure_states.create nombre: 'Iniciado', tipo: 1
  end
end
