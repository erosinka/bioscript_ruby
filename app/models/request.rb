class Request < ActiveRecord::Base
  belongs_to :plugin
 # before_save :add_parameters
 # attr_accessor :input_params
 
  #def add_parameters
  #  #self.parameters = self.params[:nmotifs]
  #  self.parameters = self.input_params
#
#  end

  def run
    
script = "
#{self.plugin.name}()(#{self.parameters})
"

script_name = sefl.id.to_s +'.py'
File.open(script_name, 'w') do |f|
    f.write(script)
end

res = `python #{script_name}`

logger.debug(self.plugin.name)

  end

end
