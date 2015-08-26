class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
    helper_method :admin?
   def menu 
    @h_menu = {
        :home => ['Home', root_path],
        :plugins => ['Plugins', plugins_path()]
    }

    end

protected
    def admin?
        false
    end
end
