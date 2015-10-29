class Result < ActiveRecord::Base
	belongs_to :result_type
#	belongs_to :job
	belongs_to :request
end
