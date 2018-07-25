require 'recaptcha'
require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    # Strategy for signing in a user, based on IP address in the database. It verifies user
    # request using reCAPTCHA.
    class IpAuthenticatable < ::Devise::Strategies::Authenticatable
      module FailureApp
        extend ActiveSupport::Concern

        included do
          def route(scope)
            return :"new_#{scope}_session_url" unless scope_class.devise_modules.include?(:ip_authenticatable)
            "#{scope}_ip_authentication_url"
          end
        end
      end

      include Recaptcha::Verify

      def valid?
        mapping.to.authenticatable_ip_class.constantize.to_adapter.find_first(ip_address: remote_ip) && 
          params.key?('g-recaptcha-response') &&
          super
      end

      def authenticate!
        resource = remote_ip.present? && mapping.to.find_for_ip_authentication(authentication_hash, remote_ip)
        if resource.respond_to?(:active_for_ip_authentication?) &&
           resource.active_for_ip_authentication? &&
           validate(resource)
          resource.after_ip_authentication(remote_ip)
          session['ip_authentication'] = true
          success!(resource)
        end
        raise(:not_found_in_database) unless resource
      end

      private

      # Receives a resource and check if it is valid by calling valid_for_authentication?
      # An optional block that will be triggered while validating can be optionally
      # given as parameter. Check IpAuth::Models::IpAuthenticable.valid_for_authentication?
      # for more information.
      #
      # In case the resource can't be validated, it will fail with the given
      # unauthenticated_message.
      def validate(resource)
        result = resource && (Devise.captcha_for_sign_in || verify_recaptcha)

        if result
          true
        else
          fail!(resource.ip_unauthenticated_message) if resource
          false
        end
      end

      # Extract a hash with attributes:values from the http params.
      def http_auth_hash
        keys = [http_authentication_key, :ip_address]
        Hash[*keys.zip(decode_credentials).flatten]
      end

      # Extract the appropriate subhash for authentication from params.
      def params_auth_hash
        params[scope].merge(ip_address: remote_ip)
      end

      def remote_ip
        request.remote_ip
      end

      # Provides a scoped session data for authenticated users.
      # Warden manages clearing out this data when a user logs out
      def session
        raw_session["warden.user.#{scope}.session"] ||= {}
      end
    end
  end
end

Warden::Strategies.add(:ip_authenticatable, Devise::Strategies::IpAuthenticatable)
Devise::FailureApp.send(:include, Devise::Strategies::IpAuthenticatable::FailureApp)
