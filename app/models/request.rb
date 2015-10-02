class Request < ActiveRecord::Base
  belongs_to :plugin
  before_save :add_parameters
  
  def add_parameters

    self.parameters = 'blabla'

  end
end
