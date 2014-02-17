class Character < ActiveRecord::Base
  def response_hash
    %w(id name radius precision cost distance).inject({}){|r, k|
      r[k] = self[k]
      r
    }
  end
end
