class DecretosController < ApplicationController
  respond_to :json, :html

  def index
    @decreto = Decreto.new
    respond_to do |format|
      format.html
      format.json { render json: DecretoDatatable.new(view_context) }
    end
  end

  def new
    @decreto = Decreto.new
    respond_to do |format|
      format.html {render partial: "modal_decreto", locals: { actionvar: "create"}}
    end
  end

  def show
    @decreto = Decreto.find(params[:id])
  end

  def edit
    @decreto = Decreto.find(params[:id])
    respond_to do |format|
      format.html {render partial: "modal_decreto", locals: { actionvar: "update"}}
    end
  end

  def destroy
    Decreto.find(params[:id]).delete
    render json: {url: "/decretos"}
  end  

  def create
    dec = params[:decreto].select { |key, value| ["letra", "nro", "bis", "descripcion",
          "sumario", "sancion", "observaciones", "entrada_vigencia", "finaliza_vigencia",
          "plazo_dia", "plazo_mes", "plazo_anio", "organismo_origen"].include?(key) }
    @decreto = Decreto.create dec.to_hash

    ## get params tags_ids the POST
    params[:tags_ids].split(',').each { |id| @decreto.tags << Tag.find(id) } unless params[:tags_ids].blank?

    ## get params exps_ids the POST
    unless params[:exps_ids].blank?
      params[:exps_ids].split(',').each { |id| @decreto.circuitos << Expediente.find(id).circuitos.find_by(nro: 0) }
    end

    ## get params clasifications_ids the POST and save
    unless params[:clasificaciones].blank?
      params[:clasificaciones].each { |key,value| @decreto.clasificacions <<  Clasificacion.where(nombre: key).first() }
    end

    ## get params linked_normas the POST and save
    unless params[:linked_normas].blank?
      JSON.parse(params['linked_normas']).each do |key, value|
        @decreto.relationship_modificadas.create do |rm|
          rm.tipo_relacion = value["relation_type"]
          rm.modifica_id = value["id"]
          rm.desde = value["from"]
          rm.hasta = value["to"]
          rm.dia = value["to_day"]
          rm.mes = value["to_month"]
          rm.anio = value["to_year"]
          rm.dia_habil = value["type_day"]
        end
      end
    end

    unless params[:destinies].blank?
      JSON.parse(params[:destinies]).each do |key, value|
        @decreto.destinos.create do |d|
          d.tipo = value['tipo']
          d.fecha = value['fecha']
          d.destino = value['destino']
        end
      end
    end

    redirect_to action: :index
  end

  def update
    @decreto = Decreto.find(params[:id])
    dec = params[:decreto].select { |key, value| ["letra", "nro", "bis", "descripcion",
          "sumario", "sancion", "observaciones", "entrada_vigencia", "finaliza_vigencia",
          "plazo_dia", "plazo_mes", "plazo_anio", "organismo_origen"].include?(key) }

    @decreto.update dec.to_hash

    ## update params tags_ids the PATCH
    current_tags = params[:tags_ids].split(',')
    old_tag = @decreto.tags.map{ |x| x.id.to_s }
    (current_tags - old_tag).each { |id| @decreto.tags << Tag.find(id) }
    (old_tag - current_tags).each { |id| @decreto.tags.delete(id) }

    ## update params exps_ids the PATCH
    current_exps = params[:exps_ids].split(',')
    old_exps = @decreto.expedientes.map{ |x| x.id.to_s}
    (current_exps - old_exps).each { |id| @decreto.circuitos << Expediente.find(id).circuitos.find_by(nro: 0) }
    (old_exps - current_exps).each { |id| @decreto.circuitos.delete(Expediente.find(id).circuitos.find_by(nro: 0).id) }

    ## update params clasifications_ids the PATCH
    current_clasific = []
    old_clasific = @decreto.clasificacions.map{ |x| x.id}
    if params[:clasificaciones].present?
      params[:clasificaciones].each { |key,value| current_clasific << Clasificacion.where(nombre: key).first().id }
    end
    (current_clasific - old_clasific).each { |id| @decreto.clasificacions <<  Clasificacion.find(id) }
    (old_clasific - current_clasific).each { |id| @decreto.clasificacions.delete(id) }
    
    if params['linked_normas'].present?
      ## update params linked_normas the PATCH
      current_normas = []
      old_normas = @decreto.modificadas.map{ |x| x.id }
      JSON.parse(params['linked_normas']).each do |key, value|
        unless old_normas.include?(value["id"])
          @decreto.relationship_modificadas.create do |rm|
              rm.tipo_relacion = value["relation_type"]
              rm.modifica_id = value["id"]
              rm.desde = value["from"]
              rm.hasta = value["to"]
              rm.dia = value["to_day"]
              rm.mes = value["to_month"]
              rm.anio = value["to_year"]
              rm.dia_habil = value["type_day"]
          end
        end
        current_normas << value["id"]
      end
      # delete norms
      (old_normas - current_normas).each { |id| @decreto.modificadas.delete(id) }
    end

    current_destinies = JSON.parse(params[:destinies]).select{ |x, y| y.has_key?(:id) }.map{ |x, y| y[:id] }
    new_destinies = JSON.parse(params[:destinies]).select{ |x, y| not y.has_key?(:id) }
    old_destinies = @decreto.destinos.map{ |x| x.id.to_s }
    new_destinies.each do |key, value|
      @decreto.destinos.create do |nd|
        nd.tipo = value['tipo']
        nd.fecha = value['fecha']
        nd.destino = value['destino']
      end
    end
    (old_destinies - current_destinies).each { |id| @decreto.destinos.delete(id) }

    redirect_to action: :index
  end

  def search_exp
    expedientes = Expediente.where("CONCAT(nro_exp, bis, EXTRACT(year from anio)) ilike ?",
                                   "%#{params[:q]}%").order("nro_exp::int asc").first(15)
    render json: build_json_exp(expedientes)
  end

  def search_norma
    normas = Norma.where("CONCAT(nro, bis, EXTRACT(year from sancion)) ilike ?",
                                   "%#{params[:q]}%").order(nro: :asc).first(15)
    render json: build_json_norma(normas)
  end

  def search_tag
    tags = Tag.where("nombre ilike '%#{params[:q]}%'").first(5)
    render json: tags
  end

  private

  def decreto_params
    params.require(:decreto).permit("letra", "nro", "bis", "descripcion",
          "sumario", "sancion", "observaciones", "entrada_vigencia", "finaliza_vigencia",
          "plazo_dia", "plazo_mes", "plazo_anio", "organismo_origen")
  end

  def build_json_exp exps
    json_array = []
    exps.each do |x|
      year = x.anio.present? ? x.anio.year.to_s : ""
      json_array << {
        id: x.id,
        indice: x.nro_exp + "/" + x.bis.to_s + "/" + year
      }
    end
    json_array
  end

  def build_json_norma norma
    json_array = []
    norma.each do |x|
      year = x.sancion.present? ? x.sancion.year.to_s : ""
      json_array << {
        id: x.id,
        indice: x.type + ": " + x.nro.to_s + "/" + x.bis.to_s  + "/" + year
      }
    end
    json_array
  end

end
