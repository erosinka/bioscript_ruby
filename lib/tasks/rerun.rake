namespace :bioscript do

  desc "Rerun plugins"
  task :rerun, [:version] do |t, args|

    ### Use rails enviroment
    require "#{Rails.root.to_s}/config/environment"

    ### Require Net::HTTP
    require 'net/http'
    require 'uri'
    require "rubygems"
    require 'csv'
    require 'json'
   
    script_dir = APP_CONFIG[:script_dir]
    
    days = 30

    requests = Request.where("status_id = 4 and not exists(select 1 from results where request_id = requests.id) and extract(epoch from current_timestamp) - extract(epoch from created_at) < #{days} *24*60*60").all
    
    puts "Restoring #{days} days requests : #{requests.size} tasks"

    requests.sort{|a,b| b.created_at <=> a.created_at}.each do |r|
      puts "Working on #{r.key}"
      
      script_name = APP_CONFIG[:data_path] + script_dir + r.key.to_s + '_script.py'    
      output = `python #{script_name} 2>&1; echo $?`
      puts "Parsing the output..."
      #logger.debug('DELAYED_JOB.RUN OUTPUT: ' + output)
      r.parse_res output
    #  exit
    end
 
  end
end
