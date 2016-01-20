class RequestsController < ApplicationController
#    before_action :set_plugin, only: [:create]
    before_action :set_request, only: [:show, :edit, :update, :destroy]
  protect_from_forgery except: [:fetch, :create]
  # GET /requests
  # GET /requests.json
  def index
  #  @requests = Request.all
    @requests = Request.where(:user_id => 1) 
    @user_requests_sorted = @requests.sort {|a,b| b.id <=> a.id}
    # @requests = Request.all
  end

  # GET /requests/1
  # GET /requests/1.json
  def show
    if !@request
        page_not_found
    else
    val = {}
    val[:parameters] = JSON.parse(@request.parameters)
    results = Result.where(:request_id => @request.id)
    val[:results] = []
    results.each do |r|
        res = {}
        res[:fname] = r.fname
        res[:id] = r.id
        res[:is_file] = r.is_file
        val[:results].push(res)
    end
    val[:plugin_id] = @request.plugin_id
    val[:status] = @request.status.status
    respond_to do |format|

    #    format.html { redirect_to @request, notice: 'test' }
        format.html #{ render :show, status: :created, location: @request }
        format.json { render json: val, status: :ok, location: @request }
    end
    end
       # format.json { render :show, status: :ok, location: @request }
  end

  def fetch
    @plugin = Plugin.find_by_key(params[:oid])
    @info_content = @plugin.info_content
    @service = Service.find_by_shared_key(params[:shared_key]) if params[:shared_key]
    @request = Request.new(:plugin_id => @plugin.id, :user_id => 1, :service_id => (@service) ? @service.id : nil)
  
    render :partial => 'new'
  end

  # GET /requests/new
  def new
    
   # @plugin = Plugin.where({:id =>params[:plugin_id]}).first
    h = {}
    h[:id] = params[:plugin_id] if params[:plugin_id]
    h[:key] = params[:plugin_key] if params[:plugin_key]
    @plugin = Plugin.where(h).first 
    if @plugin
      @info_content = @plugin.info_content
      @request = Request.new(:plugin_id => @plugin.id, :user_id => 1)      
      render
    else
     # render :text => 'ERROR'
     page_not_found
    end    
  end


  # GET /requests/1/edit
  def edit
  end


  # POST /requests
  # POST /requests.json
  def create
    require 'digest'
    # request_params = {"user_id"=>"1", "plugin_id"=>"106"}
    #logger.debug('SERVICE_ID ' + params[:service_id])
    # if post comes from htsstation I have bs_private with files for select
    @service = Service.find(params[:request][:service_id]) if params[:request][:service_id]
    #logger.debug('SERVICE ' + @service.to_json)
    @request = Request.new(request_params)
    @plugin = Plugin.find(request_params[:plugin_id])
    @info_content = @plugin.info_content
    @h_in = @plugin.hash_in  
    
    @param_h = {}
    JSON.parse(params[:list_fields]).map{|e| @param_h[e] = params[e]}

