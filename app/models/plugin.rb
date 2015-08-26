class Plugin < ActiveRecord::Base


  def info_content
    return ActiveSupport::JSON.decode(self.info)
  end
end

