class Plugin < ActiveRecord::Base
    has_many :requests

    before_destroy :ensure_not_referenced_by_any_request

  def info_content
    return ActiveSupport::JSON.decode(self.info)
  end

  def hash_in
    in_content = self.info_content['in']
    h_in = {}
    in_content.map{ |i| h_in[i['id']] = i}
    return h_in
  end
    private

    def ensure_not_referenced_by_any_request
        if requests.empty?
            return true
        else
            errors.add(:base, 'Request is present')
        end
    end
end

