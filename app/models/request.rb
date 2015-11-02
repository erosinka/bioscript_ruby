class Request < ActiveRecord::Base
  belongs_to :plugin
  has_many :results
  def run
    #dir = APP_CONFIG[:data_path] + APP_CONFIG[:input_dir]
    link_dir = APP_CONFIG[:data_path] + APP_CONFIG[:request_input_dir]
    output_dir = APP_CONFIG[:data_path] + APP_CONFIG[:output_dir]
    #get the name of the plugin file
    n = self.plugin.name.match(/(.+?)Plugin/)

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
        if v
            line = h_in[k]
            param_type = h_param_types[line['type']]
    
            # if parameter is a multiple field, create a list of filenames and add filepath
            if v.is_a?(Array) #if h_inp[k]['multiple']
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
                arg_line = arg_line + "]"
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

    script = "import os\nos.chdir('#{output_dir}')\nfrom bsPlugins import #{n[1]}\nplugin = #{n[1]}.#{self.plugin.name}()\nplugin(#{arg_line})"

    #script_name = sefl.id.to_s +'.py'
    script_name = 'script.py'
    File.open(script_name, 'w') do |f|
        f.write(script)
    end
    output = `python #{script_name}`

    request_id = self.id
    res = output.split("\n")
    res.each do |line|
        logger.debug('SPLIT: ' + line)
        k = line.split(request_id.to_s)
        logger.debug('k: ' + k[0])
        path = k[0].split(':').map(&:strip)
        logger.debug('path: ' + path[1])
        file_name = request_id.to_s + k[1]
        logger.debug('file_name: ' + file_name)
        new_result = Result.new(:request_id => self.id, :fname => file_name, :path => path[1])
        new_result.save
    end

  end

end
