#!/usr/bin/env ruby
require json
namespace :bioscript do
dir = Dir.new("/local/rvmuser/srv/bioscript/lib/tasks")

dir.entries.select{|f| f.match(/.+\.py\z/)}.each do |e|
    puts e
    filename = e.sub(/\.py\z/, '')
    long_filename = Pathname.new(dir) + "#{e}"
    puts filename
    plugin_name = e.sub(/\.py\z/, 'Plugin') 
   
    `from e import filename`
    `json.dumps(plugin_name.info)`

    #for each <plugin_name>Plugin
    #plugin_name

end

end
