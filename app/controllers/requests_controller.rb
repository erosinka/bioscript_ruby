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


  # POST /requests
  # POST /requests.json
  def create
    require 'digest'
    logger.debug('CREATE PARAMS:' + params.to_s)
    @request = Request.new(request_params)
    @plugin = Plugin.find(request_params[:plugin_id])
    @h_in = @plugin.hash_in  

    h_param_types={} #{'bam': true, 'list': false}
    ParamType.all.map{|pt| h_param_types[pt.name] = pt.is_file}
    
#    download_cmd = "wget -O #{dir} '#{url}'" #validate: no \ no ', dir contains the name of the file. 
    #curl '#{url}' > file
#    `#{download_cmd}`

    #list of fields of type file
#    list_file_fields = param_h.keys.select{|k| param_h[k] and param_h[k].respond_to?("original_filename")}
    # edit hash put original file name instead of parameter value for parameters of type file
#    list_file_fields.map{|k| param_h[k] = params[k].original_filename}
    param_h = {}
    JSON.parse(params[:list_fields]).map{|e| param_h[e] = params[e]}
    
    @request.parameters = param_h.to_json
    respond_to do |format|
      if @request.save
        
        dir = APP_CONFIG[:data_path] + APP_CONFIG[:input_dir]
        link_dir = APP_CONFIG[:data_path] + APP_CONFIG[:request_input_dir]
        keys = param_h.keys
        @list_file_fields = []
        #param_h.each do |k, v|
        keys.each do |k|
            key = k.split(':').last
            line = @h_in[key]
            # if parameter type is_file and value exists
            if h_param_types[line['type']] and param_h[k]
                prefix_name = @request.id.to_s + "_" + k + '.' # + param_h[k].split('.').last
                if param_h[k].respond_to?("original_filename")
                    original_filename = param_h[k].original_filename
                    filename = prefix_name + original_filename.split('.').last
                    filepath = dir + filename
                    File.open(dir + filename, 'wb+') do |f|
                        f.write(params[k].read)
                    end
                # if URL
                else
                    original_filename = param_h[k] #url.split('/').last
                    url = param_h[k]
                    filename = prefix_name + original_filename.split('.').last
                    filepath = dir + filename
                    download_cmd = "wget -O #{filepath} '#{url}'"
                    `#{download_cmd}`

                end
                logger.debug('FILE:' + k.to_s + ';' + filename + ';')
                @list_file_fields.push(key)
                param_h[k + '_original_filename'] = original_filename
                param_h[k] = filename
                sha2 = Digest::SHA2.file(filepath).hexdigest
                FileUtils.move filepath, (dir + sha2)
                File.symlink (dir + sha2), (link_dir + filename) #
                #@list_file_fields.push(k)
            end
        end
        @param_h = param_h
        #rewrite the parameters in case of multiple
        @request.update_attribute(:parameters, rewrite_multiple.to_json)
       # @request.update_attribute(:parameters, @tmp_h.to_json)
        
        @request.delay.run create_arg_line
        @request.update_attributes(:status_id => 2)
        
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

    def rewrite_multiple
        @tmp_h = {}
        @param_h.each do |k, v|
            if (res = k.split(':')).size == 3 # and k.include?('Multi')
                @tmp_h[res[2]] ||= []
                @tmp_h[res[2]].push(@param_h[k])
            else
                @tmp_h[k] = @param_h[k]
            end
        end
        return @tmp_h
    end

    def create_arg_line
        arg_line = ''
        link_dir = APP_CONFIG[:data_path] + APP_CONFIG[:request_input_dir]
        @tmp_h.each do |k, v|
            if (!k.include?('original_filename') and !v.to_s.blank?)
            if !@list_file_fields.include?(k)
                #arg_line =  arg_line + k + " = '" + v.to_s + "', "
                arg_line =  arg_line + k + " = " + v.to_s + ", "
            else
                # if it is Multi field with array of files: tracks: ['file1', 'file2']
                if v.is_a? Array
                    arg_line = arg_line + k + " = ["
                    files = v
                    files.each do |fname|
                        p = link_dir + fname.to_s
                        arg_line = arg_line + "'" + p + "', "
                    end
                    #remove last comma and space
                    arg_line = arg_line.chop.chop
                    arg_line = arg_line + "], "
                else
                    p = link_dir + v.to_s
                    arg_line = arg_line + k + " = '" + p + "', "
                end
            end
            end
         end
        logger.debug('ARG_LINE:' + arg_line + ';')
        return arg_line
    end
end
