class Request < ActiveRecord::Base
  belongs_to :plugin
  has_many :results
  #has :statuses
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
    out_content = self.plugin.info_content['out']
    line_start = []
    out_content.each do |out|
        # line_start[0] = 'density_fwd (track):'
        line_start.push(out['id'] + ' (' + out['type'] + '): ')
    end
    request_id = self.id
    res = output.split("\n")
    logger.debug('RES: ' + res[0])
    res.each do |line|
        includes = false;
        #check if each line of output has proper begining
        line_start.each do |ls|
            includes = line.include?(ls)
            break if (includes)
        end
        if (!includes)
            error = 'no output!'
            logger.debug(error + ' ' + line.include?(ls).to_s)
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
            # error: no path
        end
        new_result = Result.new(:request_id => self.id, :fname => file_name, :path => folder_name)
        new_result.save
    end

  end

end
