class RequestsController < ApplicationController
#    before_action :set_plugin, only: [:create]
    before_action :set_request, only: [:show, :edit, :update, :destroy]

  # GET /requests
  # GET /requests.json
  def index
    @requests = Request.where(:user_id => 1) 
    @user_requests_sorted = @requests.sort {|a,b| b.id <=> a.id}
    # @requests = Request.all
  end

  # GET /requests/1
  # GET /requests/1.json
  def show
  end

  # GET /requests/new
  def new
    @plugin = Plugin.find(params[:plugin_id])
    @info_content = @plugin.info_content
    @request = Request.new(:plugin_id => @plugin.id, :user_id => 1)
  end

  # GET /requests/1/edit
  def edit
  end

 # def get_parameters(plugin)
 # end

  # POST /requests
  # POST /requests.json
  def create
    require 'digest'
    #plugin = Plugin.find(params[:plugin_id])
    @request = Request.new(request_params)
    tmp_h = {}
    JSON.parse(params[:list_fields]).map{|e| tmp_h[e] = params[e]}
    
    #list of fields of type file
    list_file_fields = tmp_h.keys.select{|k| tmp_h[k] and tmp_h[k].respond_to?("original_filename")}

    logger.debug("all fields:" + tmp_h.keys.to_json)
    list_file_fields.map{|k| tmp_h[k] = params[k].original_filename}
    @request.parameters = tmp_h.to_json
    respond_to do |format|
      if @request.save
        
        dir = APP_CONFIG[:data_path] + APP_CONFIG[:input_dir]
        link_dir = APP_CONFIG[:data_path] + APP_CONFIG[:request_input_dir]
        #only for fielts of file type
        list_file_fields.map{|k|
          tmp_h[k] = params[k].original_filename #
          filename = @request.id.to_s + "_" + k#
          #add extension and full path to file name because of plugins realization
          ext = ''
          if (res = tmp_h[k].split('.')).size == 2
            ext = res[1]
            filename = filename + '.' + ext
            #tmp_h[k] = link_dir + filename
            tmp_h[k] = filename
          end 
          filepath = dir + filename
          File.open(filepath, 'wb+') do |f|
            f.write(params[k].read)
          end
          sha2 = Digest::SHA2.file(filepath).hexdigest
          FileUtils.move filepath, (dir + sha2)
          File.symlink (dir + sha2), (link_dir + filename) #
        }
        #rewrite the parameters in case of multiple
        tmp_h2 = {}
        tmp_h.keys.each do |k|
            if (res = k.split(':')).size == 3
                tmp_h2[res[2]] ||= []
                tmp_h2[res[2]].push(tmp_h[k])
            else
                tmp_h2[k] = tmp_h[k]
            end
        end
        logger.debug('CONT')
        @request.update_attribute(:parameters, tmp_h2.to_json)

        @request.delay.run
        #@request.update_attribute(:error, res)
        #format.html { redirect_to @request, notice: 'Request was successfully created.' }
        
       # format.html { redirect_to results_path(:request_id => @request.id)}
        format.html { redirect_to @request, notice: 'Request was successfully created.' }
        format.json { render :show, status: :created, location: @request }
      else
        format.html { render :new }
        format.json { render json: @request.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /requests/1
  # PATCH/PUT /requests/1.json
  def update
    respond_to do |format|
      if @request.update(request_params)
        format.html { redirect_to @request, notice: 'Request was successfully updated.' }
        format.json { render :show, status: :ok, location: @request }
      else
        format.html { render :edit }
        format.json { render json: @request.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /requests/1
  # DELETE /requests/1.json
  def destroy
    @request.destroy
    respond_to do |format|
      format.html { redirect_to requests_url, notice: 'Request was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_request
      @request = Request.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def request_params
      params.require(:request).permit(:user_id, :plugin_id, :parameters)
    end

end
