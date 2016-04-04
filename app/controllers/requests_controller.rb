class RequestsController < ApplicationController
  before_action :set_request, only: [:show, :edit, :update, :destroy]
  protect_from_forgery except: [:fetch, :create]
  # GET /requests
  # GET /requests.json
  def index
#    @by_month = Request.all.count(:group => created_at.month)
     @requests = Request.all
    #@requests = Request.where(:user_id => 1)
    #@by_month = @requests.group_by{ |r| r.created_at.month}#@requests.select("created_at.month, count(*)").group("created_at.month")
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
            format.json { render json: @request.request_info.to_json, status: :ok, location: @request }
        end
    end
  end

# method called from HTSStation
  def fetch
    @plugin = Plugin.find_by_key(params[:plugin_id])
    @info_content = @plugin.info_content
    @service = Service.find_by_shared_key(params[:shared_key]) if params[:shared_key]
    a = JSON.parse(params[:bs_private])
    #app/controller/new_bs_job_controller.rb bs_fetch L207 
    @bs_private = a['prefill']['track']
    if @service
        logger.debug('Service is')
    end
    #user_id = @service ? params[:user_id] : 1
    user_id = params[:user_id]
    @files_from_hts_1 = []
    if @bs_private
        @bs_private.each do |bsp|
            t = JSON.parse(bsp[0])
            file = [t['n'], bsp[0]]
            @files_from_hts_1.push(file)
        end
        @files_from_hts = @files_from_hts_1.sort {|a,b| a[0] <=> b[0]}
    end
    # could create service - bioscript with service.id = 2
    @request = Request.new(:plugin_id => @plugin.id, :user_id => user_id, :service_id => (@service) ? @service.id : nil)
    render :partial => 'new'
  end

  # GET /requests/new
  def new
    # @plugin = Plugin.where({:id =>params[:plugin_id]}).first
    h = {}
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


  # POST /requests
  # POST /requests.json
  def create
    require 'digest'
    # if post comes from htsstation I have bs_private with files for select
    @service = Service.find(params[:request][:service_id]) if params[:request][:service_id] and !params[:request][:service_id].empty?
    @request = Request.new(request_params)
    logger.debug('CREATE REQUEST: ' + @request.to_json)
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
    logger.debug('CREATE PARAM_H:' + @param_h.to_json)
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
           #  @request.delay.run create_arg_line
            @request.run_job create_arg_line
            # request status is pending
            @request.update_attributes(:status_id => 2)
            logger.debug('CALLBACK')
            @request.service_callback if @service #@service.id
#       format.html { redirect_to @request, notice: 'Request was successfully updated.' }
        redirect_url = @service ? (@service.server_url + @service.redirect_path) : request_path(@request)
        render json: {:redirect_url => redirect_url}
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
        # create unique key for request
        rnd = Array.new(6){[*'0'..'9', *'a'..'z'].sample}.join
        while(Request.find_by_key(rnd)) do
            rnd = Array.new(6){[*'0'..'9', *'a'..'z'].sample}.join
        end 
        return rnd
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
        #param_h.each do |k, v|
        keys.each do |k|
            key = k.split(':').last
            line = @h_in[key]
            # if parameter type is_file and value exists
            if h_param_types[line['type']] and !@param_h[k].blank?
                prefix_name = @request.key.to_s + "_" + k + '.' # + param_h[k].split('.').last
                type = params[k + '_bs_group']
                logger.debug('type: ' + type);
                if type == 'file'
                    original_filename = '';
                    if params[k].respond_to?("original_filename")
                        original_filename = params[k].original_filename
                    else
                        logger.debug('No original_filename for arg ' + k + ' of type file \n');
                    end
                    filename = prefix_name + original_filename.split('.').last
                    filepath = dir + filename
                    #logger.debug('FILE:' + filepath + ';')
                    File.open(filepath, 'wb+') do |f|
                        f.write(params[k].read)
                    end
                #elsif @param_h[k].match(/^(ftp)|(http.?)\:\/\//)
                elsif type == 'text'
                    original_filename = @param_h[k] 
                    url = @param_h[k]
                    file_end = original_filename.split('.').last
                    file_end.gsub!('&', '_')
                    filename = prefix_name + file_end.gsub("/", "_")
                    filepath = dir + filename
                    download_cmd = "wget -O #{filepath} '#{url}'"
                    `#{download_cmd}`
                elsif type == 'select'
                    val = JSON.parse(@param_h[k])
                    logger.debug('SELECT option from HTS:' + val.class.to_s + ' ' + val.to_s)
                    if val.has_key?("n")
                        original_filename = val['n']
                        url = val['p']
                        logger.debug('HASH URL: ' + url)
                        file_end = original_filename.split('.').last
                        file_end.gsub!('&', '_')
                        filename = prefix_name + file_end.gsub("/", "_")
                        filepath = dir + filename
                        download_cmd = "wget -O #{filepath} '#{url}'"
                        `#{download_cmd}`
                    else
                        logger.debug('ERROR: no proper keys in hash ' + k + '\n');
                    end 
                else
                    logger.debug('ERROR: cannot create file links. Type of arg is not file or text or select')
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

    def upload original_filename

     file_end = original_filename.split('.').last
     file_end.gsub!('&', '_')
   #  logger.debug('PREFIX_NAME:' + @prefix_name.to_s);
     filename = @prefix_name + file_end.gsub("/", "_")
     filepath = @dir + filename
   #  logger.debug('URL:' + filepath + ';')
 #   curl '#{url}' > file
 #   curl -k #{url} -o #{filepath}
     download_cmd = "wget -O #{filepath} '#{url}'"
     `#{download_cmd}`
    end

    def create_arg_line
        arg_line = ''
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
                    # if not a numeric field then value is in quotes
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
        # cut last coma and space
        arg_line = arg_line.chop.chop
        logger.debug('PLUGIN ARG_LINE:' + arg_line + ';')
        return arg_line
    end
end
