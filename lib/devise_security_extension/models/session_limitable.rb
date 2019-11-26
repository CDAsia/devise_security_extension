require 'devise_security_extension/hooks/session_limitable'
require 'devise_security_extension/session_limit'

module Devise
  module Models
    # SessionLimited ensures, that there is only one session usable per account at once.
    # If someone logs in, and some other is logging in with the same credentials,
    # the session from the first one is invalidated and not usable anymore.
    # The first one is redirected to the sign page with a message, telling that 
    # someone used his credentials to sign in.
    module SessionLimitable
      extend ActiveSupport::Concern

      included do
        has_many :session_limits, as: :session_limitable,
                 class_name: session_limitable_class, dependent: :destroy
      end

      def self.required_fields(klass)
        [:session_limitable_class, :limit_session_to, :timeout_session_in, :reject_session_on_limit]
      end

      # Create new limitable session
      #
      def log_limitable_request!
        token = generate_limitable_token
        opts = session_limitable_condition unique_session_id: token,
                                           last_accessed_at: Time.now.utc
        authenticate_limitable? && session_limitable_adapter.create!(opts) && token
      end

      # Check if +token_or_object+ is valid
      #
      def accept_limitable_token?(token_or_object)
        extract_object_from_options(token_or_object).present?
      end

      # Update the `:last_accessed_at` to current time.
      #
      def update_limitable_access_at(token_or_object)
        record = extract_object_from_options(token_or_object)
        record.last_accessed_at = Time.now.utc
        record.save(validate: false)
      end

      # Expire session matching the +token_or_object+.
      #
      def expire_session_limit(token_or_object)
        object = extract_object_from_options(token_or_object)
        object && session_limitable_adapter.destroy(object)
      end

      # Find the first instance, matching +token_or_object+, and optional +options+.
      #
      def find_limitable_by_token(token, options = {})
        token, options = nil, token if token.is_a?(Hash)

        options.merge! unique_session_id: token if token
        options = session_limitable_condition(options)

        session_limitable_adapter.find_first options
      end

      def limit_session_to
        self.class.limit_session_to
      end

      def timeout_session_in
        self.class.timeout_session_in || if respond_to?(:timeout_in)
                                                  timeout_in
                                                else
                                                  0.seconds
                                                end
      end

      def reject_session_on_limit
        record.try(:reject_session_on_limit) || self.class.reject_session_on_limit
      end

      private

      def generate_limitable_token
        loop do
          token = Devise.friendly_token
          break token unless find_limitable_by_token(token).present?
        end
      end

      def extract_object_from_options(token_or_object, opts = {})
        if token_or_object.is_a?(String)
          find_limitable_by_token token_or_object, opts
        elsif token_or_object.respond_to?(:id)
          find_limitable_by_token opts.deep_merge(id: token_or_object.id)
        end
      end

      # Check if it will allow authentication and remove session if possible.
      #
      def authenticate_limitable?
        return true if limit_session_to > session_limits.count
        opts = session_limitable_condition(order: [:last_accessed_at, :asc])
        if reject_session_on_limit
          # When +reject_session_on_limit+ is true, check for session that already timeout.
          # If exist, remove that session.
          session_limitable_adapter.find_all(opts).any? do |session|
            expire_session_limit(session) if ((Time.now.utc - timeout_session_in) <=> session.last_accessed_at) >= 0
          end
        else
          # Remove oldest session if +reject_session_on_limit+ is false.
          session = session_limitable_adapter.find_first(opts)
          expire_session_limit(session) if session
        end
      end

      def session_limitable_adapter
        self.class.session_limitable_class.constantize.to_adapter
      end

      def session_limitable_condition(options = {})
        options.deep_merge session_limitable: self
      end

      module ClassMethods
        ::Devise::Models.config self, :session_limitable_class,
                                :limit_session_to, :timeout_session_in,
                                :reject_session_on_limit
      end
    end
  end
end