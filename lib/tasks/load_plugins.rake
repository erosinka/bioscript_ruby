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
   
    
    dir_name = "/local/rvmuser/srv/bioscript/bsPlugins"
    dir = Dir.new(dir_name)
    
    types = [] 
    #for each .py file in  a folder
    #dir.entries.map{|f| m = f.match(/(Vplot)\.py$/); (m) ? m[1] : nil}.compact.each do |filename|
    dir.entries.map{|f| m = f.match(/(.+?)\.py$/); (m) ? m[1] : nil}.compact.each do |filename|
      # filename = e.sub(/\.py\z/, '')
    #    puts filename
        filepath = Pathname.new(dir) + "#{filename}.py"
        plugin_names = []
        File.open(filepath, 'r') do |f|
            while (l = f.gets) do
                #find Plugin
                if n = l.match(/class (.+?Plugin)/)
                    plugin_names.push(n[1])
                   # puts n[1]
                    cmd = "python -c 'import os\nimport json\nos.chdir(\"/srv/bsPlugins/bsPlugins\")\nimport #{filename}\nprint json.dumps(#{filename}.#{n[1]}.info)'"
                    result =  `#{cmd}`
                    
                    hash = JSON.parse(result)
                    title = hash["title"]
                    hash["in"].each do |h|
                        if !types.include?(h["type"])
                            types.push(h["type"])
                        end
                    end
                    query = '"title": ' + "\"#{title}\""
                    @plugin = Plugin.where("info LIKE :query", query: "%#{query}%")
                    if @plugin.count == 0
                        query = query = '"title":' + "\"#{title}\""
                        @plugin = Plugin.where("info LIKE :query", query: "%#{query}%")
                    end
                    #update all - deprecated and not
                    #@plugin = @plugin.where(:deprecated => false).first
                    #@plugin = Plugin.where(:id => 142)
                    @plugin.each do |p| 
                    #    p.update(:name => n[1], :info => JSON.generate(hash)) #or plugin_name?
                     #   puts "#{p.id}  #{filename}"
                    end
                end
            end
        end
    end
    puts types
  end
end