#    list_file_fields = param_h.keys.select{|k| param_h[k] and param_h[k].respond_to?("original_filename")}
#    list_file_fields.map{|k| param_h[k] = params[k].original_filename}
    
    # replace files with just name to save in database
    @param_h.each do |k, v|
        if v and v.respond_to?("original_filename")
            @param_h[k] = params[k].original_filename
        end
    end

    @request.parameters = @param_h.to_json
   # create the key 
   rnd = Array.new(6){[*'0'..'9', *'a'..'z'].sample}.join
    while(Request.find_by_key(rnd)) do
      rnd = Array.new(6){[*'0'..'9', *'a'..'z'].sample}.join
    end 
    @request.key = rnd
    respond_to do |format|
      if @request.save
        create_file_links
        #rewrite the parameters in case of multiple
        @request.update_attribute(:parameters, rewrite_multiple.to_json)
       # @request.update_attribute(:parameters, @tmp_h.to_json)
        
        @request.delay.run create_arg_line
        @request.update_attributes(:status_id => 2)

        # callback_service_pending
        if @service     
          
            h = {
            :callback => 'callback',
            :plugin_id => @plugin.key,
            :validation => 'success',
           # :app => {:user_id => 1},
            :task_id => @request.key} 
            logger.debug('H_JSON:' + h.to_json)
            format.html {render json: {:key => @request.key } }
        else
            format.html { redirect_to @request, notice: 'Request was successfully created.' }
            format.json { render :show, status: :created, location: @request }
        end
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
      @request = Request.find_by_key(params[:key])
    #  @request = Request.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def request_params
      params.require(:request).permit(:user_id, :plugin_id, :parameters, :key, :service_id) #, :service_id)
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

    def create_file_links
        h_param_types={} #{'bam': true, 'list': false}
        ParamType.all.map{|pt| h_param_types[pt.name] = pt.is_file}
        dir = APP_CONFIG[:data_path] + APP_CONFIG[:input_dir]
        link_dir = APP_CONFIG[:data_path] + APP_CONFIG[:request_input_dir]
        keys = @param_h.keys
        @list_file_fields = []
        logger.debug('PARAMS:' + params.to_s)
        logger.debug('PARAMS_H:' + @param_h.to_s)
        #param_h.each do |k, v|
        keys.each do |k|
            key = k.split(':').last
            line = @h_in[key]
            logger.debug('K:' + k + ';')
            # if parameter type is_file and value exists
            if h_param_types[line['type']] and !@param_h[k].blank?
                prefix_name = @request.key.to_s + "_" + k + '.' # + param_h[k].split('.').last
                if params[k].respond_to?("original_filename")
                    original_filename = params[k].original_filename
                    filename = prefix_name + original_filename.split('.').last
                    filepath = dir + filename
                    logger.debug('FILE:' + filepath + ';')
                    File.open(dir + filename, 'wb+') do |f|
                        f.write(params[k].read)
                    end
                # if URL
                else
                    original_filename = @param_h[k] #url.split('/').last
                    url = @param_h[k]
                    file_end = original_filename.split('.').last
                    file_end.gsub!('&', '_')
                    filename = prefix_name + file_end.gsub("/", "_")
                    filepath = dir + filename
                    logger.debug('URL:' + filepath + ';')
                #   download_cmd = "wget -O #{dir} '#{url}'" #validate: no \ no ', dir contains the name of the file. 
                #   curl '#{url}' > file
                    download_cmd = "wget -O #{filepath} '#{url}'"
                    `#{download_cmd}`
                    logger.debug('URL2:' + download_cmd + ';')
                end
                @list_file_fields.push(key)
                @param_h[k + '_original_filename'] = original_filename
                @param_h[k] = filename
                sha2 = Digest::SHA2.file(filepath).hexdigest
                FileUtils.move filepath, (dir + sha2)
                File.symlink (dir + sha2), (link_dir + filename) #
                #@list_file_fields.push(k)
            end
        end
    end

    def create_arg_line
        arg_line = ''
        logger.debug('LIST:' + @list_file_fields.to_s + ';')
        link_dir = APP_CONFIG[:data_path] + APP_CONFIG[:request_input_dir]
        @tmp_h.each do |k, v|
            if (!k.include?('original_filename') and !v.to_s.blank?)
            if !@list_file_fields.include?(k)
                if (v.is_a? Array)
                    arg_line = arg_line + k + "= '"
                    v.each do |value|
                        arg_line = arg_line + value.to_s + ',' 
                    end
                    arg_line = arg_line.chop + "', "
                else
                    test = @h_in[k]['type']
                    if test == 'int' or test == 'float'
                        arg_line =  arg_line + k + " = " + v.to_s + ", "
                    else
                        arg_line =  arg_line + k + " = '" + v.to_s + "', "
                    end
                end
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
