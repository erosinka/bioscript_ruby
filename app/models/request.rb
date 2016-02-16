class Request < ActiveRecord::Base
  belongs_to :plugin
  has_many :results
  belongs_to :status
  
  def to_param
    key
  end
  
  def run arg_line
    # request is started
    self.update_attributes(:status_id => 1)
    # callback_service running
    service_callback if self.service_id
    
    output_dir = APP_CONFIG[:data_path] + APP_CONFIG[:output_dir]
    #get the name of the plugin file
    n = self.plugin.name.match(/(.+?)Plugin/)
    script = "import os\nos.chdir('#{output_dir}')\nfrom bsPlugins import #{n[1]}\nplugin = #{n[1]}.#{self.plugin.name}()\nplugin(#{arg_line})"
    logger.debug('SCRIPT_NAME ' + self.key.to_s);
    #script_name = sefl.id.to_s +'.py'
    script_dir =  APP_CONFIG[:script_dir]
    #logger.debug('SCRIPT_DIR ' + script_dir);
    script_name = APP_CONFIG[:data_path] + script_dir + self.key.to_s + '_script.py'
    #logger.debug('SCRIPT_NAME: ' + script_name);
    #script_name = APP_CONFIG[:data_path] +  self.key.to_s + '_script.py'
    File.open(script_name, 'w') do |f|
      f.write(script)
    end
    output = `python #{script_name} 2>&1`
    logger.debug('DELAYED_JOB.RUN OUTPUT: ' + output)
    out_content = self.plugin.info_content['out']
    line_start = []
    out_content.each do |out|
      # line_start[0] = 'density_fwd (track):'
      line_start.push(out['id'] + ' (' + out['type'] + '):')
    end
    error = false
    err_msg = ''
    request_id = self.id
    lines = output.split("\n")
    lines.each do |line|
        includes = false;
      #check if each line of output has proper begining
      line_start.each do |ls|
        error = !line.include?(ls)
        break if (!error)
      end
      if error
        err_msg = lines.join("\\n")
        break
      end
      #example of line:
      #density_fwd (track): /data/epfl/bbcf/bioscript/tmp/tmp4dJJ7W/Density_average_fwd.sql
      logger.debug('SPLIT: ' + line)
      k = line.split(':', 2).map(&:strip)
      # other option:
      # k = line.split('/', 2)
      # path = '/' + k[1]
      file_name = ''
      path = ''
      if (k.length > 1)
        # full_path = '/data/epfl...'
        full_path = k[1]
        # file_name = full_path.rpartition('/').last
        # path = full_path.split(file_name)[0]
        tab = full_path.split('/') 
        # file_name = tab.pop
        file_name = tab.pop
        folder_name = tab.pop 
        path = tab.join('/') + '/' + folder_name
        logger.debug('FNAME: ' + path)
        `chmod 755 #{path}`
      else
        error = true
        err_msg = 'no output path'
        break
      end
      new_result = Result.new(:request_id => self.id, :fname => file_name, :path => folder_name, :is_file => true)
      new_result.save
    end
    logger.debug('ERROR: ' + err_msg)
    if (error)
      self.update_attributes(:error => err_msg, :status_id => 5)
    else
      self.update_attributes(:status_id => 4)
    end 
    status_name = self.status.status
    # call_back_service finish
    service_callback if self.service_id #self.service_id
  end


  def service_callback
    @service = Service.find(self.service_id)
    hts_server = @service.callback_url #APP_CONFIG[:hts_server]
    # in table Services we store whole url for callback function?
    hts_url = @service.server_url + @service.callback_url
    res = Net::HTTP.post_form(URI.parse(hts_url), request_info)
    response =  res.body.gsub(/\n/, '.:;:.')
  end
  
  # request data in json format for hts_callback mainly
  def request_info #request_key
    @request = self
    # @request = Request.find_by_key(request_key)
    val = {
      :key => @request.key,
      :user_id => @request.user_id,
      :task_id => @request.key,
      :parameters => JSON.parse(@request.parameters),
      :plugin_id => @request.plugin.key,
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
end
