class Request < ActiveRecord::Base
  belongs_to :plugin
 # before_save :add_parameters
 # attr_accessor :input_params
 
  #def add_parameters
  #  #self.parameters = self.params[:nmotifs]
  #  self.parameters = self.input_params
#
#  end
end
