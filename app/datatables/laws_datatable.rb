class LawsDatatable
  include Rails.application.routes.url_helpers
  delegate :params, :link_to, to: :@view

  def initialize(view)
    @view = view
  end

  def as_json(_options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: laws.count,
      iTotalDisplayRecords: laws.count,
      data: data
    }
  end

  private
  def data
    paginated_laws.map do |law|
      [
        "#{law.number} / #{law.letter} / #{law.year}",
        law.law_type,
        law.year,
        '',
        'expediente nro 1',
        actions(law)
      ]
    end
  end

  def format_date(date)
    date.present? ? date.strftime('%d/%m/%Y - %H:%M') : ''
  end

  def laws
    Law.where(filter).order(:id)
  end

  def sort_column(column)
    columns[column.to_i]
  end

  def filter
    query = []
    binds = []

    ## Must be fixed
    if params[:search][:value].present?
      search = "%#{params[:search][:value]}%"
      query += ["(people.nombre ILIKE ?  OR people.apellido ILIKE ?)"]
      query += ["(people.number_doc ILIKE ?  OR people.telefono ILIKE ?)"]
      query += ["(people.email ILIKE ?  OR people.domicilio ILIKE ?)"]
      binds += [search] * 6
    end
    [query.join(' OR ')] + binds
  end

  def paginated_laws
    laws.page(page).per(per_page)
  end

  def per_page
    params[:length].to_i > 0 ? params[:length].to_i : 25
  end

  def page
    params[:start].to_i / per_page + 1
  end

  def actions(law)
    link_to '', law, class: 'btn btn-info fa fa-eye'
  end
end