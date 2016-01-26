class RequestsController < ApplicationController
  # before_action :set_plugin, only: [:create]
  before_action :set_request, only: [:show, :edit, :update, :destroy]
  protect_from_forgery except: [:fetch, :create]
  # GET /requests
  # GET /requests.json
  def index
    # @requests = Request.all
    @requests = Request.where(:user_id => 1) 
    @user_requests_sorted = @requests.sort {|a,b| b.id <=> a.id}
  end

  # GET /requests/1
  # GET /requests/1.json
  def show
    if !@request
        page_not_found
    else
        respond_to do |format|
            # format.html { redirect_to @request, notice: 'test' }
            format.html #{ render :show, status: :ok, location: @request }
            format.json { render json: request_info.to_json, status: :ok, location: @request }
        end
    end
  end

# method called from HTSStation
  def fetch
    @plugin = Plugin.find_by_key(params[:oid])
    @info_content = @plugin.info_content
    @service = Service.find_by_shared_key(params[:shared_key]) if params[:shared_key]
    a = JSON.parse(params[:bs_private])
    #app/controller/new_bs_job_controller.rb bs_fetch L207 
    bs_private = a['prefill']['track']
    @files_from_hts = []
    if bs_private
        bs_private.each do |bsp|
            t = JSON.parse(bsp[0])
            #file = [t['n'], t['p'] +'/'+ t['n']]
            file = [t['p'] + '/' + t['n'], t['p'] +'/'+ t['n']]
            @files_from_hts.push(file)
        end
    end
#    logger.debug('BS_FILES:'+ @files_from_hts.to_json)
    # could create service - bioscript with service.id = 2
    @request = Request.new(:plugin_id => @plugin.id, :user_id => 1, :service_id => (@service) ? @service.id : nil)
    render :partial => 'new'
  end

  # GET /requests/new
  def new
    # @plugin = Plugin.where({:id =>params[:plugin_id]}).first
    h = {}
    logger.debug('NEW is called');
    h[:id] = params[:plugin_id] if params[:plugin_id]
    h[:key] = params[:plugin_key] if params[:plugin_key]
    @plugin = Plugin.where(h).first 
    if !@plugin
        page_not_found
    else
        @info_content = @plugin.info_content
        @request = Request.new(:plugin_id => @plugin.id, :user_id => 1)      
        render
    end    
  end


  # GET /requests/1/edit
  def edit
  end

  def create_test
    require 'digest'
    @service = Service.find(params[:request][:service_id]) if params[:request][:service_id] and !params[:request][:service_id].empty?
    @request = Request.new(request_params)
    @plugin = Plugin.find(request_params[:plugin_id])
    @info_content = @plugin.info_content
    @h_in = @plugin.hash_in
    @param_h = {}
    JSON.parse(params[:list_fields]).map{|e| @param_h[e] = params[e]}
    @request.key = create_key
    @request.save
   # render json: {:redirect_url => 'test' }, status: :ok
    render json: {:redirect_url => request_path(@request)}
  end


  # POST /requests
  # POST /requests.json
  def create
    require 'digest'
    # request_params = {"user_id"=>"1", "plugin_id"=>"106"}

    # params = {"controller":"requests","action":"create"}

    # if post comes from htsstation I have bs_private with files for select
    @service = Service.find(params[:request][:service_id]) if params[:request][:service_id] and !params[:request][:service_id].empty?
    # @bs_private = params[:prefill][:track] if @service and if params[:prefill]
    logger.debug('SERVICE ' + @service.to_json) if @service
    @request = Request.new(request_params)
    logger.debug('REQUEST ' + @request.to_json)
    @plugin = Plugin.find(request_params[:plugin_id])
    @info_content = @plugin.info_content
    @h_in = @plugin.hash_in  
    
    @param_h = {}
    JSON.parse(params[:list_fields]).map{|e| @param_h[e] = params[e]}

    # replace files with just name to save in database
    @param_h.each do |k, v|
        if v and v.respond_to?("original_filename")
            @param_h[k] = params[k].original_filename
        end
    end
    logger.debug('CREATE:' + @param_h.to_json)

    @request.parameters = @param_h.to_json
    # create random key for new request
    @request.key = create_key

  #  respond_to do |format|
        if !@request.save
         #   format.html { render :new }
         #   format.json { render json: @request.errors, status: :unprocessable_entity }
            render json: @request.errors, status: :unprocessable_entity 
        else
            create_file_links
            # rewrite the parameters in case of multiple file upload
            @request.update_attribute(:parameters, rewrite_multiple.to_json)
            # run delayed_job to execute the python script
            @request.delay.run create_arg_line
            # request status is pending
            @request.update_attributes(:status_id => 2)

#            if !@service     
#                format.html { redirect_to @request, notice: 'Request was successfully created.' }
#                format.json { render :show, status: :created, location: @request }
#            else
#                h = {
#                    :callback => 'callback',
#                    :plugin_id => @plugin.key,
#                    :validation => 'success',
#                    # :app => {:user_id => 1},
#                    :task_id => @request.key} 
#                format.html {render json: {:key => @request.key } }
#                # callback_service_pending
#                # service_callback @service.id
#            end

#          format.html { redirect_to @request, notice: 'Request was successfully updated.' }
#          format.json { 
 #         format.all {
  
        redirect_url = @service ? (@service.server_url + @service.redirect_path) : request_path(@request)
        render json: {:redirect_url => redirect_url}
          # { render status: :500 }
#} 
 #       }

        end
#    end
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
      params.require(:request).permit(:user_id, :plugin_id, :parameters, :key, :service_id) #, :service_id) :format ??
    end

    def create_key
        # create the key for request
        rnd = Array.new(6){[*'0'..'9', *'a'..'z'].sample}.join
        while(Request.find_by_key(rnd)) do
            rnd = Array.new(6){[*'0'..'9', *'a'..'z'].sample}.join
        end 
        return rnd
    end

    def service_callback_bp service_id
        @service = Service.find(service_id)
        hts_server = @service.callback_url #APP_CONFIG[:hts_server]
        # in table Services we store whole url for callback function?
        hts_url = hts_server #+ 'new_bs_job/hts_callback'
        res = Net::HTTP.post_form(URI.parse(hts_url), request_info.to_json)
        response =  res.body.gsub(/\n/, '.:;:.')
    end

# request data in json format for hts_callback mainly
    def request_info_bp #request_key
        set_request
        # @request = Request.find_by_key(request_key) 
        val = {
            :key => @request.key,
            :parameters => JSON.parse(@request.parameters),
            :plugin_id => @request.plugin_id,
            :status => @request.status.status,
            :error => @request.error,
            :results => []
        }
        results = Result.where(:request_id => @request.id)
        results.each do |r|
            res = {
                :fname => r.fname,
                :id => r.id,
                :is_file => r.is_file
            }
            val[:results].push(res)
        end
        return val
    end

# rewrite parameters for multiple fields
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
                #   curl -k #{url} -o #{filepath}
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
