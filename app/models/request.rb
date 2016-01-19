class Request < ActiveRecord::Base
  belongs_to :plugin
  has_many :results
  belongs_to :status

#  before_create :validate
#  validate :validate

  def to_param
    key
  end

  def validate

    # plugin.info to define which parameters are files
    in_content = self.plugin.info_content['in']
    h_in = {}
    in_content.map{ |i| h_in[i['id']] = i}
    
    h_param_types={} #{'bam': true, 'list': false}
    ParamType.all.map{|pt| h_param_types[pt.name] = pt.is_file}
    
    params = JSON.parse(self.parameters)

 end


 def run arg_line
    # started
    self.update_attributes(:status_id => 1)
    output_dir = APP_CONFIG[:data_path] + APP_CONFIG[:output_dir]
    #get the name of the plugin file
    n = self.plugin.name.match(/(.+?)Plugin/)
    script = "import os\nos.chdir('#{output_dir}')\nfrom bsPlugins import #{n[1]}\nplugin = #{n[1]}.#{self.plugin.name}()\nplugin(#{arg_line})"
    #script_name = sefl.id.to_s +'.py'
    script_name = 'script.py'
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
#   service = Service.find_by_shared_key(key) 
 end

end
