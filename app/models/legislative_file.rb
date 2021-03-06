class LegislativeFile < ActiveRecord::Base
  # == Associations
  has_many :administrative_files
  has_many :loops
  has_many :legislative_file_states, dependent: :delete_all
  has_many :laws
  has_many :tags  ## Change to has_many and add tags model
  has_many :uploads

  # == Association recursive expediente acumula
  has_many :acumulados_relationship, class_name: "Acumula", foreign_key: "acumula_id"
  has_many :accumulated_in, through: :acumulados_relationship
  has_one :acumula_relationship, class_name: "Acumula", foreign_key: "acumulado_id"
  has_one :physically_attached, through: :acumula_relationship

  # == Association recursive expediente acumula
  has_many :adjuntados_relationship, class_name: "AdjuntaFisicamente", foreign_key: "adjunta_id"
  has_many :adjuntados, through: :adjuntados_relationship
  has_one :adjunta_relationship, class_name: "AdjuntaFisicamente", foreign_key: "adjuntado_id"
  has_one :adjunta, through: :adjunta_relationship

  validates :sheets, presence: true

  # == Callbacks
  before_create :sequential_number

  # == Nested attributes
  accepts_nested_attributes_for :loops, reject_if: :all_blank
  accepts_nested_attributes_for :uploads

  # == Methods
  # Return first loop. Physical representation of legislative file into DB.
  def first_loop
    return loops.first if loops.count.zero?
    loops.find_by number: 0
  end

  # Return procedure that begins the legislative file.
  def origin_procedures
    return nil if first_loop.blank?
    first_loop.origin_procedures
  end

  def origin_procedure_ids
    first_loop.origin_procedure_ids
  end

  def sequential_number
    return if self.number.present?
    last = LegislativeFile.last
    self.number = (last.number.to_i + 1).to_s if last.present?
  end

  def text
    result = number.nil? ? 'S/N' : "##{number}"
    result += " - #{bis}" if bis.present? && !bis.zero?
    result += "  (año: #{year})" if year.present?
    result
  end

  def initiators
    people = []
    origin_procedures.each do |proc|
      people.concat(proc.persons)
    end
    if people.all? { |p| p.type == 'Concejal' }
      result = people.map { |b| b.full_name }.join('; ')
    else
      result = people.map { |b| b.full_name }.join('; ')
    end
    origin_procedures.each do |p|
      result += "; " unless result.empty?
      result += p.comisions.collect(&:denominacion).join('; ')
      result += p.organo_de_gobiernos.collect(&:denominacion).join('; ')
      result += p.bloques.collect(&:denominacion).join('; ')
      result += p.reparticion_oficials.collect(&:denominacion).join('; ')
      result += p.municipal_offices.collect(&:denominacion).join('; ')
    end
    result[0..664]
  end

  def uploads=(files)
    files.each { |file| uploads.create file: file }
  end

  def to_s
    "##{self.number}"
  end
end
