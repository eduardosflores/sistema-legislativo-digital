module ApplicationHelper

  def norma_a_dispositivos norma
    resp = "dsa"
    norma.modificadas.each do |n|
      resp
    end
    resp
  end

  def dispositivos_a_norma norma
    "dispositivos a norma"
  end

  def fechas norma
    resp = ""
    if norma.sancion.present?
      resp = resp + "Sanción: #{norma.sancion}\n"
    end
    norma.destinos.each do |d|
      case d.tipo
      when 0
        resp = resp + "Comunic: #{d.fecha}\n"
      when 1
        resp = resp + "Notific: #{d.fecha}\n"
      end
    end
    resp
  end

  def index_norma norma
    link_to norma.nro.to_s + "-" + norma.bis.to_s + "/" + norma.sancion.try(:year).to_s, declaracion_path(norma)
  end

  def norma_expediente norma
    resp = ""
    norma.circuitos.each do |c|
      if (c.nro == 0)
        resp = resp + "Expediente: " + link_to(c.expediente.nro_exp, "expedientes/#{c.expediente.id}") + "\n"
      else
        resp= resp + "Circuito nro: #{c.nro}--> Expediente: " + link_to(c.expediente.nro_exp, "expediente/#{c.expediente.id}") + "\n"
      end
    end
    resp
  end

  def resolve_path_name
    return "Declaraciones" if current_page?(controller: :declaracions, action: :index)
    return "Declaración #{params[:id]}" if current_page?(controller: :declaracions, action: :show, id: params[:id].to_i)
    return "Inicio" if current_page?(controller: :dashboard, action: :index)
  end

  def prepopulate_exps norma
    norma.expedientes.present? ? build_json_exp(norma.expedientes) : []
  end

  def prepopulate_tags norma
    norma.tags.present? ? build_json_tags(norma.tags) : []
  end

  def build_json_exp exps
    json_array = []
    exps.each do |x|
      year = x.anio.present? ? x.anio.year.to_s : ""
      json_array << {
        id: x.id,
        indice: year + "/" + x.nro_exp + "/" + x.bis.to_s
      }
    end
    json_array
  end

  def build_json_tags tags
    json_array = []
    tags.each { |x| json_array << { id: x.id, nombre: x.nombre } }
    json_array.to_json
  end

  def indice norma
    x = norma.modifica
    year = x.sancion.present? ? x.sancion.year.to_s : ""
    "#{x.type}: #{year}/#{x.nro}/#{x.bis}"
  end

  def to_date date
    date.strftime("%d/%m/%Y")
  end  
end
