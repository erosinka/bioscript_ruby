class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
    before_filter :order_plugins
    protect_from_forgery with: :exception
    helper_method :admin?

    Bundler.require(*Rails.groups)
    Config::Integration::Rails::Railtie.preload

    rescue_from ActiveRecord::RecordNotFound, :with => :page_not_found
  
    def menu 
        @h_menu = {
            :home => ['Home', root_path],
            :plugins => ['Plugins', plugins_path()]
        }
    end

#protected
    def admin?
        false
    end

    def page_not_found
        respond_to do |format|
            format.html {render file: "#{Rails.root}/public/404.html", layout: false, status: 404}
          #  format.html { render template: 'errors/not_found_error', layout: 'layouts/application', status: 404 }
            format.all  { render nothing: true, status: 404 }
        end
   end

    def order_plugins 
    
        @plugins = (admin?) ? Plugin.all : Plugin.where(:deprecated => false)
        plugins_ordered = {}
        plugins_ordered[:plugins] = {}
        plugins_ordered[:plugins][:key] = 'Operations'
        plugins_ordered[:plugins][:childs] = []
        path_list = {}
        @plugins.each do |p|
            h = {}
            info = JSON.parse(p.info)
            h[:key] = info['path'][1]
            h[:id] = p.key
            h[:info] = info
            operation = info['path'][0]
            path_list[operation] ||=[]
            path_list[operation].push(h)
        end
        path_list.each do |k, v|
            child2 = {}
            child2[:key] = k
            child2[:childs] = []
            v = v.sort_by {|k| k[:key]}
            v.each do |p|
                child2[:childs].push(p)
            end
            plugins_ordered[:plugins][:childs].push(child2)
        end
        
         plugins_ordered[:plugins][:childs]= plugins_ordered[:plugins][:childs].sort_by {|k| k[:key]}
         @plugins_ordered = plugins_ordered

    end

    
end
