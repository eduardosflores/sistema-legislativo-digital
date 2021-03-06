class Person < ActiveRecord::Base
  #== Concejal Associations
  # has_and_belongs_to_many :periodos
  # has_and_belongs_to_many :comisions
  # belongs_to :bloque

  #== PaperTrail changes tracker
  has_paper_trail

  #== Associations
  has_and_belongs_to_many :procedures
  has_many :estado_procedure, as: :ref
  has_many :processes_signatories
  has_many :signed_paperwork,
           through: :processes_signatories,
           source: :process

  belongs_to :picture, class_name: 'Upload'
  belongs_to :cv, class_name: 'Upload'
  belongs_to :ddjj, class_name: 'Upload'

  def full_name
    if self.type == 'Concejal'
      "Concejal #{name} #{surname} (Bque #{bloque.try(:denominacion)})"
    elsif surname.present? && name.present?
      "#{surname}, #{name}"
    elsif surname.present?
      surname
    elsif name.present?
      name
    else
      ''
    end
  end

  def fullname_with_dni
    if type == 'Concejal'
      "Concejal #{name} #{surname} - Bloque #{bloque.try(:denominacion)}"
    else
      cuit_or_dni.present? ? full_name + " (DNI: #{cuit_or_dni})" : full_name
    end
  end

  def text
    if type == 'Concejal'
      return "Concejal #{full_name}"
    end

    if cuit_or_dni.present?
     "#{full_name} [#{cuit_or_dni}]"
    else
      full_name
    end
  end

  def picture_file=(photo)
    update picture: Upload.create(file: photo)
  end

  def cv_file=(file)
    update cv: Upload.create(file: file)
  end

  def ddjj_file=(file)
    update ddjj: Upload.create(file: file)
  end

  def picture_file; end
  def cv_file; end
  def ddjj_file; end
end
