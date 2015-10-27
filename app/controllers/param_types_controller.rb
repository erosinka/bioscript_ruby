class ParamTypesController < ApplicationController
  before_action :set_param_type, only: [:show, :edit, :update, :destroy]

  # GET /param_types
  # GET /param_types.json
  def index
    @param_types = ParamType.all
  end

  # GET /param_types/1
  # GET /param_types/1.json
  def show
  end

  # GET /param_types/new
  def new
    @param_type = ParamType.new
  end

  # GET /param_types/1/edit
  def edit
  end

  # POST /param_types
  # POST /param_types.json
  def create
    @param_type = ParamType.new(param_type_params)

    respond_to do |format|
      if @param_type.save
        format.html { redirect_to @param_type, notice: 'Param type was successfully created.' }
        format.json { render :show, status: :created, location: @param_type }
      else
        format.html { render :new }
        format.json { render json: @param_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /param_types/1
  # PATCH/PUT /param_types/1.json
  def update
    respond_to do |format|
      if @param_type.update(param_type_params)
        format.html { redirect_to @param_type, notice: 'Param type was successfully updated.' }
        format.json { render :show, status: :ok, location: @param_type }
      else
        format.html { render :edit }
        format.json { render json: @param_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /param_types/1
  # DELETE /param_types/1.json
  def destroy
    @param_type.destroy
    respond_to do |format|
      format.html { redirect_to param_types_url, notice: 'Param type was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_param_type
      @param_type = ParamType.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def param_type_params
      params.require(:param_type).permit(:name, :is_file)
    end
end
