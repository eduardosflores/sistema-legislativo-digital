class ProceduresController < ApplicationController
  before_action :authenticate_user!

  def index
    respond_to do |format|
      format.html
      format.json { render json: build_json_response }
    end
  end

  def new
    authorize Procedure, :create?

    #@procedure = ProcedureForm.new
    @procedure = Procedure.new
    @procedure.procedure_states.build
    @procedure.administrative_files.build
    # @procedure.procedure_signatories.build
    @procedure.contingency_plan = ContingencyPlan.new
    @procedure.uploads.build
    #2.times {@procedure.administrative_files.build}
  end

  def create
    authorize Procedure, :create?

    ##############################
    ### CONVERT THIS INTO A SERVICE
    ##############################
    @procedure = Procedure.new procedure_params

    form = ProcedureForm.new procedure_params, params[:action], current_user
    if form.valid? && @procedure.save
      if @procedure.is_dispatch?
        @procedure.legislative_files.each do |file|
          file.legislative_file_states.create do |state|
            state.name = :dispatched
            state.procedure = @procedure
            state.state_type = :parliamentary
          end
        end

        #######################################################
        ##### REPLACE IT
        @procedure.update comision_ids: params[:comision_ids]
        @procedure.update person_ids: params[:councilor_ids]
        #######################################################
      end

      ## Saving initiators
      if procedure_params[:initiator_attributes].present?
        puts "Trygin " * 8
        procedure_params[:initiator_attributes].each do |initiator|
        puts initiator
        puts initiator.inspect
          case initiator['type']
          when 'dem'
            initiator = OrganoDeGobierno.find(codigo: 'DEM')
            @procedure.organo_de_gobiernos << initiator
          when 'legislative_secretary'
            initiator = OrganoDeGobierno.find(codigo: 'SL')
            @procedure.organo_de_gobiernos << initiator
          when 'partisan_block'
            initiator = Bloque.find initiator['id']
            @procedure.bloques << initiator
          when 'commission'
            initiator = Comision.find initiator['id']
            @procedure.comisions << initiator
          when 'councilor'
            initiator = Concejal.find initiator['id']
            @procedure.persons << initiator
          when 'official_distribution'
            initiator = ReparticionOficial.find initiator['id']
            @procedure.reparticion_oficials << initiator
          when 'municipal_office'
            initiator = MunicipalOffice.find initiator['id']
            @procedure.municipal_offices << initiator
          when 'particular_pyshic'
            initiator = Fisica.find initiator['id']
            @procedure.persons << initiator
          when 'particular_legal'
            initiator = Juridica.find initiator['id']
            @procedure.persons << initiator
          end
        end
      end

      flash[:success] = t '.success'
      redirect_to @procedure
    else
      flash.now[:error] = form.errors.full_messages
      render :new
    end
  end

  def edit
    authorize Procedure, :edit?

    @procedure = Procedure.find params[:id]
    @procedure.contingency_plan = ContingencyPlan.new if @procedure.contingency_plan.nil?
  end

  def update
    authorize Procedure, :edit?
    @procedure = Procedure.find params[:id]

    if @procedure.update procedure_params
      #######################################################
      ##### REPLACE IT
      @procedure.update comision_ids: params[:comision_ids]
      @procedure.update person_ids: params[:councilor_ids]
      #######################################################
      flash[:success] = 'Trámite actualizado correctamente'
      redirect_to @procedure
    else
      flash[:error] = 'No fue posible actualizar el trámite'
      redirect_to edit_procedure_path(@procedure)
    end
  end

  def show
    @procedure = Procedure.find params[:id]
    respond_to do |format|
      format.html
      format.json { render json: @procedure.to_json }
    end
  end

  def print
    if params[:id].present?
      pdf = Prawn::Procedures.new()
      send_data pdf.render, filename: 'tramites.pdf',
                type: 'application/pdf', disposition: 'inline'
    else
      pdf = Prawn::Procedures.new()
      send_data pdf.render, filename: 'tramites.pdf',
                type: 'application/pdf', disposition: 'inline'
    end
  end

  private

  def procedure_params
    params.require(:procedure).permit :type, :sheets, :topic, :observations,
      :day, :month, :year, :uploads, :legislative_files, initiator_attributes: [],
      person_ids: [], comision_ids: [], contingency_plan_attributes: [:date_at, :reason, :generator, :signatory],
      procedure_states_attributes: [],
      councilors: [], legislative_file_ids: [], administrative_file_ids: [],
      administrative_files_attributes: [:id, :number, :sheets, :letter, :year, :_destroy],
      procedure_signatory_attributes: []
  end

  def build_json_response
    if params[:select_q].present?
      q = "%#{params[:select_q]}%"
      w = "id::text ilike ?"
      Procedure.where(w, q).limit(20).to_json(methods: :text)
    else
      ProcedureDatatable.new(view_context)
    end
  end
end
