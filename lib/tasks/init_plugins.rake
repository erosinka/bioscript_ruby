namespace :bioscript do

  desc "Init plugins"
  task :init_plugins, [:version] do |t, args|

    ### Use rails enviroment
    require "#{Rails.root.to_s}/config/environment"

    ### Require Net::HTTP
    require 'net/http'
    require 'uri'
    require "rubygems"
    require 'csv'
    require 'json'
   
    
    dir_name = "/local/rvmuser/srv/bsPlugins/bsPlugins"
    dir = Dir.new(dir_name)
   
    old_plugins = OldPlugin.all.sort{|a, b| a.id <=> b.id}

    h_plugins = {}
    h_mapping = {}

    old_plugins.each do |p|
    
    info = JSON.parse(p.info)

      h_plugins[info['path']]||=[]
      h_plugins[info['path']].push(p)

    end
    
    h_plugins.each_key do |path|

      latest = h_plugins[path].last
      latest_info = JSON.parse(latest.info)

      h = {
        :info => latest.info,
        :name => latest.name
      }
      
      new_plugin = Plugin.new(h)
      new_plugin.save
      h_plugins[path].each do |old_plugin|
        h_mapping[old_plugin.id]= new_plugin.id
      end
    end		   

    h_mapping.each_key do |old_plugin_id|
    
      Request.where(:plugin_id => old_plugin_id).all.each do |r|
        r.update_attribute(:plugin_id, h_mapping[old_plugin_id])
      end

    end
   
    

 
  end
end
