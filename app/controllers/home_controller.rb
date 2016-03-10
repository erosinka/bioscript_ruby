class HomeController < ApplicationController

def index
    stats 
end

def stats
    #@by_month = Request.all.count(:group => created_at.month)
#    @by_month = Request.select("created_at.month, sum(*)").group("created_at.month")
   # logger.debug('DATA COUNT:' + @by_month.to_s);
#    data = {}
#    @requests = Request.all
#    @requests.each do |request|
#        date = request.created_at
#        data[date.y] = data[date.y] + 1
#    end
end

end
