class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
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

    
end
