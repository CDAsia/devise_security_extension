module Devise
  class AuthenticatableIp < Devise.parent_model.constantize
    self.table_name = :devise_authenticatable_ips

    belongs_to :owner, polymorphic: true, required: true
  end
end
