class Job < ActiveRecord::Base
	belongs_to :task
	has_many :results
end
