class Request < ActiveRecord::Base
  belongs_to :plugin

  def run

    arg_line = ''
    params = JSON.parse(self.parameters)#.map{|e| tmp_h[e] = params[e]}
#    params = self.parameters #.map{|e| tmp_h[e] = params[e]}
    params.each do |k, v|
        if (v)
            arg_line =  arg_line + k + "= '" + v.to_s + "', "
        end
    end
#script = "#{self.plugin.name}()(#{self.parameters})"
script = "#{self.plugin.name}()(#{arg_line})(#{params})"

#script_name = sefl.id.to_s +'.py'
script_name = 'script'
File.open(script_name, 'w') do |f|
    f.write(script)
end

#res = `python #{script_name}`

logger.debug(self.plugin.name)

  end

end
