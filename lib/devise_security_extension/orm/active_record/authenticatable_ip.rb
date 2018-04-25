require 'ipaddress'

module Devise
  class AuthenticatableIp < Devise.parent_model.constantize
    self.table_name = :devise_authenticatable_ips

    belongs_to :owner, polymorphic: true, required: true

    validates :ip_address, presence: true, uniqueness: { case_sensitive: false }
    validate :validate_ip_address

    def validate_ip_address
      ::IPAddress::parse(ip_address)
    rescue ArgumentError => e
      errors.add(:ip_address, :invalid, message: e.message)
    end
  end
end
