class Request < ActiveRecord::Base
  belongs_to :plugin

  def run
    dir = APP_CONFIG[:data_path] + APP_CONFIG[:input_dir]
    link_dir = APP_CONFIG[:data_path] + APP_CONFIG[:request_input_dir]
    n = self.plugin.name.match(/(.+?)Plugin/)
    arg_line = ''
    params = JSON.parse(self.parameters)
    params.each do |k, v|
        if (v)
            if v.is_a?(Array)
                arg_line = arg_line + k + "= ["
                v.each do |f|
                    filepath = dir + f.to_s;
                    arg_line = arg_line + "'" + filepath + "', "
                end
                arg_line = arg_line + "]"
            else
                arg_line =  arg_line + k + "='" + v.to_s + "', "
            end
        end
    end
script = "from bsPlugins import #{n[1]}\nplugin = #{n[1]}.#{self.plugin.name}()\nplugin(#{arg_line})\nprint plugin.output_files[0][0]"

#script_name = sefl.id.to_s +'.py'
script_name = 'script.py'
File.open(script_name, 'w') do |f|
    f.write(script)
end

#res = `python #{script_name}`

logger.debug(self.plugin.name)

  end

end
