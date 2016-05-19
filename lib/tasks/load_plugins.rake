namespace :bioscript do

  desc "Load plugins"
  task :load_plugins, [:version] do |t, args|

    ### Use rails enviroment
    require "#{Rails.root.to_s}/config/environment"

    ### Require Net::HTTP
    require 'net/http'
    require 'uri'
    require "rubygems"
    require 'csv'
    require 'json'
   
    dir_name = "/mnt/common/epfl/lib/python2.7/site-packages/bsPlugins" 
 #   dir_name = "/local/rvmuser/srv/bioscript/bsPlugins/bsPlugins"
    dir = Dir.new(dir_name)
    
    types = [] 

    h_present = {}

    # create unique key for request

   def create_key
      rnd = Array.new(6){[*'0'..'9', *'a'..'z'].sample}.join
      while(Request.find_by_key(rnd)) do
        rnd = Array.new(6){[*'0'..'9', *'a'..'z'].sample}.join
      end
      return rnd
    end
    

    #for each .py file in  a folder
 
    dir.entries.map{|f| m = f.match(/(.+?)\.py$/); (m) ? m[1] : nil}.compact.each do |filename|

      filepath = Pathname.new(dir) + "#{filename}.py"
      plugin_names = []
      File.open(filepath, 'r') do |f|
        while (l = f.gets) do
          
          #find Plugin
          if n = l.match(/class (.+?Plugin)/)
            plugin_names.push(n[1])
            h_present[n[1]]=1
          
            cmd = "python -c 'import os\nimport json\nos.chdir(\"/mnt/common/epfl/lib/python2.7/site-packages/bsPlugins\")\nimport #{filename}\nprint json.dumps(#{filename}.#{n[1]}.info)'"
            
            result =  `#{cmd}`
            
            hash = JSON.parse(result)
            path = hash["path"]
            hash["in"].each do |h|
              if !types.include?(h["type"])
                types.push(h["type"])
              end
            end
            
            query = "info ~ E'path\":\s*..#{path.join(".,\\s*.").to_s}'"
            @plugins = Plugin.where(query).all
              
            if @plugins.empty?
              puts "create! #{n[1]}"
              h = {
                :name => n[1],
                :filename => filename,
                :key => create_key,
                :info_path => path.to_json,
                :info => JSON.generate(hash)
              }
              new_plugin = Plugin.new(h)
              new_plugin.save
            else
              @plugins.each do |p|
                puts "update! " + [p.id, p.name].join(", ")
                h = {
                  :name => n[1],
                  :filename => filename,
                  :key => (p.key) ? p.key : create_key,
                  :info_path => path.to_json,
                  :info => JSON.generate(hash)
                }
                p.update_attributes(h) 
                
              end
            end
          end
        end
      end
    end
    
    ## find ones not in git and delete them without mercy
    Plugin.all.each do |p|
      if !h_present[p.name]
        puts "DESTROY! #{p.name} "
#        Result.where(:request_id => p.requests.map{|e| e.id}).destroy_all
#        p.requests.destroy_all
#        p.destroy
      end
    end
    
  end
end
