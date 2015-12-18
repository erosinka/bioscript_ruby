class Request < ActiveRecord::Base
  belongs_to :plugin
  has_many :results
  belongs_to :status

  before_create :validate
#  validate :validate
  def validate

    # plugin.info to define which parameters are files
    in_content = self.plugin.info_content['in']
    h_in = {}
    in_content.map{ |i| h_in[i['id']] = i}
    
    h_param_types={} #{'bam': true, 'list': false}
    ParamType.all.map{|pt| h_param_types[pt.name] = pt.is_file}
    
    params = JSON.parse(self.parameters)

    params.each do |k, v|
        logger.debug('VALIDATE:' + k.to_s + ';' + v.to_s)
        if (!v.to_s.blank?)
            line = h_in[k.split(':').last]
            param_type = h_param_types[line['type']]
            if (line['type'] == 'int')
                validate_int(k, v)
            end
            if (line['type'] == 'float')
                validate_float(k, v)
            end
         #add validate min max
        end
    end
    end

    def validate_int(p_name, val)
        test = val.is_a? Integer
        logger.debug('VALIDATE INT' + test.to_s)
        errors.add(:base, "#{p_name} is not an integer value") if (!(val.is_a? Integer))
    end

    def validate_float(p_name, val)
        logger.debug('VALIDATE FLOAT')
        errors.add(:base, "#{p_name} is not a float value") if (!(val.is_a? Float))
    end
    
    def validate_min(p_name, val, min)
      errors.add(:base, "#{p_name} is not in the authorized range") if val < min
    end 

    def validate_max(p_name, val, max)
      errors.add(:base, "#{p_name} is not in the authorized range") if val > max
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
    logger.debug('OUTPUT: ' + output)
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
    logger.debug('RES: ' + lines[0])
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
        new_result = Result.new(:request_id => self.id, :fname => file_name, :path => folder_name)
        new_result.save
    end
    logger.debug('ERROR: ' + err_msg)
    if (error)
        self.update_attributes(:error => err_msg, :status_id => 5)
    else
        self.update_attributes(:status_id => 4)
    end  
end

  def run_bp line
    # started
    self.update_attributes(:status_id => 1)
    logger.debug('RUN STARTED: ' + line)
    link_dir = APP_CONFIG[:data_path] + APP_CONFIG[:request_input_dir]
    output_dir = APP_CONFIG[:data_path] + APP_CONFIG[:output_dir]

    # plugin info to define which parameters are files
    in_content = self.plugin.info_content['in']
    h_in = {}
    in_content.map{ |i| h_in[i['id']] = i}
    # needed to add file path in case of file fields, but also is need to check if i is url
    
    h_param_types={} #{'bam': true, 'list': false}
    ParamType.all.map{|pt| h_param_types[pt.name] = pt.is_file}
    
    arg_line = ''
    params = JSON.parse(self.parameters)
    params.each do |k, v|
        # params[v].present? params[v].nil? params[v].to_s.blank?
        
        # if parameter value is not empty
        if (!k.include?('original_filename') and !v.to_s.blank?)
            line = h_in[k]
            param_type = h_param_types[line['type']]
    
            # if parameter is a multiple field, create a list of filenames and add filepath
            if (v.is_a?(Array)) #if h_inp[k]['multiple']
                arg_line = arg_line + k + " = ["
                v.each do |fname|
                    if fname.include?('http')
                        p = fname.to_s
                    else
                        p = link_dir + fname.to_s
                    end
                    arg_line = arg_line + "'" + p + "', "
                end
                #remove last comma and space
                arg_line = arg_line.chop.chop
                arg_line = arg_line + "],"
            else 
                # if parameter is a one file or url
                if param_type 
                    if v.include?('http')
                        p = v.to_s
                    else
                        p = link_dir + v.to_s
                    end
                    arg_line = arg_line + k + " = '" + p + "', "
                # if simple parameter
                else
                    arg_line =  arg_line + k + " = '" + v.to_s + "', "
                end
            end
        end
    end

    #get the name of the plugin file
    n = self.plugin.name.match(/(.+?)Plugin/)
    script = "import os\nos.chdir('#{output_dir}')\nfrom bsPlugins import #{n[1]}\nplugin = #{n[1]}.#{self.plugin.name}()\nplugin(#{arg_line})"
    #script_name = sefl.id.to_s +'.py'
    script_name = 'script.py'
    File.open(script_name, 'w') do |f|
        f.write(script)
    end
    output = `python #{script_name} 2>&1`
    logger.debug('OUTPUT: ' + output)
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
    logger.debug('RES: ' + lines[0])
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
        new_result = Result.new(:request_id => self.id, :fname => file_name, :path => folder_name)
        new_result.save
    end
    logger.debug('ERROR: ' + err_msg)
    if (error)
        self.update_attributes(:error => err_msg, :status_id => 5)
    else
        self.update_attributes(:status_id => 4)
    end  

    end
end


